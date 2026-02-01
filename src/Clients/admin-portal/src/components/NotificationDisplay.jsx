"use client";

import React from 'react';
import { useNotification } from './NotificationProvider';
import { X, Save } from 'lucide-react';

const NotificationDisplay = () => {
  const { notifications, markAsRead, saveNotification, removeSavedNotification, savedNotifications, showNotificationHistory, toggleNotificationHistory } = useNotification();

  const notificationsToDisplay = showNotificationHistory ? savedNotifications : notifications;

  if (!showNotificationHistory && notifications.length === 0) {
    return null;
  }

  return (
    <div className="fixed bottom-4 right-4 z-50 flex flex-col space-y-2">
      {notificationsToDisplay.map((notification) => (
        <div
          key={notification.id}
          className={`relative p-4 rounded-lg shadow-md text-white max-w-sm w-full flex items-start space-x-3
            ${notification.type === 'info' ? 'bg-blue-500' : ''}
            ${notification.type === 'success' ? 'bg-green-500' : ''}
            ${notification.type === 'warning' ? 'bg-yellow-500' : ''}
            ${notification.type === 'error' ? 'bg-red-500' : ''}
            ${notification.read && !showNotificationHistory ? 'opacity-70' : ''}
          `}
        >
          <div className="flex-1">
            <p className="font-semibold">{notification.message}</p>
            <p className="text-xs opacity-80 mt-1">
              {new Date(notification.timestamp).toLocaleTimeString()}
            </p>
          </div>
          <div className="flex space-x-2">
            {!showNotificationHistory && (
              <button
                onClick={() => saveNotification(notification)}
                className="p-1 rounded-full hover:bg-white hover:bg-opacity-20 transition-colors"
                title="Save Notification"
              >
                <Save className="w-4 h-4" />
              </button>
            )}
            <button
              onClick={() => {
                if (showNotificationHistory) {
                  removeSavedNotification(notification.id);
                } else {
                  markAsRead(notification.id);
                }
              }}
              className="p-1 rounded-full hover:bg-white hover:bg-opacity-20 transition-colors"
              title={showNotificationHistory ? "Remove Saved" : "Mark as Read"}
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      ))}
    </div>
  );
};

export default NotificationDisplay;
