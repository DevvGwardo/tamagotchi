/**
 * Web App Type Definitions
 */

export type Mood = 'ecstatic' | 'happy' | 'content' | 'neutral' | 'sad' | 'miserable' | 'sleeping' | 'eating';
export type ActionType = 'feed' | 'play' | 'sleep' | 'pet';

export interface PetState {
  id: string;
  name: string;
  hunger: number;
  happiness: number;
  energy: number;
  xp: number;
  health: number;
  mood: Mood;
  skin: string;
  lastUpdated: number;
}

export interface HistoryEntry {
  id: string;
  emoji: string;
  text: string;
  time: number;
}

export interface ActionDef {
  type: ActionType;
  label: string;
  emoji: string;
  delta: { hunger: number; happiness: number; energy: number; xp: number };
}
