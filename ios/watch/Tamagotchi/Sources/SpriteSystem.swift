import SwiftUI
import WatchKit

// MARK: - Sprite Animation System

/// Defines a sprite animation sequence
struct SpriteAnimation {
    let name: String
    let frames: [String]  // Asset names
    let frameDuration: TimeInterval
    let loops: Bool
    
    static let idle = SpriteAnimation(
        name: "idle",
        frames: ["cat_idle_1", "cat_idle_2", "cat_idle_3", "cat_idle_4", "cat_idle_5", "cat_idle_6", 
                 "cat_idle_7", "cat_idle_8", "cat_idle_9", "cat_idle_10", "cat_idle_11", "cat_idle_12"],
        frameDuration: 0.15,
        loops: true
    )
    
    static let happy = SpriteAnimation(
        name: "happy",
        frames: ["cat_happy_1", "cat_happy_2", "cat_happy_3", "cat_happy_4", "cat_happy_5", "cat_happy_6"],
        frameDuration: 0.12,
        loops: true
    )
    
    static let eating = SpriteAnimation(
        name: "eating",
        frames: ["cat_eating_1", "cat_eating_2", "cat_eating_3", "cat_eating_4", "cat_eating_5"],
        frameDuration: 0.15,
        loops: false
    )
    
    static let sleeping = SpriteAnimation(
        name: "sleeping",
        frames: ["cat_sleeping_1", "cat_sleeping_2"],
        frameDuration: 0.8,
        loops: true
    )
    
    static let sad = SpriteAnimation(
        name: "sad",
        frames: ["cat_sad_1", "cat_sad_2", "cat_sad_3"],
        frameDuration: 0.5,
        loops: true
    )
    
    static let dead = SpriteAnimation(
        name: "dead",
        frames: ["cat_dead_1"],
        frameDuration: 1.0,
        loops: false
    )
    
    static let bounce = SpriteAnimation(
        name: "bounce",
        frames: ["cat_bounce_1", "cat_bounce_2", "cat_bounce_3", "cat_bounce_4", "cat_bounce_5"],
        frameDuration: 0.08,
        loops: false
    )

    static let thinking = SpriteAnimation(
        name: "thinking",
        frames: ["cat_eating_1", "cat_eating_2", "cat_eating_3", "cat_eating_4", "cat_eating_5"],
        frameDuration: 0.2,
        loops: true
    )
}

// MARK: - Sprite Animator

/// Manages sprite animation state and timing
class SpriteAnimator: ObservableObject {
    @Published private(set) var currentFrame: String = ""
    @Published private(set) var isAnimating = false
    
    private var currentAnimation: SpriteAnimation?
    private var frameIndex = 0
    private var timer: Timer?
    private var completion: (() -> Void)?
    private let soundManager = SoundManager.shared
    
    func play(_ animation: SpriteAnimation, completion: (() -> Void)? = nil) {
        // Don't restart if already playing same animation
        if currentAnimation?.name == animation.name && isAnimating { return }
        
        stop()
        currentAnimation = animation
        self.completion = completion
        frameIndex = 0
        isAnimating = true
        
        // Set initial frame immediately
        updateFrame()
        
        // Start timer if more than one frame
        if animation.frames.count > 1 {
            timer = Timer.scheduledTimer(
                withTimeInterval: animation.frameDuration,
                repeats: true
            ) { [weak self] _ in
                self?.advanceFrame()
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isAnimating = false
    }
    
    private func advanceFrame() {
        guard let animation = currentAnimation else { return }
        
        frameIndex += 1
        
        if frameIndex >= animation.frames.count {
            if animation.loops {
                frameIndex = 0
            } else {
                // Animation complete
                frameIndex = animation.frames.count - 1
                stop()
                completion?()
                return
            }
        }
        
        updateFrame()
    }
    
    private func updateFrame() {
        guard let animation = currentAnimation,
              frameIndex < animation.frames.count else { return }
        currentFrame = animation.frames[frameIndex]
        
        // Play synced sound/haptic
        soundManager.play(for: animation.name, frame: frameIndex)
    }
}

// MARK: - Animated Sprite View

struct AnimatedSpriteView: View {
    @StateObject private var animator = SpriteAnimator()
    let mood: String
    let triggerBounce: Bool
    let size: CGFloat
    
    var body: some View {
        Image(animator.currentFrame)
            .resizable()
            .interpolation(.none)  // Keep pixel art crisp
            .antialiased(false)
            .frame(width: size, height: size)
            .opacity(animator.currentFrame.isEmpty ? 0 : 1)
            .onAppear {
                startAnimationForMood()
            }
            .onChange(of: mood) { _ in
                startAnimationForMood()
            }
            .onChange(of: triggerBounce) { _ in
                if triggerBounce {
                    animator.play(.bounce) { [self] in
                        startAnimationForMood()
                    }
                }
            }
    }
    
    private func startAnimationForMood() {
        let animation: SpriteAnimation
        switch mood {
        case "dead":      animation = .dead
        case "sleeping":  animation = .sleeping
        case "eating":    animation = .eating
        case "thinking":  animation = .thinking
        case "sad", "miserable": animation = .sad
        case "happy", "ecstatic": animation = .happy
        default:          animation = .idle
        }
        animator.play(animation)
    }
}

// MARK: - Fallback Canvas Sprite (when assets missing)

/// Programmatic fallback if sprite assets aren't loaded yet
struct CanvasSpriteView: View {
    let mood: String
    let size: CGFloat
    
    var body: some View {
        Canvas { context, canvasSize in
            let pixelSize = canvasSize.width / 12
            let pixels = getPixelData()
            
            // Apply filters based on mood
            if mood == "dead" {
                context.addFilter(.colorMultiply(Color.gray.opacity(0.5)))
            } else if mood == "sad" || mood == "miserable" {
                context.addFilter(.saturation(0.6))
            }
            
            // Draw pixels
            for (col, row, color) in pixels {
                let rect = CGRect(
                    x: CGFloat(col) * pixelSize,
                    y: CGFloat(row) * pixelSize,
                    width: pixelSize * 0.95,
                    height: pixelSize * 0.95
                )
                context.fill(Path(rect), with: .color(color))
            }
            
            // Add sleep Z
            if mood == "sleeping" {
                context.draw(
                    Text("Z").font(.system(size: pixelSize, weight: .bold)),
                    at: CGPoint(x: 9 * pixelSize, y: 2 * pixelSize)
                )
            }
        }
        .frame(width: size, height: size)
    }
    
    private func getPixelData() -> [(Int, Int, Color)] {
        // Golden pixel cat with more detail
        var pixels: [(Int, Int, Color)] = []
        
        let furMain = Color(red: 0.85, green: 0.70, blue: 0.12)
        let furDark = Color(red: 0.70, green: 0.55, blue: 0.08)
        let furLight = Color(red: 0.95, green: 0.82, blue: 0.25)
        let eye = Color.black
        
        // Body (rows 6-10)
        for row in 6...10 {
            for col in 3...8 {
                pixels.append((col, row, (row + col) % 2 == 0 ? furMain : furDark))
            }
        }
        
        // Ears (rows 2-5)
        for r in 0...2 {
            pixels.append((2, 5-r, r == 2 ? furLight : furMain))
            pixels.append((3, 5-r, furMain))
            pixels.append((8, 5-r, r == 2 ? furLight : furMain))
            pixels.append((9, 5-r, furMain))
        }
        
        // Head (rows 4-7)
        for row in 4...7 {
            for col in 2...9 {
                let isEdge = col == 2 || col == 9 || row == 4
                pixels.append((col, row, isEdge ? furDark : furMain))
            }
        }
        
        // Eyes based on mood
        let eyeY = mood == "sleeping" ? 6 : 5
        pixels.append((4, eyeY, eye))
        pixels.append((5, eyeY, eye))
        pixels.append((6, eyeY, eye))
        pixels.append((7, eyeY, eye))
        
        // Eye shine
        if mood != "sleeping" && mood != "dead" {
            pixels.append((5, 4, Color.white.opacity(0.8)))
            pixels.append((7, 4, Color.white.opacity(0.8)))
        }
        
        // Nose/Mouth
        pixels.append((5, 7, Color(red: 0.55, green: 0.27, blue: 0.07)))
        pixels.append((6, 7, Color(red: 0.55, green: 0.27, blue: 0.07)))
        
        return pixels
    }
}

// MARK: - Smart Sprite View (tries assets, falls back to canvas)

struct SmartSpriteView: View {
    let mood: String
    let triggerBounce: Bool
    let size: CGFloat
    
    @State private var useCanvasFallback = false
    
    var body: some View {
        Group {
            if useCanvasFallback {
                CanvasSpriteView(mood: mood, size: size)
            } else {
                AnimatedSpriteView(
                    mood: mood,
                    triggerBounce: triggerBounce,
                    size: size
                )
                .onAppear {
                    // Check if first frame exists, fallback if not
                    checkAssetAvailability()
                }
            }
        }
    }
    
    private func checkAssetAvailability() {
        // Try to load first frame to check if assets exist
        let testImage = UIImage(named: "cat_idle_1")
        useCanvasFallback = (testImage == nil)
    }
}

// MARK: - Direct Sprite View (load from bundle path)

struct DirectSpriteView: View {
    let mood: String
    let size: CGFloat
    
    private var frameName: String {
        switch mood {
        case "dead": return "cat_dead_1"
        case "sleeping": return "cat_sleeping_1"
        case "eating": return "cat_eating_1"
        case "sad": return "cat_sad_1"
        case "happy": return "cat_happy_1"
        default: return "cat_idle_1"
        }
    }
    
    var body: some View {
        // Try to load from bundle path directly
        if let uiImage = loadImageFromBundle() {
            Image(uiImage: uiImage)
                .resizable()
                .interpolation(.none)
                .frame(width: size, height: size)
        } else {
            // Fallback to canvas if image not found
            CanvasSpriteView(mood: mood, size: size)
        }
    }
    
    private func loadImageFromBundle() -> UIImage? {
        // Try to load from asset catalog
        return UIImage(named: frameName)
    }
}
