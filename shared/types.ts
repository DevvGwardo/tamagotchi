/**
 * OpenClaw Tamagotchi — Shared Type Definitions
 * Shared between iOS/watchOS app and web dashboard
 */

export type StatKey = 'hunger' | 'happiness' | 'energy' | 'xp' | 'health';

export interface PetStats {
  hunger: number;      // 0–100
  happiness: number;   // 0–100
  energy: number;      // 0–100
  xp: number;          // 0–∞
  health: number;      // 0–100
}

export type Mood = 'ecstatic' | 'happy' | 'content' | 'neutral' | 'sad' | 'miserable' | 'sleeping' | 'eating';

export interface PetState {
  id: string;
  name: string;
  stats: PetStats;
  mood: Mood;
  lastFed: number;     // Unix timestamp
  lastPlayed: number;
  lastSlept: number;
  lastUpdated: number;
  skin: string;        // e.g. 'default', 'cyber', 'seasonal-xmas'
  createdAt: number;
}

export type ActionType = 'feed' | 'play' | 'sleep' | 'pet';

export interface GameAction {
  type: ActionType;
  timestamp: number;
  delta: Partial<PetStats>;
}

export const INITIAL_STATS: PetStats = {
  hunger: 80,
  happiness: 80,
  energy: 100,
  xp: 0,
  health: 100,
};

export const STAT_DECAY_PER_HOUR: Partial<PetStats> = {
  hunger: -2,
  happiness: -1,
};

export const ACTION_EFFECTS: Record<ActionType, Partial<PetStats>> = {
  feed:   { hunger: +30, happiness: +5 },
  play:   { happiness: +25, energy: -10 },
  sleep:  { energy: +50, hunger: -5 },
  pet:    { happiness: +10 },
};

export const MOOD_THRESHOLDS: Array<{ mood: Mood; min: number }> = [
  { mood: 'ecstatic', min: 90 },
  { mood: 'happy',    min: 75 },
  { mood: 'content',  min: 60 },
  { mood: 'neutral',  min: 40 },
  { mood: 'sad',      min: 20 },
  { mood: 'miserable',min: 0  },
];

export function deriveMood(stats: PetStats): Mood {
  if (stats.energy < 10) return 'sleeping';
  const avg = (stats.hunger + stats.happiness + stats.health) / 3;
  for (const t of MOOD_THRESHOLDS) {
    if (avg >= t.min) return t.mood;
  }
  return 'miserable';
}

export function computeStats(current: PetStats, elapsedMs: number, actions: GameAction[]): PetStats {
  const hours = elapsedMs / 3_600_000;
  const decayed = {
    hunger:    Math.max(0, current.hunger    + STAT_DECAY_PER_HOUR.hunger!    * hours),
    happiness: Math.max(0, current.happiness + STAT_DECAY_PER_HOUR.happiness! * hours),
    energy:    current.energy,  // energy doesn't passively decay
    xp:        current.xp,
    health:    current.health,
  };
  // Apply action deltas
  let stats = { ...decayed };
  for (const action of actions) {
    stats.hunger    = Math.min(100, Math.max(0, stats.hunger    + (action.delta.hunger    ?? 0)));
    stats.happiness = Math.min(100, Math.max(0, stats.happiness + (action.delta.happiness ?? 0)));
    stats.energy    = Math.min(100, Math.max(0, stats.energy    + (action.delta.energy    ?? 0)));
    stats.xp        = stats.xp + (action.delta.xp ?? 0);
  }
  // Health penalty if starving
  if (stats.hunger === 0) stats.health = Math.max(0, stats.health - 10 * hours);
  return stats;
}
