import { useState, useEffect } from 'react';
import type { PetState } from '../types';

interface Achievement {
  id: string;
  name: string;
  description: string;
  emoji: string;
  xpReward: number;
}

const ACHIEVEMENTS: Achievement[] = [
  { id: 'first_feed', name: 'First Meal', description: 'Fed Clawbert for the first time', emoji: '🍖', xpReward: 10 },
  { id: 'first_play', name: 'Playtime', description: 'Played with Clawbert for the first time', emoji: '🎾', xpReward: 10 },
  { id: 'xp_100', name: 'First Steps', description: 'Reached 100 XP', emoji: '💡', xpReward: 25 },
  { id: 'xp_500', name: 'Growing Up', description: 'Reached 500 XP', emoji: '🌱', xpReward: 50 },
  { id: 'xp_1000', name: 'Veteran Caretaker', description: 'Reached 1,000 XP', emoji: '⭐', xpReward: 100 },
  { id: 'perfect_care', name: 'Perfect Care', description: 'All stats above 80', emoji: '✨', xpReward: 50 },
  { id: 'survivor', name: 'Survivor', description: 'Recovered from critical health', emoji: '🏥', xpReward: 30 },
  { id: 'streak_3', name: 'Getting Serious', description: '3-day care streak', emoji: '🔥', xpReward: 25 },
  { id: 'streak_7', name: 'Streak Master', description: '7-day care streak', emoji: '🔥', xpReward: 75 },
  { id: 'streak_30', name: 'Dedicated', description: '30-day care streak', emoji: '👑', xpReward: 250 },
  { id: 'pet_50', name: 'Best Friends', description: 'Petted Clawbert 50 times', emoji: '🤚', xpReward: 50 },
  { id: 'feed_100', name: 'Chef', description: 'Fed Clawbert 100 times', emoji: '👨‍🍳', xpReward: 75 },
  { id: 'night_owl', name: 'Night Owl', description: 'Interacted after midnight', emoji: '🌙', xpReward: 15 },
  { id: 'early_bird', name: 'Early Bird', description: 'Interacted before 6am', emoji: '🌅', xpReward: 15 },
  { id: 'immortal', name: 'Immortal', description: 'Never let Clawbert die for a week', emoji: '💎', xpReward: 200 },
];

interface AchievementsPanelProps {
  pet: PetState;
  deaths: number;
}

export function AchievementsPanel({ pet, deaths }: AchievementsPanelProps) {
  const [unlockedIds, setUnlockedIds] = useState<string[]>([]);
  const [showUnlockedOnly, setShowUnlockedOnly] = useState(false);
  const [newUnlock, setNewUnlock] = useState<string | null>(null);

  useEffect(() => {
    // Load unlocked achievements from localStorage
    const saved = localStorage.getItem('clawbert_achievements');
    if (saved) {
      setUnlockedIds(JSON.parse(saved));
    }
  }, []);

  useEffect(() => {
    // Check for new achievements
    const newlyUnlocked: string[] = [];
    
    if (pet.xp >= 100 && !unlockedIds.includes('xp_100')) newlyUnlocked.push('xp_100');
    if (pet.xp >= 500 && !unlockedIds.includes('xp_500')) newlyUnlocked.push('xp_500');
    if (pet.xp >= 1000 && !unlockedIds.includes('xp_1000')) newlyUnlocked.push('xp_1000');
    if (pet.hunger > 80 && pet.happiness > 80 && pet.health > 80 && !unlockedIds.includes('perfect_care')) {
      newlyUnlocked.push('perfect_care');
    }
    if (pet.perfectDayStreak >= 3 && !unlockedIds.includes('streak_3')) newlyUnlocked.push('streak_3');
    if (pet.perfectDayStreak >= 7 && !unlockedIds.includes('streak_7')) newlyUnlocked.push('streak_7');
    if (pet.perfectDayStreak >= 30 && !unlockedIds.includes('streak_30')) newlyUnlocked.push('streak_30');
    
    if (newlyUnlocked.length > 0) {
      const updated = [...unlockedIds, ...newlyUnlocked];
      setUnlockedIds(updated);
      localStorage.setItem('clawbert_achievements', JSON.stringify(updated));
      setNewUnlock(newlyUnlocked[0]);
      
      // Clear notification after 3 seconds
      setTimeout(() => setNewUnlock(null), 3000);
    }
  }, [pet, unlockedIds]);

  const unlockedCount = unlockedIds.length;
  const totalCount = ACHIEVEMENTS.length;
  const progressPercent = Math.round((unlockedCount / totalCount) * 100);

  const filteredAchievements = showUnlockedOnly
    ? ACHIEVEMENTS.filter(a => unlockedIds.includes(a.id))
    : ACHIEVEMENTS;

  return (
    <div className="achievements-panel">
      {newUnlock && (
        <div className="achievement-toast">
          🏆 Achievement Unlocked!
        </div>
      )}
      
      <div className="achievements-header">
        <div className="achievements-progress">
          <span className="achievements-title">🏆 Achievements</span>
          <span className="achievements-count">{unlockedCount}/{totalCount}</span>
        </div>        
        <div className="progress-bar">
          <div 
            className="progress-fill" 
            style={{ width: `${progressPercent}%` }}
          />
        </div>
        
        <button 
          className="filter-btn"
          onClick={() => setShowUnlockedOnly(!showUnlockedOnly)}
        >
          {showUnlockedOnly ? 'Show All' : 'Show Unlocked'}
        </button>
      </div>

      <div className="achievements-grid">
        {filteredAchievements.map((achievement) => {
          const isUnlocked = unlockedIds.includes(achievement.id);
          
          return (
            <div 
              key={achievement.id}
              className={`achievement-card ${isUnlocked ? 'unlocked' : 'locked'} ${newUnlock === achievement.id ? 'new' : ''}`}
            >
              <div className="achievement-emoji">{achievement.emoji}</div>
              <div className="achievement-info">
                <div className="achievement-name">{achievement.name}</div>
                <div className="achievement-desc">{achievement.description}</div>
                {isUnlocked && (
                  <div className="achievement-reward">+{achievement.xpReward} XP</div>
                )}
              </div>              
              <div className="achievement-status">
                {isUnlocked ? '✓' : '🔒'}
              </div>
            </div>
          );
        })}
      </div>

      <div className="lifetime-stats">
        <div className="stat-item">
          <span className="stat-icon">☠️</span>
          <span className="stat-label">Deaths</span>
          <span className="stat-value">{deaths}</span>
        </div>        
        <div className="stat-item">
          <span className="stat-icon">🔥</span>
          <span className="stat-label">Best Streak</span>
          <span className="stat-value">{pet.perfectDayStreak} days</span>
        </div>        
        <div className="stat-item">
          <span className="stat-icon">💡</span>
          <span className="stat-label">Total XP</span>
          <span className="stat-value">{Math.round(pet.xp)}</span>
        </div>
      </div>
    </div>  );
}
