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
  const [currency, setCurrency] = useState('MWK');
  const [currencySymbol, setCurrencySymbol] = useState('MWK');

  const load = async () => {
    try {
      const token = localStorage.getItem('token');
      if (!token) return;
      const res = await settingsAPI.getAll();
      const map: Record<string, string> = {};
      res.data.forEach((s: any) => { map[s.key] = s.value; });
      const cur = map.currency || 'MWK';
      setCurrency(cur);
      setCurrencySymbol(SYMBOL_MAP[cur] || cur);
    } catch {
      // Not logged in or error — use defaults
    }
  };

  useEffect(() => {
    load();
  }, []);

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
