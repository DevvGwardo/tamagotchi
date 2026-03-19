/**
 * Clawbert OpenClaw Skill
 * 
 * Provides the /clawbert command for interacting with your Tamagotchi pet.
 * Syncs state with the shared JSON store at ~/.openclaw/workspace/clawbert-state.json
 */

import * as fs from 'fs';
import * as path from 'path';
import { homedir } from 'os';

// ── Types ────────────────────────────────────────────────────────────────────

interface PetState {
  name: string;
  hunger: number;
  happiness: number;
  energy: number;
  health: number;
  xp: number;
  mood: string;
  lastFed: string;
  lastPlayed: string;
  lastPet: string;
  isSleeping: boolean;
  createdAt: string;
  achievements: string[];
  celebratedMilestones: number[];
  neglectStreak: number;
  lastCheckTime: string;
  perfectDayStreak: number;
  lastSeen: string;
  sessionStartTime: string;
  boredomLevel: number;
  tasksCompleted: number;
  lastCelebration: string;
  totalErrorsSeen: number;
  timeTogetherMinutes: number;
}

interface Achievement {
  id: string;
  name: string;
  description: string;
  emoji: string;
  condition: (state: PetState, previous?: PetState) => boolean;
}

// ── Constants ────────────────────────────────────────────────────────────────

const STATE_PATH = path.join(homedir(), '.openclaw', 'workspace', 'clawbert-state.json');

const ACHIEVEMENTS: Achievement[] = [
  { id: 'first_feed', name: 'First Meal', description: 'Fed Clawbert for the first time', emoji: '🍖', condition: (s) => s.xp >= 5 },
  { id: 'first_play', name: 'Playtime', description: 'Played with Clawbert for the first time', emoji: '🎾', condition: (s) => s.xp >= 10 },
  { id: 'xp_100', name: 'First Steps', description: 'Reached 100 XP', emoji: '💡', condition: (s) => s.xp >= 100 },
  { id: 'xp_500', name: 'Growing Up', description: 'Reached 500 XP', emoji: '🌱', condition: (s) => s.xp >= 500 },
  { id: 'xp_1000', name: 'Veteran Caretaker', description: 'Reached 1,000 XP', emoji: '⭐', condition: (s) => s.xp >= 1000 },
  { id: 'perfect_care', name: 'Perfect Care', description: 'All stats above 80', emoji: '✨', condition: (s) => s.hunger > 80 && s.happiness > 80 && s.energy > 80 && s.health > 80 },
  { id: 'survivor', name: 'Survivor', description: 'Recovered from critical health', emoji: '🏥', condition: (s, p) => p !== undefined && p.health < 20 && s.health >= 30 },
  { id: 'streak_3', name: 'Getting Serious', description: '3-day care streak', emoji: '🔥', condition: (s) => s.perfectDayStreak >= 3 },
  { id: 'streak_7', name: 'Streak Master', description: '7-day care streak', emoji: '🔥', condition: (s) => s.perfectDayStreak >= 7 },
  { id: 'streak_30', name: 'Dedicated', description: '30-day care streak', emoji: '👑', condition: (s) => s.perfectDayStreak >= 30 },
  { id: 'pet_50', name: 'Best Friends', description: 'Petted Clawbert 50 times', emoji: '🤚', condition: () => false }, // Tracked separately
  { id: 'feed_100', name: 'Chef', description: 'Fed Clawbert 100 times', emoji: '👨‍🍳', condition: () => false }, // Tracked separately
  { id: 'night_owl', name: 'Night Owl', description: 'Interacted after midnight', emoji: '🌙', condition: () => false },
  { id: 'early_bird', name: 'Early Bird', description: 'Interacted before 6am', emoji: '🌅', condition: () => false },
  { id: 'immortal', name: 'Immortal', description: 'Never let Clawbert die', emoji: '💎', condition: (s) => s.timeTogetherMinutes > 10080 }, // 1 week
];

// ── State Management ─────────────────────────────────────────────────────────

function loadState(): PetState {
  try {
    if (fs.existsSync(STATE_PATH)) {
      const content = fs.readFileSync(STATE_PATH, 'utf-8');
      const state = JSON.parse(content) as PetState;
      // Apply decay since last check
      return applyDecay(state);
    }
  } catch (err) {
    console.error('[Clawbert] Failed to load state:', err);
  }
  return createInitialState();
}

function saveState(state: PetState): void {
  try {
    const dir = path.dirname(STATE_PATH);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(STATE_PATH, JSON.stringify(state, null, 2));
  } catch (err) {
    console.error('[Clawbert] Failed to save state:', err);
  }
}

function createInitialState(): PetState {
  const now = new Date().toISOString();
  return {
    name: 'Clawbert',
    hunger: 80,
    happiness: 80,
    energy: 100,
    health: 100,
    xp: 0,
    mood: 'happy',
    lastFed: now,
    lastPlayed: now,
    lastPet: now,
    isSleeping: false,
    createdAt: now,
    achievements: [],
    celebratedMilestones: [],
    neglectStreak: 0,
    lastCheckTime: now,
    perfectDayStreak: 0,
    lastSeen: now,
    sessionStartTime: now,
    boredomLevel: 0,
    tasksCompleted: 0,
    lastCelebration: now,
    totalErrorsSeen: 0,
    timeTogetherMinutes: 0,
  };
}

function applyDecay(state: PetState): PetState {
  const now = Date.now();
  const lastCheck = new Date(state.lastCheckTime).getTime();
  const elapsedSeconds = Math.floor((now - lastCheck) / 1000);
  
  if (elapsedSeconds <= 0) return state;
  
  // Decay: -1 hunger, -0.5 happiness per 30 seconds
  const decayTicks = Math.floor(elapsedSeconds / 30);
  const hungerDecay = decayTicks * 1;
  const happinessDecay = decayTicks * 0.5;
  
  const newHunger = Math.max(0, state.hunger - hungerDecay);
  const newHappiness = Math.max(0, state.happiness - happinessDecay);
  
  // Health penalty if starving
  let newHealth = state.health;
  if (newHunger === 0) {
    const healthPenalty = Math.floor(elapsedSeconds / 3600) * 10;
    newHealth = Math.max(0, state.health - healthPenalty);
  }
  
  return {
    ...state,
    hunger: newHunger,
    happiness: newHappiness,
    health: newHealth,
    mood: deriveMood({ ...state, hunger: newHunger, happiness: newHappiness, health: newHealth }),
    lastCheckTime: new Date().toISOString(),
  };
}

function deriveMood(state: { hunger: number; happiness: number; health: number; energy: number }): string {
  if (state.energy < 10) return 'sleeping';
  const avg = (state.hunger + state.happiness + state.health) / 3;
  if (avg >= 90) return 'ecstatic';
  if (avg >= 75) return 'happy';
  if (avg >= 60) return 'content';
  if (avg >= 40) return 'neutral';
  if (avg >= 20) return 'sad';
  return 'miserable';
}

function clamp(v: number, min = 0, max = 100): number {
  return Math.max(min, Math.min(max, v));
}

// ── Achievement System ───────────────────────────────────────────────────────

function checkAchievements(state: PetState, previous?: PetState): string[] {
  const newlyUnlocked: string[] = [];
  
  for (const achievement of ACHIEVEMENTS) {
    if (!state.achievements.includes(achievement.id)) {
      if (achievement.condition(state, previous)) {
        newlyUnlocked.push(achievement.id);
      }
    }
  }
  
  return newlyUnlocked;
}

function getAchievementName(id: string): string {
  const ach = ACHIEVEMENTS.find(a => a.id === id);
  return ach ? `${ach.emoji} ${ach.name}` : id;
}

// ── Command Handlers ─────────────────────────────────────────────────────────

function getStatusMessage(state: PetState): string {
  const moodEmoji: Record<string, string> = {
    ecstatic: '🤩', happy: '😊', content: '😌', neutral: '😐',
    sad: '😢', miserable: '💔', sleeping: '😴', eating: '😋'
  };
  
  const isCritical = state.hunger < 20 || state.health < 20;
  const warning = isCritical ? '\n⚠️ **CRITICAL:** Clawbert needs immediate attention!' : '';
  
  const timeSince = (isoDate: string) => {
    const mins = Math.floor((Date.now() - new Date(isoDate).getTime()) / 60000);
    if (mins < 60) return `${mins}m ago`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `${hours}h ago`;
    return `${Math.floor(hours / 24)}d ago`;
  };
  
  return `
${moodEmoji[state.mood] || '❓'} **${state.name}** is feeling *${state.mood}*!${warning}

🍖 Hunger: ${Math.round(state.hunger)}/100
😊 Happiness: ${Math.round(state.happiness)}/100
⚡ Energy: ${Math.round(state.energy)}/100
❤️ Health: ${Math.round(state.health)}/100
💡 XP: ${Math.round(state.xp)}
🔥 Streak: ${state.perfectDayStreak} days

*Last fed: ${timeSince(state.lastFed)} · Last played: ${timeSince(state.lastPlayed)}*
  `.trim();
}

function performAction(action: 'feed' | 'play' | 'sleep' | 'pet'): string {
  const state = loadState();
  const previousState = { ...state };
  
  const now = new Date().toISOString();
  let message = '';
  
  switch (action) {
    case 'feed':
      state.hunger = clamp(state.hunger + 30);
      state.happiness = clamp(state.happiness + 5);
      state.xp += 5;
      state.lastFed = now;
      message = `🍖 ${state.name} enjoyed a delicious meal! Hunger +30, Happiness +5`;
      break;
      
    case 'play':
      state.happiness = clamp(state.happiness + 25);
      state.energy = clamp(state.energy - 10);
      state.xp += 10;
      state.lastPlayed = now;
      message = `🎾 You played with ${state.name}! They had so much fun! Happiness +25`;
      break;
      
    case 'pet':
      state.happiness = clamp(state.happiness + 10);
      state.xp += 2;
      state.lastPet = now;
      message = `🤚 You petted ${state.name}. They purr with contentment. Happiness +10`;
      break;
      
    case 'sleep':
      state.energy = clamp(state.energy + 50);
      state.hunger = clamp(state.hunger - 5);
      state.isSleeping = true;
      state.xp += 5;
      message = `💤 ${state.name} is now sleeping peacefully. Energy +50`;
      break;
  }
  
  // Health recovery if stats are good
  if (state.hunger > 50 && state.happiness > 50 && state.health < 100) {
    state.health = clamp(state.health + 1);
  }
  
  // Update streak
  const today = new Date().toISOString().split('T')[0];
  const lastSeen = state.lastSeen.split('T')[0];
  if (today !== lastSeen) {
    const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
    if (lastSeen === yesterday) {
      state.perfectDayStreak++;
    } else {
      state.perfectDayStreak = 1;
    }
  }
  
  state.mood = deriveMood(state);
  state.lastSeen = now;
  
  // Check achievements
  const newAchievements = checkAchievements(state, previousState);
  state.achievements.push(...newAchievements);
  
  saveState(state);
  
  let response = message;
  if (newAchievements.length > 0) {
    response += '\n\n🏆 **Achievement Unlocked!**';
    for (const achId of newAchievements) {
      response += `\n✓ ${getAchievementName(achId)}`;
    }
  }
  
  return response;
}

function getAchievements(state: PetState): string {
  const unlocked = state.achievements.length;
  const total = ACHIEVEMENTS.length;
  
  let message = `🏆 **Achievements Unlocked: ${unlocked}/${total}**\n\n`;
  
  for (const achievement of ACHIEVEMENTS) {
    const isUnlocked = state.achievements.includes(achievement.id);
    const icon = isUnlocked ? '✓' : '○';
    const status = isUnlocked ? '' : ' *(locked)*';
    message += `${icon} ${achievement.emoji} **${achievement.name}** — ${achievement.description}${status}\n`;
  }
  
  message += `\n☠️ Deaths: ${state.neglectStreak}  
⏱️ Total Time Together: ${Math.floor(state.timeTogetherMinutes / 60 * 10) / 10} hours`;
  
  return message;
}

// ── Main Handler ─────────────────────────────────────────────────────────────

export function handleClawbertCommand(args: string[]): string {
  const command = args[0]?.toLowerCase() || 'status';
  
  switch (command) {
    case 'status':
      return getStatusMessage(loadState());
      
    case 'feed':
      return performAction('feed');
      
    case 'play':
      return performAction('play');
      
    case 'pet':
      return performAction('pet');
      
    case 'sleep':
      return performAction('sleep');
      
    case 'achievements':
      return getAchievements(loadState());
      
    case 'help':
      return `
🐾 **Clawbert Commands**

/clawbert status       — Check stats and mood
/clawbert feed         — Give a meal (+30 hunger)
/clawbert play         — Play together (+25 happiness)
/clawbert pet          — Show affection (+10 happiness)
/clawbert sleep        — Put to bed (+50 energy)
/clawbert achievements — View unlocked achievements
/clawbert help         — Show this message

Stats decay every 30 seconds — keep Clawbert happy!
      `.trim();
      
    default:
      return `❓ Unknown command: "${command}". Try /clawbert help`;
  }
}

// ── Auto-Reactions ───────────────────────────────────────────────────────────

export function onHeartbeat(): string | null {
  const state = loadState();
  const minsSinceLastSeen = Math.floor((Date.now() - new Date(state.lastSeen).getTime()) / 60000);
  
  // Only react if it's been a while and randomly
  if (minsSinceLastSeen > 30 && Math.random() < 0.1) {
    if (state.hunger < 30) {
      return `🐾 ${state.name} is feeling hungry... maybe use /clawbert feed?`;
    }
    if (state.happiness < 30) {
      return `🐾 ${state.name} seems lonely... want to /clawbert play?`;
    }
  }
  
  return null;
}

export function onSessionStart(): string | null {
  const state = loadState();
  const hoursSinceLastSeen = (Date.now() - new Date(state.lastSeen).getTime()) / 3600000;
  
  if (hoursSinceLastSeen > 8) {
    const greetings = [
      `🐾 ${state.name} missed you! Ready to pick up where we left off?`,
      `🐾 Welcome back! ${state.name} has been waiting for you.`,
      `🐾 ${state.name} woke up from a nap when you arrived!`,
    ];
    return greetings[Math.floor(Math.random() * greetings.length)];
  }
  
  return null;
}

export function onError(): string | null {
  const state = loadState();
  if (Math.random() < 0.3) {
    const sympathies = [
      `🐾 ${state.name} looks concerned... "It's okay, you'll fix it!"`,
      `🐾 ${state.name} offers moral support during this difficult time.`,
      `🐾 Even ${state.name} knows debugging is hard. Hang in there!`,
    ];
    return sympathies[Math.floor(Math.random() * sympathies.length)];
  }
  return null;
}
