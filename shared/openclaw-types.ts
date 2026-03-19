/**
 * OpenClaw Tamagotchi — OpenClaw Integration Types
 * Types for OpenClaw-to-Tamagotchi communication
 */

/** Commands that OpenClaw can send to the Tamagotchi */
export type OpenClawCommand =
  | 'feed'      // Feed the pet
  | 'play'      // Play with the pet
  | 'pet'       // Pet/give attention
  | 'sleep'     // Put to sleep
  | 'status'    // Get current status
  | 'achievements' // Get unlocked achievements
  | 'customize';   // Access customization options

/** Events that the Tamagotchi can report to OpenClaw */
export type OpenClawEvent =
  | 'startup'          // Tamagotchi started/restarted
  | 'taskComplete'     // An action completed successfully
  | 'error'            // Something went wrong
  | 'heartbeat'        // Periodic status check
  | 'longConversation'; // User has had extended interaction

/** Metadata for sync JSON file format */
export interface SyncMetadata {
  version: string;           // Format version
  lastModified: number;      // Unix timestamp
  deviceId: string;          // Source device identifier
  checksum: string;          // Data integrity hash
}

/** Definition for an unlockable achievement */
export interface AchievementDefinition {
  id: string;
  name: string;
  description: string;
  condition: string;         // Human-readable unlock condition
  icon?: string;             // Optional icon identifier
  secret?: boolean;          // Hidden until unlocked
}

/** Achievement definitions registry */
export const ACHIEVEMENTS: Record<string, AchievementDefinition> = {
  first_feed: {
    id: 'first_feed',
    name: 'First Meal',
    description: 'Feed your pet for the first time',
    condition: 'Use the feed command once',
    icon: '🍖',
  },
  first_play: {
    id: 'first_play',
    name: 'Playtime!',
    description: 'Play with your pet for the first time',
    condition: 'Use the play command once',
    icon: '🎾',
  },
  night_owl: {
    id: 'night_owl',
    name: 'Night Owl',
    description: 'Feed your pet after midnight',
    condition: 'Use feed command between 00:00 and 06:00',
    icon: '🌙',
    secret: true,
  },
  marathon_player: {
    id: 'marathon_player',
    name: 'Marathon Player',
    description: 'Play with your pet 5 times in one hour',
    condition: 'Use play command 5 times within 60 minutes',
    icon: '🏆',
  },
  caretaker_streak_7: {
    id: 'caretaker_streak_7',
    name: 'Dedicated Caretaker',
    description: 'Maintain a 7-day care streak',
    condition: 'Interact with your pet at least once per day for 7 consecutive days',
    icon: '🔥',
  },
  resurrection: {
    id: 'resurrection',
    name: 'Resurrection',
    description: 'Bring your pet back from the brink',
    condition: 'Revive your pet after health reaches 0',
    icon: '✨',
    secret: true,
  },
};

/** Helper to get all achievement IDs */
export const ACHIEVEMENT_IDS = Object.keys(ACHIEVEMENTS) as string[];

/** Helper to check if an achievement exists */
export function isValidAchievement(id: string): boolean {
  return id in ACHIEVEMENTS;
}
