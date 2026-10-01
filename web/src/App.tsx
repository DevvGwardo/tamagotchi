import { useState, useEffect, useCallback, useRef } from 'react';
import './App.css';
import {
  syncToHermes,
  syncFromHermes,
  getSyncStatus,
} from './hermes-bridge';
import type { PetState, HistoryEntry, ActionDef, Mood } from './types';

// ── Constants ────────────────────────────────────────────────────────────────

const ACTIONS: ActionDef[] = [
  { type: 'feed',  label: 'Feed',  emoji: '🍎', delta: { hunger: 30, happiness: 5,  energy: 0,   xp: 5  } },
  { type: 'play',  label: 'Play',  emoji: '🎮', delta: { hunger: 0,  happiness: 25, energy: -10, xp: 10 } },
  { type: 'pet',   label: 'Pet',   emoji: '💕', delta: { hunger: 0,  happiness: 10, energy: 0,   xp: 2  } },
  { type: 'sleep', label: 'Sleep', emoji: '💤', delta: { hunger: -5, happiness: 0,  energy: 50,  xp: 5  } },
];

const ACTION_COLORS: Record<string, string> = {
  feed:  '#22C55E',
  play:  '#FCD34D',
  pet:   '#F472B6',
  sleep: '#8B5CF6',
};

const STAT_DOTS = [
  { key: 'hunger',    color: '#22C55E' },
  { key: 'happiness', color: '#F472B6' },
  { key: 'energy',    color: '#8B5CF6' },
  { key: 'health',    color: '#14B8A6' },
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

function getLevel(xp: number): number {
  return Math.floor(xp / 100) + 1;
}

function getPetEmoji(mood: Mood, isDead: boolean): string {
  if (isDead) return '💀';
  switch (mood) {
    case 'sleeping':  return '😴';
    case 'ecstatic':  return '😸';
    case 'happy':     return '😺';
    case 'content':   return '🐱';
    case 'neutral':   return '😐';
    case 'sad':       return '😢';
    case 'miserable': return '😿';
    case 'eating':    return '😋';
    default:          return '😺';
  }
}

function getMoodLabel(mood: Mood): string {
  const labels: Record<Mood, string> = {
    ecstatic:  'Ecstatic 🌟',
    happy:     'Happy 😊',
    content:   'Content 😌',
    neutral:   'Neutral 😐',
    sad:       'Sad 😢',
    miserable: 'Miserable 😞',
    sleeping:  'Sleeping 💤',
    eating:    'Eating 🍽️',
  };
  return labels[mood] || mood;
}

const INITIAL: PetState = {
  id: crypto.randomUUID(),
  name: 'Hermes',
  hunger: 80,
  happiness: 80,
  energy: 100,
  xp: 0,
  health: 100,
  mood: 'happy',
  skin: 'default',
  lastUpdated: Date.now(),
};

type ViewState = 'hatch' | 'main' | 'chat' | 'sleeping' | 'lowStats' | 'dead';

interface ChatMessage {
  id: string;
  text: string;
  sender: 'pet' | 'user';
}

// ── App ──────────────────────────────────────────────────────────────────────

export default function App() {
  const [isHatched, setIsHatched] = useState(() => {
    return localStorage.getItem('hermes_hatched') === 'true';
  });

  const [pet, setPet] = useState<PetState>(() => {
    try {
      const saved = localStorage.getItem('hermes');
      if (saved) return JSON.parse(saved) as PetState;
    } catch { /* ignore */ }
    return INITIAL;
  });

  const [history, setHistory] = useState<HistoryEntry[]>(() => {
    try {
      const saved = localStorage.getItem('hermes_history');
      if (saved) return JSON.parse(saved) as HistoryEntry[];
    } catch { /* ignore */ }
    return [];
  });

  const [deaths, setDeaths] = useState(() =>
    parseInt(localStorage.getItem('hermes_deaths') ?? '0', 10)
  );

  const [feedback, setFeedback] = useState('');
  const [bounce, setBounce] = useState(false);
  const [isDead, setIsDead] = useState(false);
  const [nameInput, setNameInput] = useState('');
  const [showChat, setShowChat] = useState(false);
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([
    { id: '1', text: 'Hey! How are you? 🐾', sender: 'pet' },
  ]);
  const [chatInput, setChatInput] = useState('');
  const chatEndRef = useRef<HTMLDivElement>(null);

  // Sync state
  const [syncStatus] = useState(getSyncStatus());
  const [isSyncing, setIsSyncing] = useState(false);

  // Persist to localStorage
  useEffect(() => { localStorage.setItem('hermes', JSON.stringify(pet)); }, [pet]);
  useEffect(() => { localStorage.setItem('hermes_history', JSON.stringify(history)); }, [history]);
  useEffect(() => { localStorage.setItem('hermes_deaths', String(deaths)); }, [deaths]);
  useEffect(() => { localStorage.setItem('hermes_hatched', String(isHatched)); }, [isHatched]);

  // Sync TO Hermes whenever pet state changes
  useEffect(() => {
    if (isDead || !isHatched) return;
    const timeout = setTimeout(() => {
      setIsSyncing(true);
      syncToHermes(pet, history, deaths)
        .catch(err => console.error('[App] Sync failed:', err))
        .finally(() => setIsSyncing(false));
    }, 500);
    return () => clearTimeout(timeout);
  }, [pet.hunger, pet.happiness, pet.energy, pet.health, pet.xp, pet.mood, pet.name, isDead, isHatched]);

  // Poll FROM Hermes every 5s
  useEffect(() => {
    if (isDead || !isHatched) return;
    const interval = setInterval(() => {
      syncFromHermes()
        .then(({ pet: remotePet, source }) => {
          if (remotePet && source !== 'none') {
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
          }
        })
        .catch(err => console.error('[App] Sync from Hermes failed:', err));
    }, 5000);
    return () => clearInterval(interval);
  }, [isDead, isHatched]);

  // Stat decay — every 30s
  useEffect(() => {
    if (isDead || !isHatched) return;
    const interval = setInterval(() => {
      setPet(prev => {
        const next = {
          ...prev,
          hunger:    clamp(prev.hunger - 1),
          happiness: clamp(prev.happiness - 0.5),
        };
        next.mood = deriveMood(next);
        return next;
      });
    }, 30_000);
    return () => clearInterval(interval);
  }, [isDead, isHatched]);

  // Check for death
  useEffect(() => {
    if (!isDead && pet.health <= 0) {
      setIsDead(true);
      setDeaths(d => d + 1);
    }
  }, [pet.health, isDead]);

  // Auto-scroll chat
  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [chatMessages]);

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
    setPet({ ...INITIAL, name: pet.name, id: crypto.randomUUID(), lastUpdated: Date.now() });
    setIsDead(false);
    setHistory([]);
  };

  const hatchPet = () => {
    const name = nameInput.trim() || 'Hermes';
    setPet({ ...INITIAL, name, id: crypto.randomUUID(), lastUpdated: Date.now() });
    setIsHatched(true);
    setIsDead(false);
    setHistory([]);
  };

  const startNewPet = () => {
    setIsHatched(false);
    setIsDead(false);
    setNameInput('');
  };

  const wakeUp = () => {
    setPet(prev => {
      const newEnergy = clamp(prev.energy + 30);
      return {
        ...prev,
        energy: newEnergy,
        mood: deriveMood({ ...prev, energy: newEnergy }),
        lastUpdated: Date.now(),
      };
    });
  };

  const sendChat = () => {
    if (!chatInput.trim()) return;
    const userMsg: ChatMessage = { id: crypto.randomUUID(), text: chatInput.trim(), sender: 'user' };
    setChatMessages(prev => [...prev, userMsg]);
    setChatInput('');
    setTimeout(() => {
      const replies = [
        "Let's play! 🎉",
        `I'm feeling ${pet.mood}! 😊`,
        'More treats please! 🍎',
        'Zzz... just kidding! 😄',
        "You're the best! 💕",
        'Can we go for a walk? 🐾',
      ];
      const reply = replies[Math.floor(Math.random() * replies.length)];
      setChatMessages(prev => [...prev, { id: crypto.randomUUID(), text: reply, sender: 'pet' }]);
    }, 800 + Math.random() * 700);
  };

  // ── Determine current view ──
  const isCritical = !isDead && (pet.hunger < 20 || pet.health < 20);
  const level = getLevel(pet.xp);

  let currentView: ViewState = 'main';
  if (!isHatched) currentView = 'hatch';
  else if (isDead) currentView = 'dead';
  else if (showChat) currentView = 'chat';
  else if (pet.mood === 'sleeping') currentView = 'sleeping';
  else if (isCritical) currentView = 'lowStats';

  // ── Hatch Screen ──
  if (currentView === 'hatch') {
    return (
      <div className="app">
        <div className="device">
          <div className="screen hatch-screen">
            <h2 className="hatch-title">Hatch Your Pet</h2>
            <div className="hatch-egg">🥚</div>
            <input
              className="hatch-input"
              placeholder="Pet name..."
              value={nameInput}
              onChange={e => setNameInput(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && hatchPet()}
              maxLength={14}
            />
            <button className="hatch-btn" onClick={hatchPet}>Hatch!</button>
          </div>
        </div>
      </div>
    );
  }

  // ── Dead Screen ──
  if (currentView === 'dead') {
    return (
      <div className="app">
        <div className="device">
          <div className="screen dead-screen">
            <div className="dead-header">
              <span className="dead-name">{pet.name}</span>
              <div className="rip-badge">
                <span className="rip-dot" />
                <span className="rip-text">RIP</span>
              </div>
            </div>
            <div className="dead-char-area">
              <div className="dead-glow" />
              <span className="dead-emoji">💀</span>
            </div>
            <span className="dead-go-text">Game Over</span>
            <span className="dead-sub-text">{pet.name} has passed away...</span>
            <div className="dead-actions">
              <button className="revive-btn" onClick={revive}>
                <span className="revive-icon">↺</span>
                Revive
              </button>
              <button className="new-pet-btn" onClick={startNewPet}>
                <span className="new-pet-icon">🥚</span>
                New Pet
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // ── Sleeping Screen ──
  if (currentView === 'sleeping') {
    return (
      <div className="app">
        <div className="device">
          <div className="screen sleeping-screen">
            <span className="sleeping-name">{pet.name}</span>
            <div className="sleeping-center">
              <span className="sleeping-zzz">z &nbsp;z &nbsp;z</span>
              <span className="sleeping-emoji">😴</span>
              <span className="sleeping-label">Sleeping...</span>
            </div>
            <button className="wake-btn" onClick={wakeUp}>Wake Up</button>
          </div>
        </div>
      </div>
    );
  }

  // ── Low Stats Screen ──
  if (currentView === 'lowStats') {
    return (
      <div className="app">
        <div className="device">
          <div className="screen low-stats-screen">
            <div className="low-header">
              <span className="low-name">{pet.name}</span>
              <div className="sos-badge">SOS</div>
            </div>
            <div className="low-glow-circle">
              <span className="low-emoji">😢</span>
            </div>
            <span className="low-warn-text">Needs attention!</span>
            <div className="low-dots">
              {STAT_DOTS.map(({ key, color }) => (
                <span
                  key={key}
                  className="stat-dot"
                  style={{
                    backgroundColor: (pet[key as keyof PetState] as number) < 30 ? '#FF453A' : color,
                    opacity: Math.max(0.3, (pet[key as keyof PetState] as number) / 100),
                  }}
                />
              ))}
            </div>
            <button className="feed-urgent-btn" onClick={() => perform(ACTIONS[0])}>Feed</button>
            <span className="care-text">Care</span>
          </div>
        </div>
      </div>
    );
  }

  // ── Chat Screen ──
  if (currentView === 'chat') {
    return (
      <div className="app">
        <div className="device">
          <div className="screen chat-screen">
            <div className="chat-header">
              <span className="chat-pet-emoji">🐣</span>
              <span className="chat-online-dot" />
              <span className="chat-title">Chat</span>
              <button className="chat-back-btn" onClick={() => setShowChat(false)}>✕</button>
            </div>
            <div className="chat-messages">
              {chatMessages.map(msg => (
                <div key={msg.id} className={`chat-msg ${msg.sender}`}>
                  <div className={`chat-bubble ${msg.sender}`}>{msg.text}</div>
                </div>
              ))}
              <div ref={chatEndRef} />
            </div>
            <div className="chat-input-bar">
              <input
                className="chat-input"
                placeholder="Message..."
                value={chatInput}
                onChange={e => setChatInput(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && sendChat()}
              />
              <button className="chat-send-btn" onClick={sendChat}>↑</button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // ── Main (Pet Companion) Screen ──
  return (
    <div className="app">
      <div className="device">
        <div className="screen main-screen">
          <div className="top-row">
            <span className="pet-name">{pet.name}</span>
            <div className="level-badge">LV{level}</div>
          </div>

          <div className={`pet-char ${bounce ? 'bounce' : ''}`}>
            <span className="pet-emoji">{getPetEmoji(pet.mood, false)}</span>
          </div>

          <span className="mood-text">{getMoodLabel(pet.mood)}</span>

          <div className="stats-dots">
            {STAT_DOTS.map(({ key, color }) => (
              <span
                key={key}
                className="stat-dot"
                style={{
                  backgroundColor: color,
                  opacity: Math.max(0.3, (pet[key as keyof PetState] as number) / 100),
                }}
              />
            ))}
          </div>

          <div className="action-row">
            {ACTIONS.map(a => (
              <button
                key={a.type}
                className="action-btn"
                onClick={() => perform(a)}
                disabled={isDead}
                style={{ backgroundColor: `${ACTION_COLORS[a.type]}20` }}
              >
                <span className="action-emoji">{a.emoji}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Chat toggle */}
        <button className="chat-toggle" onClick={() => setShowChat(true)}>💬</button>

        {/* Feedback toast */}
        <div className={`feedback ${feedback ? 'show' : ''}`}>{feedback}</div>
      </div>

      {/* Sync indicator */}
      {syncStatus.connected && (
        <div className={`sync-indicator ${isSyncing ? 'syncing' : ''}`}>
          {syncStatus.source === 'file' ? '🔗' : '💾'}
        </div>
      )}
    </div>
  );
}
