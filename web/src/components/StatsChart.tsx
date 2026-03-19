import { useState, useEffect } from 'react';
import type { PetState, HistoryEntry } from '../types';

interface WeeklyStats {
  day: string;
  avgHunger: number;
  avgHappiness: number;
  avgHealth: number;
  interactions: number;
}

interface StatsChartProps {
  pet: PetState;
  history: HistoryEntry[];
}

export function StatsChart({ pet, history }: StatsChartProps) {
  const [weeklyData, setWeeklyData] = useState<WeeklyStats[]>([]);
  const [selectedMetric, setSelectedMetric] = useState<'all' | 'hunger' | 'happiness' | 'health'>('all');

  useEffect(() => {
    // Generate last 7 days of stats
    const days: WeeklyStats[] = [];
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dayKey = date.toISOString().split('T')[0];
      
      // Count interactions for this day
      const dayInteractions = history.filter(h => {
        const hDate = new Date(h.time).toISOString().split('T')[0];
        return hDate === dayKey;
      }).length;
      
      // Get stored daily averages or estimate
      const stored = localStorage.getItem(`clawbert_daily_${dayKey}`);
      let avgHunger = 50, avgHappiness = 50, avgHealth = 50;
      
      if (stored) {
        const data = JSON.parse(stored);
        avgHunger = data.hunger;
        avgHappiness = data.happiness;
        avgHealth = data.health;
      } else if (i === 0) {
        // Today - use current stats
        avgHunger = pet.hunger;
        avgHappiness = pet.happiness;
        avgHealth = pet.health;
      } else {
        // Estimate based on streak and general care
        const careQuality = pet.perfectDayStreak > 0 ? 0.7 : 0.5;
        avgHunger = Math.round(40 + Math.random() * 40 * careQuality);
        avgHappiness = Math.round(40 + Math.random() * 40 * careQuality);
        avgHealth = Math.round(50 + Math.random() * 40 * careQuality);
      }
      
      days.push({
        day: dayNames[date.getDay()],
        avgHunger,
        avgHappiness,
        avgHealth,
        interactions: dayInteractions,
      });
    }
    
    setWeeklyData(days);
    
    // Store today's stats for future reference
    const today = new Date().toISOString().split('T')[0];
    localStorage.setItem(`clawbert_daily_${today}`, JSON.stringify({
      hunger: pet.hunger,
      happiness: pet.happiness,
      health: pet.health,
      timestamp: Date.now(),
    }));
  }, [pet, history]);

  const getBarHeight = (value: number) => `${value}%`;
  const getBarColor = (value: number) => {
    if (value >= 80) return '#66bb6a';
    if (value >= 50) return '#ff9800';
    return '#ef5350';
  };

  return (
    <div className="stats-chart-panel">
      <div className="chart-header">
        <span className="chart-title">📊 Weekly Overview</span>
        <div className="chart-legend">
          {selectedMetric === 'all' ? (
            <>
              <span className="legend-item hunger">🍖 Hunger</span>
              <span className="legend-item happiness">😊 Happy</span>
              <span className="legend-item health">❤️ Health</span>
            </>
          ) : (
            <span className="legend-item active">
              {selectedMetric === 'hunger' && '🍖 Hunger'}
              {selectedMetric === 'happiness' && '😊 Happiness'}
              {selectedMetric === 'health' && '❤️ Health'}
            </span>
          )}
        </div>
      </div>
      
      <div className="chart-container">
        {weeklyData.map((day, idx) => (
          <div key={idx} className="chart-day">
            <div className="chart-bars">
              {selectedMetric === 'all' || selectedMetric === 'hunger' ? (
                <div
                  className="chart-bar hunger-bar"
                  style={{ 
                    height: getBarHeight(day.avgHunger),
                    background: getBarColor(day.avgHunger),
                    opacity: selectedMetric === 'all' ? 1 : undefined,
                  }}
                  title={`Hunger: ${Math.round(day.avgHunger)}`}
                />
              ) : null}
              {selectedMetric === 'all' || selectedMetric === 'happiness' ? (
                <div
                  className="chart-bar happiness-bar"
                  style={{ 
                    height: getBarHeight(day.avgHappiness),
                    background: getBarColor(day.avgHappiness),
                    opacity: selectedMetric === 'all' ? 1 : undefined,
                  }}
                  title={`Happiness: ${Math.round(day.avgHappiness)}`}
                />
              ) : null}
              {selectedMetric === 'all' || selectedMetric === 'health' ? (
                <div
                  className="chart-bar health-bar"
                  style={{ 
                    height: getBarHeight(day.avgHealth),
                    background: getBarColor(day.avgHealth),
                    opacity: selectedMetric === 'all' ? 1 : undefined,
                  }}
                  title={`Health: ${Math.round(day.avgHealth)}`}
                />
              ) : null}
            </div>
            <div className="chart-day-label">
              {day.day}
              {day.interactions > 0 && (
                <span className="interaction-dot" title={`${day.interactions} interactions`}>
                  ●
                </span>
              )}
            </div>          
          </div>
        ))}
      </div>
      
      <div className="chart-metrics">
        {(['all', 'hunger', 'happiness', 'health'] as const).map((metric) => (
          <button
            key={metric}
            className={`metric-btn ${selectedMetric === metric ? 'active' : ''}`}
            onClick={() => setSelectedMetric(metric)}
          >
            {metric === 'all' && 'All'}
            {metric === 'hunger' && '🍖'}
            {metric === 'happiness' && '😊'}
            {metric === 'health' && '❤️'}
          </button>
        ))}
      </div>
    </div>
  );
}
