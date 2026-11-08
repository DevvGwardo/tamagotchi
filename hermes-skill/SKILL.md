# Hermes Skill — Hermes Agent Tamagotchi

> Your AI assistant gets a virtual pet companion

Interact with Hermes, your digital Tamagotchi, directly through Hermes Agent. Feed him, play with him, and keep him happy — all from your chat interface.

## Commands

### `/hermes status`
Check Hermes's current stats, mood, and last interaction time.

**Example:**
```
/hermes status
```

**Output:**
> 🐾 **Hermes** is feeling *happy*!
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

### `/hermes feed`
Give Hermes a meal. Increases hunger by 30, happiness by 5.

**Example:**
```
/hermes feed
```

---

### `/hermes play`
Play a game with Hermes. Increases happiness by 25, decreases energy by 10.

**Example:**
```
/hermes play
```

---

### `/hermes pet`
Pet Hermes to show affection. Increases happiness by 10.

**Example:**
```
/hermes pet
```

---

### `/hermes sleep`
Put Hermes to sleep to recover energy. Increases energy by 50, decreases hunger by 5.

**Example:**
```
/hermes sleep
```

---

### `/hermes achievements`
View unlocked achievements and lifetime stats.

**Example:**
```
/hermes achievements
```

**Output:**
> 🏆 **Achievements Unlocked: 5/15**
>
> ✓ First Steps — Reached 100 XP
> ✓ Perfect Care — All stats above 80 for 24 hours
> ✓ Survivor — Recovered from critical health
> ✓ Streak Master — 7-day care streak
> ✓ Best Friends — Petted Hermes 50 times
>
> ☠️ Deaths: 2
> ⏱️ Total Time Together: 12.5 hours

---

## How It Works

Hermes's state is synchronized between all your devices through a shared JSON store:

- **Web Dashboard** — Full visual interface at `http://localhost:5173`
- **Apple Watch** — Quick interactions on your wrist
- **Hermes Agent Chat** — The `/hermes` commands in this skill

All platforms read from and write to the same state file, so Hermes is always up-to-date no matter how you interact with him.

## Auto-Reactions

Hermes also reacts automatically to your Hermes Agent activity:

- **On startup** — Hermes greets you if it's been a while
- **During heartbeats** — Periodic check-ins when you're busy
- **On errors** — Hermes expresses sympathy when things go wrong
- **After long sessions** — Hermes gets lonely if ignored too long

## File Locations

- **State file:** `~/.hermes/workspace/hermes-state.json`
- **Web app:** `~/tamagotchi/web/` (run `npm run dev`)
- **iOS/Watch app:** `~/tamagotchi/ios/` (open in Xcode)

## Tips

- Stats decay every 30 seconds — hunger and happiness drop gradually
- Keep all stats above 50 to maintain health
- Critical warnings appear when hunger or health drops below 20
- Death is permanent... until you revive Hermes with a new body
- Daily care streaks earn bonus XP

## Credits

Part of the [Hermes Agent Tamagotchi](https://github.com/DevvGwardo/tamagotchi) project.
