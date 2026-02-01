"use client";

import React from 'react';
import { useRouter } from 'next/navigation';
import { useNotification } from '@/components/NotificationProvider';
import { X, BellOff, ArrowLeft } from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';

const NotificationsPage = () => {
  const router = useRouter();
  const { savedNotifications, removeSavedNotification, markAllAsRead } = useNotification();

  return (
    <div className="container mx-auto p-6">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div className="flex items-center gap-4">
            <Button variant="ghost" size="icon" onClick={() => router.back()} title="Quay lại">
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <CardTitle className="text-2xl font-bold">Lịch sử thông báo</CardTitle>
          </div>
          {savedNotifications.length > 0 && (
            <Button 
              variant="outline" 
              onClick={markAllAsRead} // Assuming markAllAsRead also clears saved notifications or marks them as read in history
              className="flex items-center gap-2"
            >
              <BellOff className="w-4 h-4" /> Xóa tất cả
            </Button>
          )}
        </CardHeader>
        <CardContent>
          {savedNotifications.length === 0 ? (
            <p className="text-gray-500">Không có thông báo nào được lưu.</p>
          ) : (
            <div className="space-y-4">
              {savedNotifications.map((notification) => (
                <div
                  key={notification.id}
                  className={`relative p-4 rounded-lg shadow-sm border flex items-start space-x-3
                    ${notification.type === 'info' ? 'bg-blue-50 border-blue-200 text-blue-800' : ''}
                    ${notification.type === 'success' ? 'bg-green-50 border-green-200 text-green-800' : ''}
                    ${notification.type === 'warning' ? 'bg-yellow-50 border-yellow-200 text-yellow-800' : ''}
                    ${notification.type === 'error' ? 'bg-red-50 border-red-200 text-red-800' : ''}
                  `}
                >
                  <div className="flex-1">
                    <p className="font-semibold">{notification.message}</p>
                    <p className="text-xs opacity-80 mt-1">
                      Lưu lúc: {new Date(notification.savedAt).toLocaleString()}
                    </p>
                  </div>
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={() => removeSavedNotification(notification.id)}
                    className="text-gray-500 hover:text-gray-700"
                    title="Xóa thông báo đã lưu"
                  >
                    <X className="w-4 h-4" />
                  </Button>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default NotificationsPage;
