# 🐾 OpenClaw Tamagotchi — Apple Watch Virtual Companion

> A living, breathing Tamagotchi companion for your AI assistant — on your wrist.

Your OpenClaw AI gets a little best friend. A pixel-art creature that lives on your Apple Watch, reacts to your OpenClaw activity, gets hungry, sleepy, and happy — and needs you (and your AI) to take care of it.

---

## 📋 Task Board

### 🔴 Priority 1 — Foundation
- [ ] **T1.1** Define the character — name, species, personality, visual style (pixel art? flat? animated?)
- [ ] **T1.2** Choose the tech stack: SwiftUI + WatchKit for the watch app + React web dashboard
- [ ] **T1.3** Design the core stats system (HP, Hunger, Happiness, Energy, XP)
- [ ] **T1.4** Set up project structure: monorepo with `ios/`, `web/`, `shared/` directories
- [ ] **T1.5** Create the character sprite sheet (idle, happy, sad, hungry, sleeping, eating)

### 🟡 Priority 2 — Core App (Apple Watch)
- [ ] **T2.1** Bootstrap WatchKit app with XcodeGen
- [ ] **T2.2** Implement stat display on watch face (SwiftUI)
- [ ] **T2.3** Build interaction buttons: Feed, Play, Sleep, Pet
- [ ] **T2.4** Watch haptic feedback on interactions
- [ ] **T2.5** Background refresh / complication support

### 🟡 Priority 3 — Web Dashboard
- [ ] **T3.1** Bootstrap React/Vite web app
- [ ] **T3.2** Full character view with all animations
- [ ] **T3.3** Stat management panel
- [ ] **T3.4** Historical stat charts (how's Clawbert doing this week?)
- [ ] **T3.5** Character customization (colors, accessories)

### 🟢 Priority 4 — OpenClaw Integration
- [ ] **T4.1** OpenClaw plugin/skill that reads pet stats
- [ ] **T4.2** Agent can affect pet stats (positive: helpful convo = happy, negative: ignored = sad)
- [ ] **T4.3** Pet reacts to OpenClaw events (startup, heartbeat, errors)
- [ ] **T4.4** Optional: Pet "speaks" to the user through OpenClaw
- [ ] **T4.5** Sync state to a shared JSON store both the watch app and web dashboard can read

### 🔵 Priority 5 — polish & community
- [ ] **T5.1** Multiple character skins (seasonal, unlockable)
- [ ] **T5.2** Sound effects and bg music
- [ ] **T5.3** App Icon + Watch Face assets
- [ ] **T5.4** Publish to TestFlight
- [ ] **T5.5** Publish to App Store

---

## 🧬 The Character (Draft)

> **Name:** Clawbert (or help us pick!)
> 
> **Species:** OpenClaw's mascot — a small, round, cat-like creature with digital/code motifs
> 
> **Personality:** Curious, clingy, dramatic when ignored, overjoyed when cared for
> 
> **Looks:** Pixel-art style (8-bit nostalgia), big expressive eyes, tiny paws, a small light on its head that blinks

### Stats
| Stat | Range | Decay | Boosted By |
|------|-------|-------|------------|
| 🍖 Hunger | 0–100 | -2/hr | Feeding |
| 😊 Happiness | 0–100 | -1/hr | Playing, Petting |
| ⚡ Energy | 0–100 | Sleep recharge | Sleeping |
| 💡 XP | 0–∞ | +on interactions | All care actions |
| ❤️ Health | 0–100 | -10 if Hunger=0 | Full stats |

---

## 🗂️ Project Structure

```
tamagotchi/
├── ios/                 # WatchKit + iOS companion app (SwiftUI)
├── web/                 # React web dashboard (Vite + TypeScript)
├── shared/              # Shared types, stat schema, sprite data (TypeScript)
├── docs/                # Design docs, sprite specs, API contracts
└── README.md
```

---

## 🚀 Getting Started

```bash
# Clone the repo
git clone https://github.com/DevvGwardo/tamagotchi
cd tamagotchi

# Web app
cd web && npm install && npm run dev

# iOS (requires XcodeGen)
cd ios && xcodegen generate && open Tamagotchi.xcodeproj
```

---

## 💬 OpenClaw Integration

When the OpenClaw skill is installed, your agent will:
- Know Clawbert's current mood
- Mention Clawbert when stats are low
- Celebrate when you interact with the pet
- Warn you when Clawbert needs attention

Example:
> *"Hey, Clawbert's hunger is critically low. Quick — feed me! 🐾"*

---

## 🤝 Contributing

Open an issue, PR, or message in the OpenClaw Discord. All skill levels welcome — from pixel art to SwiftUI.

---

*OpenClaw Tamagotchi is not affiliated with Bandai or Nintendo. Tamagotchi is a trademark of Bandai.*
