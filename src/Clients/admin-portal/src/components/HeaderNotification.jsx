"use client";

import React from 'react';
import Link from 'next/link';
import { Bell } from 'lucide-react';
import { useNotification } from './NotificationProvider';

const HeaderNotification = () => {
  const { notifications } = useNotification();
  const unreadNotificationsCount = notifications.filter(n => !n.read).length;

  return (
    <Link href="/notifications" className="relative p-2 rounded-full hover:bg-gray-100 transition-colors">
      <Bell className="w-6 h-6 text-gray-600" />
      {unreadNotificationsCount > 0 && (
        <span className="absolute top-1 right-1 flex items-center justify-center h-5 w-5 rounded-full bg-red-500 text-white text-xs font-bold">
          {unreadNotificationsCount}
        </span>
      )}
    </Link>
  );
};

export default HeaderNotification;
