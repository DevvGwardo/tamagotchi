# 🐾 Hermes Agent Tamagotchi

> A living, breathing Tamagotchi companion for your AI assistant — on your wrist.

Your Hermes Agent AI gets a little best friend. A pixel-art creature that lives on your Apple Watch and web dashboard, reacts to activity, gets hungry, sleepy, and happy — and needs you (and your AI) to take care of it.

---

## ✨ Features

### 🎮 Core Gameplay
- **5 Core Stats** — Hunger, Happiness, Energy, Health, and XP
- **Dynamic Moods** — Hermes's mood changes based on his stats (ecstatic → happy → content → neutral → sad → miserable)
- **Stat Decay** — Stats decrease over time, requiring regular care
- **Death & Revival** — Let Hermes's health hit zero and he'll die (but you can revive him!)

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
- **Death Counter** — Tracks how many times Hermes has died
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

### 💬 Hermes Agent Integration
- **Chat Commands** — `/hermes status`, `/hermes feed`, `/hermes play`, etc.
- **Auto-Reactions** — Hermes greets you, checks in during heartbeats, sympathizes with errors
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

### 🟢 Priority 4 — Hermes Agent Integration
- [x] **T4.1** ✅ Hermes Agent skill reads pet stats from localStorage/JSON store
- [x] **T4.2** ✅ Agent affects pet stats — Your helpful conversations make Hermes happy
- [x] **T4.3** ✅ Pet reacts to Hermes Agent events — Hermes greets you on startup
- [x] **T4.4** ✅ Pet "speaks" through Hermes Agent — Status updates via your agent
- [x] **T4.5** ✅ Sync state to shared JSON store — All apps share Hermes's state

### 🔵 Priority 5 — Polish & Community
- [x] **T5.1** Multiple character skins (seasonal, unlockable via XP milestones)
- [x] **T5.2** Sound effects and background music
- [ ] **T5.3** App Icon + Watch Face assets
- [ ] **T5.4** Publish to TestFlight
- [ ] **T5.5** Publish to App Store

---

## 🧬 The Character

> **Name:** Hermes
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
├── hermes-skill/                  # Hermes Agent skill for /hermes command
│   ├── SKILL.md                   # Skill documentation
│   └── hermes.ts                  # Skill implementation
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
- Full pixel-art Hermes with animations
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

## 💬 Hermes Agent Integration

Your Hermes Agent AI assistant can interact with Hermes directly! This creates a two-way connection between your AI and your digital pet.

### What is Hermes Agent?

[Hermes Agent](https://github.com/hermes/hermes) is an AI assistant framework that runs locally on your machine. When integrated with Hermes, your AI gains awareness of your pet's state and can help take care of him.

### Installation

1. **Install the skill** in your Hermes Agent skills directory:

```bash
# Create the skills directory if it doesn't exist
mkdir -p ~/.hermes/skills

# Copy the Hermes skill
cp -r /path/to/tamagotchi/hermes-skill ~/.hermes/skills/hermes

# Or symlink for development
ln -s /path/to/tamagotchi/hermes-skill ~/.hermes/skills/hermes
```

2. **Restart Hermes Agent** to load the skill:

```bash
hermes gateway restart
```

3. **Verify installation**:

```bash
hermes skills list
# Should show: hermes
```

### Available Commands

Use the `/hermes` command in your Hermes Agent chat:

| Command | Description | Effect |
|---------|-------------|--------|
| `/hermes status` | Check current stats and mood | — |
| `/hermes feed` | Give Hermes a meal | Hunger +30 |
| `/hermes play` | Play a game together | Happiness +25, Energy −10 |
| `/hermes pet` | Show affection | Happiness +10 |
| `/hermes sleep` | Put Hermes to bed | Energy +50 |
| `/hermes achievements` | View unlocked achievements | — |
| `/hermes help` | Show all commands | — |

**Example interactions:**

```
You: /hermes status
Hermes Agent: 😊 Hermes is feeling happy!
          🍖 Hunger: 75/100
          😊 Happiness: 82/100
          ⚡ Energy: 60/100
          ❤️ Health: 95/100
          💡 XP: 245
          🔥 Streak: 3 days
```

### How State Sync Works

Hermes's state is shared across all platforms:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│Hermes Agent │◄───►│  JSON Store │◄───►│   Web App   │
│  (/hermes)  │     │  (shared)   │     │  (Browser)  │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                    ┌──────┴──────┐
                    │   watchOS   │
                    │    App      │
                    └─────────────┘
```

**State file location:**
```bash
~/.hermes/workspace/hermes-state.json
```

**Sync features:**
- **Real-time updates** — Changes sync immediately across all platforms
- **Shared state** — Hunger, happiness, energy, health, XP, mood, achievements
- **Persistence** — Data survives app restarts
- **Conflict resolution** — Last-write-wins for concurrent updates

### Testing Sync

1. **Open the web app** at `http://localhost:5173`
2. **Note Hermes's hunger level**
3. **In Hermes Agent chat**, type: `/hermes feed`
4. **Refresh the web app** — hunger should increase by 30
5. **Check the watch app** — stats should match

### Auto-Reactions

Hermes automatically reacts to Hermes Agent events:

- **On session start** --- Greets you if it's been 8+ hours
- **During heartbeats** --- Periodic check-ins (10% chance every 30 min)
- **On errors** --- Offers sympathy and moral support
- **When ignored** --- Gets sad and asks for attention

---

## 🏆 Achievements

Hermes has **15 achievements** to unlock:

| Achievement | Description | How to Unlock |
|-------------|-------------|---------------|
| 🍖 First Meal | Fed Hermes for the first time | Use `/hermes feed` |
| 🎾 Playtime | Played with Hermes | Use `/hermes play` |
| 💡 First Steps | Reached 100 XP | Earn XP from care actions |
| 🌱 Growing Up | Reached 500 XP | Keep caring for Hermes |
| ⭐ Veteran Caretaker | Reached 1,000 XP | Long-term dedication |
| ✨ Perfect Care | All stats above 80 | Maintain high stats |
| 🏥 Survivor | Recovered from critical health | Save Hermes from low health |
| 🔥 Getting Serious | 3-day care streak | Interact daily for 3 days |
| 🔥 Streak Master | 7-day care streak | Interact daily for a week |
| 👑 Dedicated | 30-day care streak | Interact daily for a month |
| 🤚 Best Friends | Petted Hermes 50 times | Use `/hermes pet` often |
| 👨‍🍳 Chef | Fed Hermes 100 times | Keep him well-fed |
| 🌙 Night Owl | Interacted after midnight | Late-night care |
| 🌅 Early Bird | Interacted before 6am | Early morning care |
| 💎 Immortal | Never let Hermes die for a week | Perfect care for 7 days |

Achievements unlock XP rewards and are displayed in the Achievements panel.

---

## 🎨 Character Skins

Unlock new looks for Hermes by earning XP:

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
- **Hermes Agent skill**: TypeScript. Test with `hermes gateway logs`

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

*Hermes Agent Tamagotchi is not affiliated with Bandai or Nintendo. Tamagotchi is a trademark of Bandai.*

---

## 🙏 Credits

- Created by [DevvGwardo](https://github.com/DevvGwardo)
- Built for [Hermes Agent](https://github.com/hermes/hermes)
- Pixel art inspired by classic 8-bit games
- Sound effects generated with Web Audio API
