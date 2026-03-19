# OpenClaw Integration for Clawbert

OpenClaw brings Clawbert to life as your AI assistant's companion! This integration lets your OpenClaw agent interact with Clawbert, check on its wellbeing, and even react to events in your workflow.

## Overview

The OpenClaw integration creates a two-way sync between:
- **OpenClaw Skill** (`~/.openclaw/skills/clawbert/`) — Command-line interface
- **Web Dashboard** — Visual pet care interface
- **Apple Watch** — Quick interactions on your wrist

All platforms share the same state file at `~/.openclaw/workspace/clawbert-state.json`.

## Commands

| Command | Description | Example Response |
|---------|-------------|------------------|
| `/clawbert` | Check Clawbert's current status | "I'm feeling pretty good! Got any snacks though? 🐾" |
| `/clawbert feed` | Feed Clawbert (+30 hunger) | "OMNOMNOM best meal ever! ⭐⭐⭐⭐⭐" |
| `/clawbert play` | Play with Clawbert (+25 happiness) | "WHEEE!! AGAIN!!" |
| `/clawbert pet` | Pet Clawbert (+10 happiness) | "*melts into a purring puddle*" |
| `/clawbert sleep` | Put Clawbert to sleep (+50 energy) | "Yaaawn... goodnight, human... zzz..." |

### Event Commands (Advanced)

These are triggered automatically by OpenClaw:

| Event | Description |
|-------|-------------|
| `clawbert startup` | Welcome greeting on OpenClaw startup |
| `clawbert celebrate` | Celebrate task completion |
| `clawbert error` | React to errors with concern |
| `clawbert bored` | Get sleepy during long conversations |

## State Sync

### How It Works

1. **Web Dashboard** writes to `clawbert-state.json` on every action
2. **OpenClaw Skill** reads from the same file for status checks
3. **Bidirectional sync** ensures both see the same state
4. **Conflict resolution** uses timestamps (last-write-wins)

### Sync Status

The web dashboard shows a sync indicator:
- 🟢 **Connected** — Synced with OpenClaw
- 🟡 **Local Only** — Using localStorage (file not accessible)

## Achievements

Unlock badges by caring for Clawbert:

| Achievement | How to Unlock | Icon |
|-------------|---------------|------|
| First Meal | Feed Clawbert for the first time | 🍖 |
| Playtime! | Play with Clawbert for the first time | 🎾 |
| Night Owl | Feed after midnight (secret!) | 🌙 |
| Marathon Player | Play 5 times in one hour | 🏆 |
| Dedicated Caretaker | 7-day care streak | 🔥 |
| Resurrection | Revive after death (secret!) | ✨ |

## Troubleshooting

### "Sync not working"
- Check that `~/.openclaw/workspace/clawbert-state.json` exists
- Ensure OpenClaw has permission to read/write the workspace
- Web app falls back to localStorage if file access unavailable

### "Clawbert doesn't respond"
- Verify the skill is installed: `ls ~/.openclaw/skills/clawbert/`
- Try running: `node ~/.openclaw/skills/clawbert/clawbert.js status`

### "Stats not updating in web"
- The web app polls for changes every 5 seconds
- Try refreshing the page
- Check browser console for sync errors

## Developer Notes

### State File Format

```json
{
  "name": "Clawbert",
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

Edit `~/.openclaw/skills/clawbert/clawbert.js`:

```javascript
case 'newcommand':
  state.happiness = Math.min(100, state.happiness + 20);
  saveState(state);
  return "Clawbert's reaction!";
```

### Web Bridge API

The web app uses `openclaw-bridge.ts`:

```typescript
import { syncToOpenClaw, syncFromOpenClaw } from './openclaw-bridge';

// On pet update
await syncToOpenClaw(petState);

// Poll for updates
const { pet } = await syncFromOpenClaw();
```

## Future Ideas

- Voice interactions with Clawbert
- Seasonal skins and events
- Multiplayer (multiple OpenClaw users sharing a pet)
- Clawbert "speaking" through OpenClaw messages

---

**Happy pet parenting!** 🐾
