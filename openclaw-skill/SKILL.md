# Clawbert Skill — OpenClaw Tamagotchi

> Your AI assistant gets a virtual pet companion

Interact with Clawbert, your digital Tamagotchi, directly through OpenClaw. Feed him, play with him, and keep him happy — all from your chat interface.

## Commands

### `/clawbert status`
Check Clawbert's current stats, mood, and last interaction time.

**Example:**
```
/clawbert status
```

**Output:**
> 🐾 **Clawbert** is feeling *happy*!
> 
> 🍖 Hunger: 75/100  
> 😊 Happiness: 82/100  
> ⚡ Energy: 60/100  
> ❤️ Health: 95/100  
> 💡 XP: 245  
> 🔥 Streak: 3 days
> 
> *Last fed: 2 hours ago*

---

### `/clawbert feed`
Give Clawbert a meal. Increases hunger by 30, happiness by 5.

**Example:**
```
/clawbert feed
```

---

### `/clawbert play`
Play a game with Clawbert. Increases happiness by 25, decreases energy by 10.

**Example:**
```
/clawbert play
```

---

### `/clawbert pet`
Pet Clawbert to show affection. Increases happiness by 10.

**Example:**
```
/clawbert pet
```

---

### `/clawbert sleep`
Put Clawbert to sleep to recover energy. Increases energy by 50, decreases hunger by 5.

**Example:**
```
/clawbert sleep
```

---

### `/clawbert achievements`
View unlocked achievements and lifetime stats.

**Example:**
```
/clawbert achievements
```

**Output:**
> 🏆 **Achievements Unlocked: 5/15**
> 
> ✓ First Steps — Reached 100 XP  
> ✓ Perfect Care — All stats above 80 for 24 hours  
> ✓ Survivor — Recovered from critical health  
> ✓ Streak Master — 7-day care streak  
> ✓ Best Friends — Petted Clawbert 50 times
> 
> ☠️ Deaths: 2  
> ⏱️ Total Time Together: 12.5 hours

---

## How It Works

Clawbert's state is synchronized between all your devices through a shared JSON store:

- **Web Dashboard** — Full visual interface at `http://localhost:5173`
- **Apple Watch** — Quick interactions on your wrist
- **OpenClaw Chat** — The `/clawbert` commands in this skill

All platforms read from and write to the same state file, so Clawbert is always up-to-date no matter how you interact with him.

## Auto-Reactions

Clawbert also reacts automatically to your OpenClaw activity:

- **On startup** — Clawbert greets you if it's been a while
- **During heartbeats** — Periodic check-ins when you're busy
- **On errors** — Clawbert expresses sympathy when things go wrong
- **After long sessions** — Clawbert gets lonely if ignored too long

## File Locations

- **State file:** `~/.openclaw/workspace/clawbert-state.json`
- **Web app:** `~/tamagotchi/web/` (run `npm run dev`)
- **iOS/Watch app:** `~/tamagotchi/ios/` (open in Xcode)

## Tips

- Stats decay every 30 seconds — hunger and happiness drop gradually
- Keep all stats above 50 to maintain health
- Critical warnings appear when hunger or health drops below 20
- Death is permanent... until you revive Clawbert with a new body
- Daily care streaks earn bonus XP

## Credits

Part of the [OpenClaw Tamagotchi](https://github.com/DevvGwardo/tamagotchi) project.
