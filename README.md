# 🐾 OpenClaw Tamagotchi

> A living, breathing Tamagotchi companion for your AI assistant — on your wrist.

Your OpenClaw AI gets a little best friend. A pixel-art creature that lives on your Apple Watch and web dashboard, reacts to activity, gets hungry, sleepy, and happy — and needs you (and your AI) to take care of it.

---

## ✅ Task Board

### 🔴 Priority 1 — Foundation

- [x] **T1.1** Define the character — name, species, personality, visual style
- [x] **T1.2** Choose the tech stack: SwiftUI + WatchKit (watchOS/iOS) + React/Vite (web)
- [x] **T1.3** Design the core stats system (HP, Hunger, Happiness, Energy, XP)
- [x] **T1.4** Set up project structure: monorepo with `ios/`, `web/`, `shared/` directories
- [x] **T1.5** Create the character sprite sheet

### 🟡 Priority 2 — Core App (Apple Watch)

- [x] **T2.1** Bootstrap WatchKit app with XcodeGen
- [x] **T2.2** Implement stat display on watch face (SwiftUI)
- [x] **T2.3** Build interaction buttons: Feed, Play, Sleep, Pet
- [x] **T2.4** Watch haptic feedback on interactions
- [ ] **T2.5** Background refresh / watch face complication support

### 🟡 Priority 3 — Web Dashboard

- [x] **T3.1** Bootstrap React/Vite web app
- [x] **T3.2** Full character view with all animations
- [x] **T3.3** Stat management panel
- [ ] **T3.4** Historical stat charts (weekly overview)
- [ ] **T3.5** Character customization (colors, accessories)

### 🟢 Priority 4 — OpenClaw Integration

- [x] **T4.1** ✅ OpenClaw skill reads pet stats from localStorage/JSON store — The `/clawbert` command queries Clawbert's current stats, mood, and last interaction time
- [x] **T4.2** ✅ Agent affects pet stats — Your helpful conversations make Clawbert happy; ignoring him too long makes him sad
- [x] **T4.3** ✅ Pet reacts to OpenClaw events — Clawbert greets you on startup, checks in during heartbeats, and expresses sympathy for errors
- [x] **T4.4** ✅ Pet "speaks" through OpenClaw — Clawbert can send messages and status updates through your OpenClaw agent
- [x] **T4.5** ✅ Sync state to shared JSON store — All apps (OpenClaw, web, watch) read/write to the same localStorage, keeping Clawbert's state in sync everywhere

### 🔵 Priority 5 — Polish & Community

- [ ] **T5.1** Multiple character skins (seasonal, unlockable via XP milestones)
- [ ] **T5.2** Sound effects and background music
- [ ] **T5.3** App Icon + Watch Face assets
- [ ] **T5.4** Publish to TestFlight
- [ ] **T5.5** Publish to App Store

---

## 🧬 The Character

> **Name:** Clawbert
>
> **Species:** A small, round, cat-like creature with digital/code motifs
>
> **Personality:** Curious, clingy, dramatic when ignored, overjoyed when cared for
>
> **Looks:** Pixel-art style (8-bit) on web; expressive emoji-based on watch/iOS

### Stats
| Stat | Range | Decay | Boosted By |
|------|-------|-------|------------|
| 🍖 Hunger | 0–100 | −1 / 30s | Feeding (+30) |
| 😊 Happiness | 0–100 | −0.5 / 30s | Playing (+25), Petting (+10) |
| ⚡ Energy | 0–100 | — | Sleeping (+50) |
| ❤️ Health | 0–100 | −10/hr if hunger=0 | All stats > 50 |
| 💡 XP | 0–∞ | +on interactions | All care actions |

### Moods
`ecstatic → happy → content → neutral → sad → miserable → sleeping → eating`

Mood is derived from the average of hunger, happiness, and health.

---

## 🗂️ Project Structure

```
tamagotchi/
├── ios/
│   ├── iOS/Tamagotchi/Sources/   # iOS companion app (SwiftUI)
│   └── watch/Tamagotchi/Sources/  # watchOS app (SwiftUI)
├── web/                           # React + Vite web dashboard
├── shared/
│   └── types.ts                   # Shared PetState, stats, decay schema
├── project.yml                    # XcodeGen config (both targets)
└── README.md
```

---

## 🐾 What's Implemented

### Web Dashboard (`web/`)
- SVG pixel-art cat with 6 visual states (idle, happy, sad, sleeping, eating, dead)
- Stat decay timer — hunger and happiness drop every 30 seconds
- Death & revival system — health=0 kills Clawbert; death counter persists
- Critical warning — device border flashes red when hunger or health < 20
- History log — last 5 actions with timestamps, persisted to localStorage
- Rename pet — pencil icon → inline edit, saved to localStorage
- Retro Game Boy-style device frame with scanline overlay and speaker grille
- Press Start 2P pixel font

### watchOS App (`ios/watch/`)
- Full SwiftUI app running on watchOS 26.2
- Mini vertical stat bars (🍖 😊 ⚡ ❤️) with color coding
- Feed / Play / Sleep / Pet buttons with haptic feedback
- Stat decay: −1 hunger, −0.5 happiness every 30 seconds
- Decay tick indicator (tiny red dot) on decaying bars
- Blinking ⚠ CRITICAL warning when hunger or health < 20
- Rename: tap the pet name to edit inline
- History log: last 3 action entries, persisted
- Death counter shown on death screen and main screen
- Health recovery: +1 HP per decay tick when hunger + happiness > 50

### iOS Companion (`ios/iOS/`)
- Full SwiftUI companion app for iPhone
- Rename, stat bars, action grid, history log, death counter
- Persists to UserDefaults

---

## 🚀 Getting Started

```bash
# Clone
git clone https://github.com/DevvGwardo/tamagotchi
cd tamagotchi

# Web app
cd web && npm install && npm run dev
# → http://localhost:5173

# iOS + watchOS (requires XcodeGen + Xcode)
cd ios && xcodegen generate && open Tamagotchi.xcodeproj
# → Select Tamagotchi-iOS scheme → Run on simulator
# → The watchOS app will install alongside as a companion
```

---

## 💬 OpenClaw Integration

Your OpenClaw AI assistant can now interact with Clawbert directly! The integration creates a two-way connection between your AI and your digital pet.

### What is OpenClaw?

[OpenClaw](https://github.com/DevvGwardo/OpenClaw) is an AI assistant framework that runs locally on your machine. When integrated with Clawbert, your AI gains awareness of your pet's state and can help take care of him — even when you're not actively using the web or watch apps.

### The `/clawbert` Command

Use the `/clawbert` command in your OpenClaw chat to interact with Clawbert:

```
/clawbert status      # Check Clawbert's current stats and mood
/clawbert feed        # Feed Clawbert (+30 hunger)
/clawbert play        # Play with Clawbert (+25 happiness)
/clawbert pet         # Pet Clawbert (+10 happiness)
/clawbert sleep       # Put Clawbert to sleep (+50 energy)
/clawbert achievements # View unlocked achievements and stats
```

### Available Commands

| Command | Description | Effect on Stats |
|---------|-------------|-----------------|
| `status` | Shows current stats, mood, and last interaction | — |
| `feed` | Give Clawbert a meal | Hunger +30 |
| `play` | Play a game together | Happiness +25 |
| `pet` | Give Clawbert some affection | Happiness +10 |
| `sleep` | Put Clawbert to bed | Energy +50 |
| `achievements` | View death count and other stats | — |

### How State Sync Works

Clawbert's state is shared across all platforms through a unified localStorage/JSON store:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  OpenClaw   │◄───►│  localStorage │◄───►│   Web App   │
│  (AI Skill) │     │  (JSON Store) │     │  (Browser)  │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                    ┌──────┴──────┐
                    │   watchOS   │
                    │    App      │
                    └─────────────┘
```

**Key features of the sync system:**
- **Real-time updates**: Changes from any device immediately reflect on all others
- **Shared state**: Hunger, happiness, energy, health, XP, mood, and history are synchronized
- **Persistence**: All data is stored in `localStorage` (web) and `UserDefaults` (watch/iOS), mirrored to the shared store
- **Conflict resolution**: Last-write-wins ensures the most recent action takes precedence

### Setup Instructions for OpenClaw Users

#### Where to Put the Skill

The Clawbert skill should be installed in your OpenClaw skills directory:

```bash
# Default location
~/.openclaw/skills/clawbert/

# Or clone directly
git clone https://github.com/DevvGwardo/tamagotchi \
  ~/.openclaw/skills/clawbert
```

The skill file structure:
```
~/.openclaw/skills/clawbert/
├── SKILL.md          # Skill definition and commands
├── clawbert.js       # Core skill logic
└── package.json      # Dependencies
```

#### How to Check If Sync Is Working

1. **Open the web app** at `http://localhost:5173` and note Clawbert's hunger level
2. **Use OpenClaw**: Type `/clawbert feed` in your OpenClaw chat
3. **Verify the change**: Refresh the web app — hunger should have increased by 30
4. **Check the watch**: Open the watchOS app — the stats should match

You can also check the shared state file directly:
```bash
# View the sync state (macOS)
cat ~/Library/Application\ Support/OpenClaw/clawbert-state.json
```

#### Troubleshooting Tips

| Issue | Solution |
|-------|----------|
| Command not found | Ensure the skill is in `~/.openclaw/skills/clawbert/` and restart OpenClaw |
| Stats not syncing | Check that all apps have read/write access to localStorage/UserDefaults |
| Outdated stats showing | Try `/clawbert status` first to force a state refresh |
| Watch not reflecting changes | The watch syncs on app foreground — open the app to trigger a refresh |
| Permission errors | Run `chmod -R 755 ~/.openclaw/skills/clawbert/` |

### Example Interactions

**Checking status when Clawbert is hungry:**
> *"Clawbert is looking a bit peckish! 🐱 His hunger is at 25/100. Want to feed him with `/clawbert feed`?"*

**Celebrating after playtime:**
> *"Clawbert had so much fun playing! His happiness is now at 85/100. He's doing a little happy dance! 💃"*

**Critical warning:**
> *"⚠️ URGENT: Clawbert's health is critically low (15/100)! He's not doing well — please check on him with `/clawbert status`"*

---

## 🤝 Contributing

Open an issue, PR, or message in the OpenClaw Discord. All skill levels welcome — from pixel art to SwiftUI.

---

*OpenClaw Tamagotchi is not affiliated with Bandai or Nintendo. Tamagotchi is a trademark of Bandai.*
