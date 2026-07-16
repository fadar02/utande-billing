import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { settingsAPI } from '../services/api';

interface SettingsContextType {
  currency: string;
  currencySymbol: string;
  formatMoney: (amount: number | string) => string;
  reload: () => void;
}

const SettingsContext = createContext<SettingsContextType | undefined>(undefined);

const SYMBOL_MAP: Record<string, string> = {
  MWK: 'MWK',
};

export const SettingsProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [currency, setCurrency] = useState('USD');
  const [currencySymbol, setCurrencySymbol] = useState('$');
  const [loaded, setLoaded] = useState(false);

  const load = async () => {
    try {
      const token = localStorage.getItem('token');
      if (!token) return;
      const res = await settingsAPI.getAll();
      const map: Record<string, string> = {};
      res.data.forEach((s: any) => { map[s.key] = s.value; });
      const cur = map.currency || 'USD';
      setCurrency(cur);
      setCurrencySymbol(SYMBOL_MAP[cur] || cur);
      setLoaded(true);
    } catch {
      // Not logged in or error — use defaults
    }
  };

  useEffect(() => {
    load();
    const interval = setInterval(() => {
      if (!loaded) load();
    }, 1000);
    return () => clearInterval(interval);
  }, [loaded]);

  const formatMoney = (amount: number | string): string => {
    const num = typeof amount === 'string' ? parseFloat(amount) : amount;
    if (isNaN(num)) return `${currencySymbol}0.00`;
    return `${currencySymbol}${num.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  };

  return (
    <SettingsContext.Provider value={{ currency, currencySymbol, formatMoney, reload: load }}>
      {children}
    </SettingsContext.Provider>
  );
};

export const useSettings = () => {
  const context = useContext(SettingsContext);
  if (!context) throw new Error('useSettings must be used within SettingsProvider');
  return context;
};
