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

- [ ] **T4.1** OpenClaw skill that reads pet stats from localStorage/JSON store
- [ ] **T4.2** Agent affects pet stats (helpful convo = happy, ignored = sad)
- [ ] **T4.3** Pet reacts to OpenClaw events (startup, heartbeat, errors)
- [ ] **T4.4** Pet "speaks" to the user through OpenClaw
- [ ] **T4.5** Sync state to a shared JSON store readable by watch + web

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

## 💬 OpenClaw Integration (Pending)

Once T4.1–T4.5 are implemented, your OpenClaw agent will:
- Know Clawbert's current mood and stats
- Mention Clawbert when stats are critically low
- Celebrate when you interact with the pet
- React to OpenClaw events (startup, heartbeat, errors)
- Speak to you through Clawbert

Example:
> *"Hey, Clawbert's hunger is critically low. Quick — feed me! 🐾"*

---

## 🤝 Contributing

Open an issue, PR, or message in the OpenClaw Discord. All skill levels welcome — from pixel art to SwiftUI.

---

*OpenClaw Tamagotchi is not affiliated with Bandai or Nintendo. Tamagotchi is a trademark of Bandai.*
