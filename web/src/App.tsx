import { useState, useEffect, useCallback, useRef } from 'react';
import './App.css';
import {
  syncToOpenClaw,
  syncFromOpenClaw,
  getSyncStatus,
  type SyncResult,
} from './openclaw-bridge';
import type { PetState, HistoryEntry, ActionDef, Mood } from './types';
import { StatsChart } from './components/StatsChart';
import { AchievementsPanel } from './components/AchievementsPanel';

// ── Constants ────────────────────────────────────────────────────────────────

// ── Constants ────────────────────────────────────────────────────────────────

const ACTIONS: ActionDef[] = [
  { type: 'feed',  label: 'Feed',  emoji: '🍖', delta: { hunger: 30, happiness: 5,  energy:  0, xp: 5  } },
  { type: 'play',  label: 'Play',  emoji: '🎾', delta: { hunger:  0, happiness: 25, energy: -10, xp: 10 } },
  { type: 'sleep', label: 'Sleep', emoji: '💤', delta: { hunger: -5, happiness:  0, energy: 50, xp: 5  } },
  { type: 'pet',   label: 'Pet',  emoji: '🤚', delta: { hunger:  0, happiness: 10, energy:  0, xp: 2  } },
];

function clamp(v: number, min = 0, max = 100) {
  return Math.max(min, Math.min(max, v));
}

function deriveMood(s: Omit<PetState, 'mood'>): Mood {
  if (s.energy < 10) return 'sleeping';
  const avg = (s.hunger + s.happiness + s.health) / 3;
  if (avg >= 90) return 'ecstatic';
  if (avg >= 75) return 'happy';
  if (avg >= 60) return 'content';
  if (avg >= 40) return 'neutral';
  if (avg >= 20) return 'sad';
  return 'miserable';
}

function statColor(v: number) {
  if (v < 20) return '#ef5350';
  if (v < 40) return '#ff9800';
  return '#66bb6a';
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

// ── SVG Pixel Art Cat ────────────────────────────────────────────────────────

type CharacterState = 'idle' | 'happy' | 'sad' | 'sleeping' | 'eating' | 'dead';

function PixelCat({ state, size = 80 }: { state: CharacterState; size?: number }) {
  // Pixel grid: 8x8, each "pixel" is size/8
  const p = size / 8;

  const body: [number, number, string][] = [
    // [col, row, color]
    [2,5, '#8B6914'], [3,5, '#A07C1A'], [4,5, '#A07C1A'], [5,5, '#8B6914'],
    [2,6, '#A07C1A'], [3,6, '#C8A414'], [4,6, '#C8A414'], [5,6, '#A07C1A'],
    [1,7, '#8B6914'], [2,7, '#A07C1A'], [3,7, '#C8A414'], [4,7, '#C8A414'], [5,7, '#A07C1A'], [6,7, '#8B6914'],
    [1,8, '#A07C1A'], [2,8, '#C8A414'], [3,8, '#C8A414'], [4,8, '#C8A414'], [5,8, '#C8A414'], [6,8, '#A07C1A'],
    [0,9, '#6B4F0F'],[1,9, '#8B6914'], [2,9, '#C8A414'], [3,9, '#C8A414'], [4,9, '#C8A414'], [5,9, '#C8A414'], [6,9, '#8B6914'],[7,9,'#6B4F0F'],
    [1,10,'#8B6914'],[2,10,'#A07C1A'],[3,10,'#C8A414'],[4,10,'#C8A414'],[5,10,'#A07C1A'],[6,10,'#8B6914'],
  ];

  // Ears
  const ears: [number,number,string][] = [
    [1,4,'#8B6914'],[2,4,'#A07C1A'],
    [5,4,'#A07C1A'],[6,4,'#8B6914'],
    [1,3,'#A07C1A'],
    [6,3,'#A07C1A'],
    [1,2,'#C8A414'],
    [6,2,'#C8A414'],
  ];

  // Head
  const head: [number,number,string][] = [
    [2,3,'#A07C1A'],[3,3,'#C8A414'],[4,3,'#C8A414'],[5,3,'#A07C1A'],
    [1,4,'#C8A414'],[2,4,'#C8A414'],[3,4,'#C8A414'],[4,4,'#C8A414'],[5,4,'#C8A414'],[6,4,'#C8A414'],
    [2,5,'#C8A414'],[3,5,'#C8A414'],[4,5,'#C8A414'],[5,5,'#C8A414'],
  ];

  // Eyes per state
  function getEyes(s: CharacterState): [number,number,string][] {
    switch (s) {
      case 'happy':
        return [[2,4,'#1a1a1a'],[5,4,'#1a1a1a'],[2,4.4,'#FFD700'],[5,4.4,'#FFD700']];
      case 'sad':
        return [[2,4,'#1a1a1a'],[5,4,'#1a1a1a']];
      case 'sleeping':
        return [[2,4,'#5a5a5a'],[5,4,'#5a5a5a']];
      case 'eating':
        return [[2,4,'#1a1a1a'],[5,4,'#1a1a1a']];
      case 'dead':
        return [[2,4,'#1a1a1a'],[5,4,'#1a1a1a']];
      default:
        return [[2,4,'#1a1a1a'],[5,4,'#1a1a1a']];
    }
  }

  function getMouth(s: CharacterState): [number,number,string][] {
    switch (s) {
      case 'happy':   return [[3,5.5,'#8B4513'],[4,5.5,'#8B4513']];
      case 'sad':     return [[3,5.5,'#5a3020'],[4,5.5,'#5a3020']];
      case 'eating':  return [[3,5.5,'#8B4513'],[4,5.5,'#8B4513']];
      case 'sleeping':return [[3,5.5,'#8B4513'],[4,5.5,'#8B4513']];
      case 'dead':    return [[2.5,5.5,'#5a3020'],[3.5,5.5,'#5a3020']];
      default:        return [[3,5.5,'#8B4513'],[4,5.5,'#8B4513']];
    }
  }

  const eyes = getEyes(state);
  const mouth = getMouth(state);

  const allPixels = [...ears, ...head, ...body, ...eyes, ...mouth];

  const filter = state === 'dead' ? 'grayscale(1) brightness(0.5)' : state === 'sad' ? 'saturate(0.7)' : 'none';

  return (
    <svg
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      style={{ imageRendering: 'pixelated', shapeRendering: 'crispEdges', filter }}
    >
      {allPixels.map(([col, row, color], i) => (
        <rect
          key={i}
          x={col * p}
          y={row * p}
          width={p * 0.95}
          height={p * 0.95}
          fill={color}
        />
      ))}
      {/* Eye shine for normal/idle */}
      {state !== 'dead' && state !== 'sleeping' && state !== 'sad' && (
        <>
          <rect x={2.2*p} y={3.6*p} width={p*0.35} height={p*0.35} fill="rgba(255,255,255,0.7)" />
          <rect x={5.2*p} y={3.6*p} width={p*0.35} height={p*0.35} fill="rgba(255,255,255,0.7)" />
        </>
      )}
      {/* Sleep Zs */}
      {state === 'sleeping' && (
        <text x={6*p} y={1.5*p} fontSize={p*0.9} fill="#93c5fd" fontFamily="monospace" fontWeight="bold">Z</text>
      )}
      {/* Dead X eyes */}
      {state === 'dead' && (
        <>
          <line x1={1.8*p} y1={3.6*p} x2={2.5*p} y2={4.3*p} stroke="#1a1a1a" strokeWidth={p*0.2} />
          <line x1={2.5*p} y1={3.6*p} x2={1.8*p} y2={4.3*p} stroke="#1a1a1a" strokeWidth={p*0.2} />
          <line x1={4.8*p} y1={3.6*p} x2={5.5*p} y2={4.3*p} stroke="#1a1a1a" strokeWidth={p*0.2} />
          <line x1={5.5*p} y1={3.6*p} x2={4.8*p} y2={4.3*p} stroke="#1a1a1a" strokeWidth={p*0.2} />
        </>
      )}
      {/* Eating chomp animation dots */}
      {state === 'eating' && (
        <>
          <rect x={3.2*p} y={5.2*p} width={p*0.4} height={p*0.4} fill="#C8A414" />
          <rect x={4.2*p} y={5.2*p} width={p*0.4} height={p*0.4} fill="#C8A414" />
        </>
      )}
    </svg>
  );
}

// ── Stat Bar ─────────────────────────────────────────────────────────────────

function StatBar({ label, value, decaying }: { label: string; value: number; decaying?: boolean }) {
  return (
    <div className="stat-bar">
      <span className="stat-label">{label}</span>
      <div className="bar-track">
        <div
          className="bar-fill"
          style={{ width: `${value}%`, background: statColor(value) }}
        />
        {decaying && <span className="decay-tick" />}
      </div>
      <span className="stat-value">{Math.round(value)}</span>
    </div>
  );
}

// ── App ──────────────────────────────────────────────────────────────────────

export default function App() {
  const [pet, setPet] = useState<PetState>(() => {
    try {
      const saved = localStorage.getItem('clawbert');
      if (saved) return JSON.parse(saved) as PetState;
    } catch { /* ignore */ }
    return INITIAL;
  });

  const [history, setHistory] = useState<HistoryEntry[]>(() => {
    try {
      const saved = localStorage.getItem('clawbert_history');
      if (saved) return JSON.parse(saved) as HistoryEntry[];
    } catch { /* ignore */ }
    return [];
  });

  const [deaths, setDeaths] = useState(() =>
    parseInt(localStorage.getItem('clawbert_deaths') ?? '0', 10)
  );

  const [feedback, setFeedback] = useState('');
  const [bounce, setBounce] = useState(false);
  const [decaying, setDecaying] = useState(false);
  const [isDead, setIsDead] = useState(false);
  const [editingName, setEditingName] = useState(false);
  const [nameInput, setNameInput] = useState('');
  const [activeTab, setActiveTab] = useState<'main' | 'stats' | 'achievements'>('main');
  const nameInputRef = useRef<HTMLInputElement>(null);

  // OpenClaw sync state
  const [syncStatus, setSyncStatus] = useState<{ connected: boolean; source: 'file' | 'localStorage' | 'none' }>(
    getSyncStatus()
  );
  const [isSyncing, setIsSyncing] = useState(false);

  // Persist to localStorage
  useEffect(() => { localStorage.setItem('clawbert', JSON.stringify(pet)); }, [pet]);
  useEffect(() => { localStorage.setItem('clawbert_history', JSON.stringify(history)); }, [history]);
  useEffect(() => { localStorage.setItem('clawbert_deaths', String(deaths)); }, [deaths]);

  // Sync TO OpenClaw whenever pet state changes (with debounce)
  useEffect(() => {
    if (isDead) return;
    
    const timeout = setTimeout(() => {
      setIsSyncing(true);
      syncToOpenClaw(pet, history, deaths)
        .then((result: SyncResult) => {
          setLastSyncTime(result.timestamp);
          setSyncStatus(getSyncStatus());
        })
        .catch((err) => {
          console.error('[App] Sync to OpenClaw failed:', err);
        })
        .finally(() => {
          setIsSyncing(false);
        });
    }, 500); // 500ms debounce

    return () => clearTimeout(timeout);
  }, [pet.hunger, pet.happiness, pet.energy, pet.health, pet.xp, pet.mood, pet.name, isDead]);

  // Poll FROM OpenClaw every 5 seconds to catch external updates
  useEffect(() => {
    if (isDead) return;

    const interval = setInterval(() => {
      syncFromOpenClaw()
        .then(({ pet: remotePet, source }) => {
          if (remotePet && source !== 'none') {
            // Merge remote state - only update stats, preserve local UI state
            setPet(prev => ({
              ...prev,
              hunger: remotePet.hunger,
              happiness: remotePet.happiness,
              energy: remotePet.energy,
              health: remotePet.health,
              xp: remotePet.xp,
              mood: remotePet.mood,
              lastUpdated: remotePet.lastUpdated,
            }));
            setLastSyncTime(Date.now());
          }
        })
        .catch((err) => {
          console.error('[App] Sync from OpenClaw failed:', err);
        });
    }, 5000); // Every 5 seconds

    return () => clearInterval(interval);
  }, [isDead]);

  // Stat decay timer — every 30s
  useEffect(() => {
    if (isDead) return;
    const interval = setInterval(() => {
      setDecaying(true);
      setPet(prev => {
        const next = {
          ...prev,
          hunger:    clamp(prev.hunger    - 1),
          happiness: clamp(prev.happiness - 0.5),
        };
        next.mood = deriveMood(next);
        return next;
      });
      setTimeout(() => setDecaying(false), 600);
    }, 30_000);
    return () => clearInterval(interval);
  }, [isDead]);

  // Check for death
  useEffect(() => {
    if (!isDead && pet.health <= 0) {
      setIsDead(true);
      setDeaths(d => d + 1);
    }
  }, [pet.health, isDead]);

  const perform = useCallback((action: ActionDef) => {
    if (isDead) return;
    const entry: HistoryEntry = {
      id: crypto.randomUUID(),
      emoji: action.emoji,
      text: `${pet.name} — ${action.label}`,
      time: Date.now(),
    };

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
      // Health recovery when stats are good
      if (next.hunger > 50 && next.happiness > 50 && next.health < 100) {
        next.health = clamp(next.health + 1);
      }
      return next;
    });

    setHistory(h => [entry, ...h].slice(0, 5));
    setFeedback(`${action.emoji} ${action.label}!`);
    setBounce(true);
    setTimeout(() => { setFeedback(''); setBounce(false); }, 1600);
  }, [isDead, pet.name]);

  const revive = () => {
    const newPet: PetState = { ...INITIAL, id: crypto.randomUUID(), lastUpdated: Date.now() };
    setPet(newPet);
    setIsDead(false);
    setHistory([]);
  };

  const startRename = () => {
    setNameInput(pet.name);
    setEditingName(true);
    setTimeout(() => nameInputRef.current?.select(), 50);
  };

  const commitRename = () => {
    if (nameInput.trim()) {
      setPet(p => ({ ...p, name: nameInput.trim() }));
    }
    setEditingName(false);
  };

  const characterState: CharacterState = isDead ? 'dead'
    : pet.mood === 'sleeping' ? 'sleeping'
    : pet.mood === 'eating'   ? 'eating'
    : pet.mood === 'sad' || pet.mood === 'miserable' ? 'sad'
    : pet.mood === 'ecstatic' || pet.mood === 'happy' ? 'happy'
    : 'idle';

  const isCritical = !isDead && (pet.hunger < 20 || pet.health < 20);
  const critFrameClass = isCritical ? 'critical-frame' : '';

  // Render tab content
  const renderTabContent = () => {
    switch (activeTab) {
      case 'stats':
        return (
          <div className="tab-panel">
            <button className="back-btn" onClick={() => setActiveTab('main')}>← Back</button>
            <StatsChart pet={pet} history={history} />
          </div>
        );
      case 'achievements':
        return (
          <div className="tab-panel">
            <button className="back-btn" onClick={() => setActiveTab('main')}>← Back</button>
            <AchievementsPanel pet={pet} deaths={deaths} />
          </div>
        );
      default:
        return null;
    }
  };

  return (
    <div className="app">
      <div className={`device ${critFrameClass}`}>

        {/* Header */}
        <div className="device-header">
          <span className="device-title">🐾 OpenClaw</span>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            {syncStatus.connected && (
              <span 
                className={`sync-indicator ${isSyncing ? 'syncing' : ''}`}
                title={`Synced via ${syncStatus.source}`}
                style={{
                  fontSize: 11,
                  color: syncStatus.source === 'file' ? '#4ade80' : '#fbbf24',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 4,
                  opacity: isSyncing ? 0.6 : 1,
                  transition: 'opacity 0.2s',
                }}
              >
                {syncStatus.source === 'file' ? '🔗' : '💾'} 
                {syncStatus.source === 'file' ? 'Synced' : 'Local'}
              </span>
            )}
            <span className="device-badge">v0.3</span>
          </div>
        </div>

        {activeTab !== 'main' ? (
          renderTabContent()
        ) : (
          <>
        {/* Character */}
        <div className={`character-wrap ${bounce ? 'bounce' : ''}`}>
          {isDead && (
            <div className="death-overlay">
              <PixelCat state="dead" size={72} />
              <p>CLAWBERT<br />HAS PASSED</p>
              <button className="revive-btn" onClick={revive}>▶ REVIVE</button>
            </div>
          )}
          <div className="character-glow" style={{ background: isCritical ? '#ef5350' : '#e94560' }} />
          <div className="cat-container">
            <PixelCat state={characterState} size={72} />
          </div>
        </div>

        {/* Name + Mood */}
        <div className="pet-info">
          <div className="pet-name-row">
            {editingName ? (
              <input
                ref={nameInputRef}
                className="name-input"
                value={nameInput}
                onChange={e => setNameInput(e.target.value)}
                onBlur={commitRename}
                onKeyDown={e => { if (e.key === 'Enter') commitRename(); if (e.key === 'Escape') setEditingName(false); }}
                maxLength={14}
              />
            ) : (
              <h1 className="pet-name">{pet.name}</h1>
            )}
            {!editingName && (
              <button className="rename-btn" onClick={startRename} title="Rename">✏️</button>
            )}
          </div>
          <div style={{ display: 'flex', justifyContent: 'center', gap: 8, alignItems: 'center', marginTop: 4 }}>
            <p className="pet-mood">{pet.mood.charAt(0).toUpperCase() + pet.mood.slice(1)}</p>
            {isCritical && <span className="critical-badge">⚠ CRITICAL</span>}
          </div>
        </div>

        {/* Stats */}
        <div className="stats-panel">
          <StatBar label="🍖" value={pet.hunger}    decaying={decaying} />
          <StatBar label="😊" value={pet.happiness} decaying={decaying} />
          <StatBar label="⚡" value={pet.energy}    decaying={false} />
          <StatBar label="❤️" value={pet.health}    decaying={false} />
          <div className="xp-row">
            <span>💡 XP</span>
            <span className="xp-value">{Math.round(pet.xp)}</span>
            {deaths > 0 && <span className="death-counter">☠ {deaths}</span>}
          </div>
        </div>

        {/* Actions */}
        <div className="actions">
          {ACTIONS.map(a => (
            <button
              key={a.type}
              className="action-btn"
              onClick={() => perform(a)}
              disabled={isDead}
            >
              <span className="action-emoji">{a.emoji}</span>
              <span className="action-label">{a.label}</span>
            </button>
          ))}
        </div>

        {/* Feedback */}
        <div className={`feedback ${feedback ? 'show' : ''}`}>{feedback}</div>

        {/* History Log */}
        {history.length > 0 && (
          <div className="history-log">
            <div className="history-log-title">◈ RECENT</div>
            <div className="history-list">
              {history.map(entry => (
                <div key={entry.id} className="history-entry">
                  <span className="history-entry-icon">{entry.emoji}</span>
                  <span className="history-entry-text">{entry.text}</span>
                  <span className="history-time">{new Date(entry.time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Speaker Grille */}
        <div className="speaker-grille">
          {[0,1,2].map(row => (
            <div key={row} className="speaker-row">
              {[...Array(7)].map((_, i) => (
                <div key={i} className="speaker-dot" />
              ))}
            </div>
          ))}
        </div>
      </div>

      <p className="hint">◈ Stats decay every 30s — keep Clawbert alive! 💾</p>
    </div>
  );
}
