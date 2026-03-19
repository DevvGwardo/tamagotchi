import SwiftUI

// MARK: - Particle System

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var opacity: Double
    let emoji: String
    let size: CGFloat
}

class ParticleSystem: ObservableObject {
    @Published var particles: [Particle] = []
    private var timer: Timer?
    
    func emit(type: ParticleType, at position: CGPoint, count: Int = 5) {
        for _ in 0..<count {
            let particle = Particle(
                position: position,
                velocity: type.initialVelocity(),
                opacity: 1.0,
                emoji: type.emoji,
                size: type.size
            )
            particles.append(particle)
        }
        
        if timer == nil {
            startUpdating()
        }
    }
    
    private func startUpdating() {
        timer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { [weak self] _ in
            self?.updateParticles()
        }
    }
    
    private func updateParticles() {
        for index in particles.indices.reversed() {
            particles[index].position.x += particles[index].velocity.dx
            particles[index].position.y += particles[index].velocity.dy
            particles[index].velocity.dy -= 0.1 // gravity
            particles[index].opacity -= 0.02
            
            if particles[index].opacity <= 0 {
                particles.remove(at: index)
            }
        }
        
        if particles.isEmpty {
            timer?.invalidate()
            timer = nil
        }
    }
}

enum ParticleType {
    case heart
    case zzz
    case crumb
    
    var emoji: String {
        switch self {
        case .heart: return "❤️"
        case .zzz: return "Z"
        case .crumb: return "🟤"
        }
    }
    
    var size: CGFloat {
        switch self {
        case .heart: return 12
        case .zzz: return 10
        case .crumb: return 6
        }
    }
    
    func initialVelocity() -> CGVector {
        switch self {
        case .heart:
            return CGVector(dx: Double.random(in: -0.5...0.5), dy: Double.random(in: -1.0...(-0.5)))
        case .zzz:
            return CGVector(dx: Double.random(in: 0.2...0.8), dy: Double.random(in: -0.3...(-0.1)))
        case .crumb:
            return CGVector(dx: Double.random(in: -1.0...1.0), dy: Double.random(in: 0.5...1.5))
        }
    }
}

// MARK: - Particle Overlay View

struct ParticleOverlay: View {
    @StateObject private var system = ParticleSystem()
    let trigger: ParticleTrigger?
    
    var body: some View {
        ZStack {
            ForEach(system.particles) { particle in
                Text(particle.emoji)
                    .font(.system(size: particle.size))
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onChange(of: trigger) { newTrigger in
            if let trigger = newTrigger {
                let position = CGPoint(x: 100, y: 100) // Center of watch
                switch trigger {
                case .pet:
                    system.emit(type: .heart, at: position, count: 3)
                case .sleep:
                    system.emit(type: .zzz, at: CGPoint(x: 80, y: 80), count: 2)
                case .eat:
                    system.emit(type: .crumb, at: CGPoint(x: 100, y: 120), count: 4)
                }
            }
        }
    }
}

enum ParticleTrigger: Equatable {
    case pet
    case sleep
    case eat
}
