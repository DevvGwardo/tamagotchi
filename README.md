# 🐾 OpenClaw Tamagotchi

> A living, breathing Tamagotchi companion for your AI assistant — on your wrist.

Your OpenClaw AI gets a little best friend. A pixel-art creature that lives on your Apple Watch and web dashboard, reacts to activity, gets hungry, sleepy, and happy — and needs you (and your AI) to take care of it.

---

## ✨ Features

### 🎮 Core Gameplay
- **5 Core Stats** — Hunger, Happiness, Energy, Health, and XP
- **Dynamic Moods** — Clawbert's mood changes based on his stats (ecstatic → happy → content → neutral → sad → miserable)
- **Stat Decay** — Stats decrease over time, requiring regular care
- **Death & Revival** — Let Clawbert's health hit zero and he'll die (but you can revive him!)

### 🏆 Achievements System
- **15 Unlockable Achievements** including:
  - First Steps (100 XP)
  - Perfect Care (all stats above 80)
  - Streak Master (7-day care streak)
  - Immortal (1 week without death)
  - And more!
- Achievement notifications when unlocked
- Progress tracking with visual progress bar

### 📊 Stats & Analytics
- **Weekly Stats Chart** — View historical trends for all stats
- **Care Streak Tracking** — Daily streak counter with flame emoji (🔥)
- **Death Counter** — Tracks how many times Clawbert has died
- **Lifetime Stats** — Total XP, best streak, and more

### 🎨 Character Customization
- **Multiple Skins** — Unlockable themes:
  - **Default** — Classic orange tabby
  - **Cyber** — Blue digital theme (unlock at 500 XP)
  - **Golden** — Gold/yellow rich theme (unlock at 1000 XP)
  - **Midnight** — Dark purple night theme (unlock at 1500 XP)
- Skin selector with preview
- XP-based unlock system

### 🔊 Sound Effects
- **8-bit Chiptune Audio** — Retro Game Boy-style sounds
- Action sounds for feed, play, pet, sleep
- Achievement unlock fanfare
- Critical warning beeps
- Mute toggle

### 💬 OpenClaw Integration
- **Chat Commands** — `/clawbert status`, `/clawbert feed`, `/clawbert play`, etc.
- **Auto-Reactions** — Clawbert greets you, checks in during heartbeats, sympathizes with errors
- **Bidirectional Sync** — All platforms share the same state

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
- [x] **T3.4** Historical stat charts (weekly overview)
- [x] **T3.5** Character customization (colors, accessories)

### 🟢 Priority 4 — OpenClaw Integration
- [x] **T4.1** ✅ OpenClaw skill reads pet stats from localStorage/JSON store
- [x] **T4.2** ✅ Agent affects pet stats — Your helpful conversations make Clawbert happy
- [x] **T4.3** ✅ Pet reacts to OpenClaw events — Clawbert greets you on startup
- [x] **T4.4** ✅ Pet "speaks" through OpenClaw — Status updates via your agent
- [x] **T4.5** ✅ Sync state to shared JSON store — All apps share Clawbert's state

### 🔵 Priority 5 — Polish & Community
- [x] **T5.1** Multiple character skins (seasonal, unlockable via XP milestones)
- [x] **T5.2** Sound effects and background music
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
│   └── src/
│       ├── components/
│       │   ├── AchievementsPanel.tsx   # Achievement system UI
│       │   └── StatsChart.tsx          # Weekly stats chart
│       ├── App.tsx
│       └── types.ts
├── openclaw-skill/                # OpenClaw skill for /clawbert command
│   ├── SKILL.md                   # Skill documentation
│   └── clawbert.ts                # Skill implementation
├── shared/
│   └── types.ts                   # Shared PetState, stats, decay schema
├── project.yml                    # XcodeGen config (both targets)
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
- **Node.js 18+** — For the web app
- **Xcode 15+** — For iOS/watchOS apps
- **XcodeGen** — For generating Xcode projects (`brew install xcodegen`)

### Quick Start

```bash
# Clone the repo
git clone https://github.com/DevvGwardo/tamagotchi
cd tamagotchi

# Install web dependencies
cd web && npm install && cd ..

# Generate Xcode project
cd ios && xcodegen generate && cd ..
```

### Running the Web App

```bash
cd web
npm run dev
# → Open http://localhost:5173 in your browser
```

The web dashboard includes:
- Full pixel-art Clawbert with animations
- All 5 stats with real-time decay
- Achievement panel (click "🏆 Achievements" button)
- Weekly stats chart (click "📊 Stats" button)
- Skin selector (click "🎨 Customize" button)
- Sound effects (toggle with 🔊/🔇 button)
- History log and death counter

### Running iOS + watchOS Apps

```bash
cd ios
open Tamagotchi.xcodeproj
```

In Xcode:
1. Select **Tamagotchi-iOS** scheme → Run on iPhone simulator
2. Select **Tamagotchi-watch** scheme → Run on Watch simulator
3. The watch app installs as a companion to the iOS app

Features on Apple Watch:
- Vertical stat bars with color coding
- Haptic feedback on interactions
- Critical warnings when stats are low
- Rename by tapping the pet name
- History log (last 3 actions)

---

## 💬 OpenClaw Integration

Your OpenClaw AI assistant can interact with Clawbert directly! This creates a two-way connection between your AI and your digital pet.

### What is OpenClaw?

[OpenClaw](https://github.com/openclaw/openclaw) is an AI assistant framework that runs locally on your machine. When integrated with Clawbert, your AI gains awareness of your pet's state and can help take care of him.

### Installation

1. **Install the skill** in your OpenClaw skills directory:

```bash
# Create the skills directory if it doesn't exist
mkdir -p ~/.openclaw/skills

# Copy the Clawbert skill
cp -r /path/to/tamagotchi/openclaw-skill ~/.openclaw/skills/clawbert

# Or symlink for development
ln -s /path/to/tamagotchi/openclaw-skill ~/.openclaw/skills/clawbert
```

2. **Restart OpenClaw** to load the skill:

```bash
openclaw gateway restart
```

3. **Verify installation**:

```bash
openclaw skills list
# Should show: clawbert
```

### Available Commands

Use the `/clawbert` command in your OpenClaw chat:

| Command | Description | Effect |
|---------|-------------|--------|
| `/clawbert status` | Check current stats and mood | — |
| `/clawbert feed` | Give Clawbert a meal | Hunger +30 |
| `/clawbert play` | Play a game together | Happiness +25, Energy −10 |
| `/clawbert pet` | Show affection | Happiness +10 |
| `/clawbert sleep` | Put Clawbert to bed | Energy +50 |
| `/clawbert achievements` | View unlocked achievements | — |
| `/clawbert help` | Show all commands | — |

**Example interactions:**

```
You: /clawbert status
OpenClaw: 😊 Clawbert is feeling happy!
          🍖 Hunger: 75/100
          😊 Happiness: 82/100
          ⚡ Energy: 60/100
          ❤️ Health: 95/100
          💡 XP: 245
          🔥 Streak: 3 days
```

### How State Sync Works

Clawbert's state is shared across all platforms:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  OpenClaw   │◄───►│  JSON Store │◄───►│   Web App   │
│  (/clawbert)│     │  (shared)   │     │  (Browser)  │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                    ┌──────┴──────┐
                    │   watchOS   │
                    │    App      │
                    └─────────────┘
```

**State file location:**
```bash
~/.openclaw/workspace/clawbert-state.json
```

**Sync features:**
- **Real-time updates** — Changes sync immediately across all platforms
- **Shared state** — Hunger, happiness, energy, health, XP, mood, achievements
- **Persistence** — Data survives app restarts
- **Conflict resolution** — Last-write-wins for concurrent updates

### Testing Sync

1. **Open the web app** at `http://localhost:5173`
2. **Note Clawbert's hunger level**
3. **In OpenClaw chat**, type: `/clawbert feed`
4. **Refresh the web app** — hunger should increase by 30
5. **Check the watch app** — stats should match

### Auto-Reactions

Clawbert automatically reacts to OpenClaw events:

- **On session start** — Greets you if it's been 8+ hours
- **During heartbeats** — Periodic check-ins (10% chance every 30 min)
- **On errors** — Offers sympathy and moral support
- **When ignored** — Gets sad and asks for attention

---

## 🏆 Achievements

Clawbert has **15 achievements** to unlock:

| Achievement | Description | How to Unlock |
|-------------|-------------|---------------|
| 🍖 First Meal | Fed Clawbert for the first time | Use `/clawbert feed` |
| 🎾 Playtime | Played with Clawbert | Use `/clawbert play` |
| 💡 First Steps | Reached 100 XP | Earn XP from care actions |
| 🌱 Growing Up | Reached 500 XP | Keep caring for Clawbert |
| ⭐ Veteran Caretaker | Reached 1,000 XP | Long-term dedication |
| ✨ Perfect Care | All stats above 80 | Maintain high stats |
| 🏥 Survivor | Recovered from critical health | Save Clawbert from low health |
| 🔥 Getting Serious | 3-day care streak | Interact daily for 3 days |
| 🔥 Streak Master | 7-day care streak | Interact daily for a week |
| 👑 Dedicated | 30-day care streak | Interact daily for a month |
| 🤚 Best Friends | Petted Clawbert 50 times | Use `/clawbert pet` often |
| 👨‍🍳 Chef | Fed Clawbert 100 times | Keep him well-fed |
| 🌙 Night Owl | Interacted after midnight | Late-night care |
| 🌅 Early Bird | Interacted before 6am | Early morning care |
| 💎 Immortal | Never let Clawbert die for a week | Perfect care for 7 days |

Achievements unlock XP rewards and are displayed in the Achievements panel.

---

## 🎨 Character Skins

Unlock new looks for Clawbert by earning XP:

| Skin | Theme | Unlock Requirement |
|------|-------|-------------------|
| Default | Classic orange tabby | Starter |
| Cyber | Blue digital/matrix | 500 XP |
| Golden | Gold/yellow luxury | 1,000 XP |
| Midnight | Dark purple night | 1,500 XP |

To change skins:
1. Open the **web app**
2. Click the **🎨 Customize** button
3. Select an unlocked skin
4. Preview and apply

---

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. **Fork the repo** on GitHub
2. **Clone your fork** locally
3. **Create a branch** for your feature
4. **Make changes** and test thoroughly
5. **Submit a pull request**

### Development Tips

- **Web app**: Uses React + Vite. Run `npm run dev` for hot reload
- **iOS/watchOS**: Uses SwiftUI. Use Xcode for debugging
- **OpenClaw skill**: TypeScript. Test with `openclaw gateway logs`

### Project Ideas

- New character skins (seasonal themes, holidays)
- Mini-games for the "Play" action
- Watch face complications
- iOS widgets
- Multiplayer (multiple pets)
- Breeding system

---

## 📝 License

MIT License — see [LICENSE](LICENSE) for details.

*OpenClaw Tamagotchi is not affiliated with Bandai or Nintendo. Tamagotchi is a trademark of Bandai.*

---

## 🙏 Credits

- Created by [DevvGwardo](https://github.com/DevvGwardo)
- Built for [OpenClaw](https://github.com/openclaw/openclaw)
- Pixel art inspired by classic 8-bit games
- Sound effects generated with Web Audio API
