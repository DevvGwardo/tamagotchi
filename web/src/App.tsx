import { useState, useEffect, useCallback } from 'react';
import './App.css';

// ── Types (mirrors shared/types.ts) ─────────────────────────────────────────

type Mood = 'ecstatic' | 'happy' | 'content' | 'neutral' | 'sad' | 'miserable' | 'sleeping' | 'eating';
type ActionType = 'feed' | 'play' | 'sleep' | 'pet';

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

interface ActionDef {
  type: ActionType;
  label: string;
  emoji: string;
  delta: { hunger: number; happiness: number; energy: number; xp: number };
}

const ACTIONS: ActionDef[] = [
  { type: 'feed',  label: 'Feed',  emoji: '🍖', delta: { hunger: 30, happiness: 5,  energy:  0, xp: 5  } },
  { type: 'play',  label: 'Play',  emoji: '🎾', delta: { hunger:  0, happiness: 25, energy: -10, xp: 10 } },
  { type: 'sleep', label: 'Sleep', emoji: '💤', delta: { hunger: -5, happiness:  0, energy: 50, xp: 5  } },
  { type: 'pet',   label: 'Pet',  emoji: '🤚', delta: { hunger:  0, happiness: 10, energy:  0, xp: 2  } },
];

const MOOD_SPRITES: Record<Mood, { main: string; accent: string; bg: string }> = {
  ecstatic:  { main: '🤩', accent: '✨', bg: '#fff9c4' },
  happy:     { main: '😊', accent: '💛', bg: '#f1f8e9' },
  content:   { main: '🙂', accent: '🌿', bg: '#e8f5e9' },
  neutral:   { main: '😐', accent: '⚪', bg: '#f5f5f5' },
  sad:       { main: '😢', accent: '💧', bg: '#e3f2fd' },
  miserable: { main: '😭', accent: '💔', bg: '#ffebee' },
  sleeping:  { main: '😴', accent: '🌙', bg: '#ede7f6' },
  eating:    { main: '😋', accent: '🍽️', bg: '#fff3e0' },
};

function clamp(v: number, min = 0, max = 100) {
  return Math.max(min, Math.min(max, v));
}

function deriveMood(s: PetState): Mood {
  if (s.energy < 10) return 'sleeping';
  const avg = (s.hunger + s.happiness + s.health) / 3;
  if (avg >= 90) return 'ecstatic';
  if (avg >= 75) return 'happy';
  if (avg >= 60) return 'content';
  if (avg >= 40) return 'neutral';
  if (avg >= 20) return 'sad';
  return 'miserable';
}

const INITIAL: PetState = {
  id: crypto.randomUUID(),
  name: 'Clawbert',
  hunger: 80,
  happiness: 80,
  energy: 100,
  xp: 0,
  health: 100,
  mood: 'happy',
  skin: 'default',
  lastUpdated: Date.now(),
};

function statColor(v: number) {
  if (v < 20) return '#ef5350';
  if (v < 40) return '#ff9800';
  return '#66bb6a';
}

// ── Components ────────────────────────────────────────────────────────────────

function StatBar({ label, value }: { label: string; value: number }) {
  return (
    <div className="stat-bar">
      <span className="stat-label">{label}</span>
      <div className="bar-track">
        <div
          className="bar-fill"
          style={{
            width: `${value}%`,
            background: statColor(value),
          }}
        />
      </div>
      <span className="stat-value">{Math.round(value)}</span>
    </div>
  );
}

function ActionButton({ action, onPerform }: { action: ActionDef; onPerform: () => void }) {
  return (
    <button className="action-btn" onClick={onPerform}>
      <span className="action-emoji">{action.emoji}</span>
      <span className="action-label">{action.label}</span>
    </button>
  );
}

// ── App ───────────────────────────────────────────────────────────────────────

export default function App() {
  const [pet, setPet] = useState<PetState>(() => {
    try {
      const saved = localStorage.getItem('clawbert');
      if (saved) return JSON.parse(saved) as PetState;
    } catch { /* ignore */ }
    return INITIAL;
  });
  const [feedback, setFeedback] = useState('');
  const [bounce, setBounce] = useState(false);

  // Persist
  useEffect(() => {
    localStorage.setItem('clawbert', JSON.stringify(pet));
  }, [pet]);

  const perform = useCallback((action: ActionDef) => {
    setPet(prev => {
      const next: PetState = {
        ...prev,
        hunger:    clamp(prev.hunger    + action.delta.hunger),
        happiness: clamp(prev.happiness + action.delta.happiness),
        energy:    clamp(prev.energy    + action.delta.energy),
        xp:        prev.xp + action.delta.xp,
        mood:      deriveMood({ ...prev, ...action.delta }),
        lastUpdated: Date.now(),
      };
      return next;
    });
    setFeedback(`${action.emoji} ${action.label}!`);
    setBounce(true);
    setTimeout(() => { setFeedback(''); setBounce(false); }, 1600);
  }, []);

  const sprite = MOOD_SPRITES[pet.mood];

  return (
    <div className="app" style={{ background: sprite.bg }}>
      <div className="device">
        {/* Header */}
        <div className="device-header">
          <span className="device-title">🐾 OpenClaw Tamagotchi</span>
          <span className="device-badge">v0.1</span>
        </div>

        {/* Character */}
        <div className={`character-wrap ${bounce ? 'bounce' : ''}`}>
          <div className="character-glow" style={{ background: sprite.accent }} />
          <span className="character-sprite">{sprite.main}</span>
          <div className="character-accent">{sprite.accent}</div>
        </div>

        {/* Name + Mood */}
        <div className="pet-info">
          <h1 className="pet-name">{pet.name}</h1>
          <p className="pet-mood">{pet.mood.charAt(0).toUpperCase() + pet.mood.slice(1)}</p>
        </div>

        {/* Stats */}
        <div className="stats-panel">
          <StatBar label="🍖" value={pet.hunger} />
          <StatBar label="😊" value={pet.happiness} />
          <StatBar label="⚡" value={pet.energy} />
          <StatBar label="❤️" value={pet.health} />
          <div className="xp-row">
            <span>💡 XP</span>
            <span className="xp-value">{Math.round(pet.xp)} XP</span>
          </div>
        </div>

        {/* Actions */}
        <div className="actions">
          {ACTIONS.map(a => (
            <ActionButton key={a.type} action={a} onPerform={() => perform(a)} />
          ))}
        </div>

        {/* Feedback */}
        <div className={`feedback ${feedback ? 'show' : ''}`}>
          {feedback}
        </div>
      </div>

      {/* Pet History Note */}
      <p className="hint">State is saved to localStorage — refresh-safe! 💾</p>
    </div>
  );
}
