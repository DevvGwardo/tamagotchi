/**
 * OpenClaw Bridge - Sync Tamagotchi state between web app and OpenClaw skill
 * 
 * This module provides bidirectional sync between the web app's localStorage
 * and the OpenClaw skill's state file at ~/.openclaw/workspace/clawbert-state.json
 * 
 * Since browsers cannot directly access the filesystem, this uses:
 * - File API access when available (Electron, Tauri, or custom bridge)
 * - localStorage fallback for standard web browsers
 */

import type { PetState as WebPetState, Mood } from './types';

// Path to the OpenClaw state file (used when file API is available)
const OPENCLAW_STATE_PATH = '/Users/devgwardo/.openclaw/workspace/clawbert-state.json';

// Keys for localStorage
const STORAGE_KEY = 'clawbert';
const STORAGE_HISTORY_KEY = 'clawbert_history';
const STORAGE_DEATHS_KEY = 'clawbert_deaths';
const LAST_SYNC_KEY = 'clawbert_last_sync';

// OpenClaw skill's state format
interface OpenClawPetState {
  name: string;
  hunger: number;
  happiness: number;
  energy: number;
  health: number;
  xp: number;
  mood: Mood;
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
  // Sync metadata
  _syncVersion?: number;
  _lastSyncFromWeb?: number;
}

interface SyncResult {
  success: boolean;
  source: 'file' | 'localStorage' | 'fallback';
  timestamp: number;
}

// Check if we have file system access (via a custom API or Electron)
function hasFileAccess(): boolean {
  return typeof (window as any).__openclaw_fileAPI !== 'undefined';
}

// Try to read from file system
async function readFromFile(): Promise<OpenClawPetState | null> {
  try {
    if (!hasFileAccess()) return null;
    
    const fileAPI = (window as any).__openclaw_fileAPI;
    const content = await fileAPI.readFile(OPENCLAW_STATE_PATH);
    return JSON.parse(content) as OpenClawPetState;
  } catch (err) {
    console.log('[OpenClaw Bridge] File read failed, using localStorage:', err);
    return null;
  }
}

// Try to write to file system
async function writeToFile(state: OpenClawPetState): Promise<boolean> {
  try {
    if (!hasFileAccess()) return false;
    
    const fileAPI = (window as any).__openclaw_fileAPI;
    await fileAPI.writeFile(OPENCLAW_STATE_PATH, JSON.stringify(state, null, 2));
    return true;
  } catch (err) {
    console.log('[OpenClaw Bridge] File write failed:', err);
    return false;
  }
}

// Read from localStorage
function readFromLocalStorage(): { pet: WebPetState | null; history: any[]; deaths: number } {
  try {
    const petRaw = localStorage.getItem(STORAGE_KEY);
    const historyRaw = localStorage.getItem(STORAGE_HISTORY_KEY);
    const deathsRaw = localStorage.getItem(STORAGE_DEATHS_KEY);
    
    return {
      pet: petRaw ? JSON.parse(petRaw) : null,
      history: historyRaw ? JSON.parse(historyRaw) : [],
      deaths: deathsRaw ? parseInt(deathsRaw, 10) : 0,
    };
  } catch (err) {
    console.error('[OpenClaw Bridge] localStorage read error:', err);
    return { pet: null, history: [], deaths: 0 };
  }
}

// Write to localStorage
function writeToLocalStorage(pet: WebPetState, history: any[], deaths: number): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(pet));
    localStorage.setItem(STORAGE_HISTORY_KEY, JSON.stringify(history));
    localStorage.setItem(STORAGE_DEATHS_KEY, String(deaths));
  } catch (err) {
    console.error('[OpenClaw Bridge] localStorage write error:', err);
  }
}

// Convert web PetState to OpenClaw format
function webToOpenClaw(webState: WebPetState): OpenClawPetState {
  const now = new Date().toISOString();
  
  return {
    name: webState.name,
    hunger: Math.round(webState.hunger),
    happiness: Math.round(webState.happiness),
    energy: Math.round(webState.energy),
    health: Math.round(webState.health),
    xp: Math.round(webState.xp),
    mood: webState.mood,
    lastFed: now,
    lastPlayed: now,
    lastPet: now,
    isSleeping: webState.mood === 'sleeping',
    createdAt: new Date(webState.lastUpdated - 86400000).toISOString(), // Estimate
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
    _syncVersion: Date.now(),
    _lastSyncFromWeb: Date.now(),
  };
}

// Convert OpenClaw format to web PetState
function openClawToWeb(openClawState: OpenClawPetState): WebPetState {
  return {
    id: crypto.randomUUID(),
    name: openClawState.name,
    hunger: clamp(openClawState.hunger, 0, 100),
    happiness: clamp(openClawState.happiness, 0, 100),
    energy: clamp(openClawState.energy, 0, 100),
    health: clamp(openClawState.health, 0, 100),
    xp: openClawState.xp,
    mood: openClawState.mood,
    skin: 'default',
    lastUpdated: Date.now(),
  };
}

function clamp(v: number, min = 0, max = 100): number {
  return Math.max(min, Math.min(max, v));
}

/**
 * Sync web app state TO OpenClaw (file or localStorage)
 * Call this whenever pet state changes (feed, play, etc.)
 */
export async function syncToOpenClaw(pet: WebPetState, history?: any[], deaths?: number): Promise<SyncResult> {
  const timestamp = Date.now();
  
  // Convert web state to OpenClaw format
  const openClawState = webToOpenClaw(pet);
  
  // Try to write to file first
  const fileSuccess = await writeToFile(openClawState);
  
  if (fileSuccess) {
    // Also update localStorage as cache
    writeToLocalStorage(pet, history || [], deaths || 0);
    localStorage.setItem(LAST_SYNC_KEY, String(timestamp));
    
    return {
      success: true,
      source: 'file',
      timestamp,
    };
  }
  
  // Fall back to localStorage
  writeToLocalStorage(pet, history || [], deaths || 0);
  localStorage.setItem(LAST_SYNC_KEY, String(timestamp));
  
  return {
    success: true,
    source: 'localStorage',
    timestamp,
  };
}

/**
 * Sync FROM OpenClaw TO web app state
 * Call this periodically (e.g., every 5 seconds) to catch updates from OpenClaw skill
 * 
 * Returns null if no updates needed (prevents infinite loops)
 * Returns updated state if OpenClaw has newer data
 */
export async function syncFromOpenClaw(): Promise<{ pet: WebPetState | null; source: 'file' | 'localStorage' | 'none' }> {
  const timestamp = Date.now();
  const lastSync = parseInt(localStorage.getItem(LAST_SYNC_KEY) || '0', 10);
  
  // Prevent sync loops - if we synced recently, don't read
  const SYNC_COOLDOWN_MS = 1000; // 1 second cooldown
  if (timestamp - lastSync < SYNC_COOLDOWN_MS) {
    return { pet: null, source: 'none' };
  }
  
  // Try to read from file first
  const fileState = await readFromFile();
  
  if (fileState) {
    // Check if OpenClaw skill has newer data
    const openClawLastUpdate = new Date(fileState.lastCheckTime || fileState.lastSeen).getTime();
    const webLastUpdate = lastSync;
    
    // Only update if OpenClaw has newer data AND it didn't come from web
    if (openClawLastUpdate > webLastUpdate && !fileState._lastSyncFromWeb) {
      const webState = openClawToWeb(fileState);
      localStorage.setItem(LAST_SYNC_KEY, String(timestamp));
      return { pet: webState, source: 'file' };
    }
    
    return { pet: null, source: 'none' };
  }
  
  // Fall back to localStorage - check if there's external updates
  const localData = readFromLocalStorage();
  if (localData.pet && localData.pet.lastUpdated > lastSync + SYNC_COOLDOWN_MS) {
    localStorage.setItem(LAST_SYNC_KEY, String(timestamp));
    return { pet: localData.pet, source: 'localStorage' };
  }
  
  return { pet: null, source: 'none' };
}

/**
 * Check if OpenClaw sync is available (file access or localStorage)
 */
export function isOpenClawSyncAvailable(): boolean {
  return hasFileAccess() || typeof localStorage !== 'undefined';
}

/**
 * Get the current sync source status
 */
export function getSyncStatus(): { connected: boolean; source: 'file' | 'localStorage' | 'none' } {
  if (hasFileAccess()) {
    return { connected: true, source: 'file' };
  }
  if (typeof localStorage !== 'undefined') {
    return { connected: true, source: 'localStorage' };
  }
  return { connected: false, source: 'none' };
}

// Type definitions for the web app (copied from App.tsx for type safety)
interface PetState {
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

// Export types
export type { OpenClawPetState, SyncResult, PetState as WebPetState };
