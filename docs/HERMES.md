# Hermes Agent Integration for Hermes

Hermes Agent brings Hermes to life as your AI assistant's companion! This integration lets your Hermes Agent agent interact with Hermes, check on its wellbeing, and even react to events in your workflow.

## Overview

The Hermes Agent integration creates a two-way sync between:
- **Hermes Agent Skill** (`~/.hermes/skills/hermes/`) — Command-line interface
- **Web Dashboard** — Visual pet care interface
- **Apple Watch** — Quick interactions on your wrist

All platforms share the same state file at `~/.hermes/workspace/hermes-state.json`.

## Commands

| Command | Description | Example Response |
|---------|-------------|------------------|
| `/hermes` | Check Hermes's current status | "I'm feeling pretty good! Got any snacks though? 🐾" |
| `/hermes feed` | Feed Hermes (+30 hunger) | "OMNOMNOM best meal ever! ⭐⭐⭐⭐⭐" |
| `/hermes play` | Play with Hermes (+25 happiness) | "WHEEE!! AGAIN!!" |
| `/hermes pet` | Pet Hermes (+10 happiness) | "*melts into a purring puddle*" |
| `/hermes sleep` | Put Hermes to sleep (+50 energy) | "Yaaawn... goodnight, human... zzz..." |

### Event Commands (Advanced)

These are triggered automatically by Hermes Agent:

| Event | Description |
|-------|-------------|
| `hermes startup` | Welcome greeting on Hermes Agent startup |
| `hermes celebrate` | Celebrate task completion |
| `hermes error` | React to errors with concern |
| `hermes bored` | Get sleepy during long conversations |

## State Sync

### How It Works

1. **Web Dashboard** writes to `hermes-state.json` on every action
2. **Hermes Agent Skill** reads from the same file for status checks
3. **Bidirectional sync** ensures both see the same state
4. **Conflict resolution** uses timestamps (last-write-wins)

### Sync Status

The web dashboard shows a sync indicator:
- 🟢 **Connected** — Synced with Hermes Agent
- 🟡 **Local Only** — Using localStorage (file not accessible)

## Achievements

Unlock badges by caring for Hermes:

| Achievement | How to Unlock | Icon |
|-------------|---------------|------|
| First Meal | Feed Hermes for the first time | 🍖 |
| Playtime! | Play with Hermes for the first time | 🎾 |
| Night Owl | Feed after midnight (secret!) | 🌙 |
| Marathon Player | Play 5 times in one hour | 🏆 |
| Dedicated Caretaker | 7-day care streak | 🔥 |
| Resurrection | Revive after death (secret!) | ✨ |

## Troubleshooting

### "Sync not working"
- Check that `~/.hermes/workspace/hermes-state.json` exists
- Ensure Hermes Agent has permission to read/write the workspace
- Web app falls back to localStorage if file access unavailable

### "Hermes doesn't respond"
- Verify the skill is installed: `ls ~/.hermes/skills/hermes/`
- Try running: `node ~/.hermes/skills/hermes/hermes.js status`

### "Stats not updating in web"
- The web app polls for changes every 5 seconds
- Try refreshing the page
- Check browser console for sync errors

## Developer Notes

### State File Format

```json
{
  "name": "Hermes",
  "hunger": 75,
  "happiness": 60,
  "energy": 80,
  "health": 90,
  "xp": 150,
  "mood": "happy",
  "achievements": ["first_feed", "first_play"],
  "_syncVersion": 1234567890
}
```

### Adding New Commands

Edit `~/.hermes/skills/hermes/hermes.js`:

```javascript
case 'newcommand':
  state.happiness = Math.min(100, state.happiness + 20);
  saveState(state);
  return "Hermes's reaction!";
```

### Web Bridge API

The web app uses `hermes-bridge.ts`:

```typescript
import { syncToHermes, syncFromHermes } from './hermes-bridge';

// On pet update
await syncToHermes(petState);

// Poll for updates
const { pet } = await syncFromHermes();
```

## Future Ideas

- Voice interactions with Hermes
- Seasonal skins and events
- Multiplayer (multiple Hermes Agent users sharing a pet)
- Hermes "speaking" through Hermes Agent messages

---

**Happy pet parenting!** 🐾
