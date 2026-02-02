"use client";

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';

const NotificationContext = createContext();

export const NotificationProvider = ({ children }) => {
  const [notifications, setNotifications] = useState([]);
  const [savedNotifications, setSavedNotifications] = useState([]);
  const [showNotificationHistory, setShowNotificationHistory] = useState(false);

  useEffect(() => {
    // Load saved notifications from localStorage on initial load
    const storedNotifications = localStorage.getItem('savedNotifications');
    if (storedNotifications) {
      setSavedNotifications(JSON.parse(storedNotifications));
    }
  }, []);

  const addNotification = useCallback((message, type = 'info', duration = 10000) => {
    const newNotification = {
      id: Date.now(),
      message,
      type,
      read: false,
      timestamp: new Date().toISOString(),
    };
    setNotifications((prev) => [...prev, newNotification]);

    // Auto-save after a short delay (e.g., 1 second)
    setTimeout(() => {
      setSavedNotifications((prevSaved) => {
        const updatedSaved = [...prevSaved, { ...newNotification, savedAt: new Date().toISOString() }];
        localStorage.setItem('savedNotifications', JSON.stringify(updatedSaved));
        return updatedSaved;
      });
    }, 1000); // Save after 1 second

    // Auto-remove from active notifications after duration
    setTimeout(() => {
      setNotifications((prev) => prev.filter((n) => n.id !== newNotification.id));
    }, duration);
  }, [setSavedNotifications]);

  const markAsRead = useCallback((id) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, read: true } : n))
    );
  }, []);

  const markAllAsRead = useCallback(() => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
  }, []);

  const saveNotification = useCallback((notificationToSave) => {
    setSavedNotifications((prev) => {
      const updatedSaved = [...prev, { ...notificationToSave, savedAt: new Date().toISOString() }];
      localStorage.setItem('savedNotifications', JSON.stringify(updatedSaved));
      return updatedSaved;
    });
    // Optionally remove from active notifications after saving
    setNotifications((prev) => prev.filter((n) => n.id !== notificationToSave.id));
  }, []);

  const removeSavedNotification = useCallback((id) => {
    setSavedNotifications((prev) => {
      const updatedSaved = prev.filter((n) => n.id !== id);
      localStorage.setItem('savedNotifications', JSON.stringify(updatedSaved));
      return updatedSaved;
    });
  }, []);

  const toggleNotificationHistory = useCallback(() => {
    setShowNotificationHistory((prev) => !prev);
  }, []);

  const value = {
    notifications,
    addNotification,
    markAsRead,
    markAllAsRead,
    savedNotifications,
    saveNotification,
    removeSavedNotification,
    showNotificationHistory,
    toggleNotificationHistory,
  };

  return (
    <NotificationContext.Provider value={value}>
      {children}
    </NotificationContext.Provider>
  );
};

export const useNotification = () => {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotification must be used within a NotificationProvider');
  }
  return context;
};
