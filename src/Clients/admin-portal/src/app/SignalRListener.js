"use client"; // 👈 DÒNG NÀY BẮT BUỘC Ở DÒNG ĐẦU TIÊN

import { useEffect } from "react";
import { HubConnectionBuilder, LogLevel } from "@microsoft/signalr";

export default function SignalRListener() {
  useEffect(() => {
    // 1. Cấu hình kết nối (Thay cổng 5103 bằng cổng API thật của bạn)
    const connection = new HubConnectionBuilder()
      .withUrl("http://localhost:5103/hubs/notifications") 
      .withAutomaticReconnect()
      .configureLogging(LogLevel.Information)
      .build();

    // 2. Bắt đầu kết nối
    connection.start()
      .then(() => {
        console.log("✅ [SignalR] Connected!");
        connection.invoke("JoinAdminGroup");
      })
      .catch((err) => console.error("❌ [SignalR] Error:", err));

    // 3. Lắng nghe sự kiện
    connection.on("ReceiveOrderNotification", (data) => {
      console.log("🔔 TING TING:", data);
      alert(`🔔 TING TING! Đơn mới từ: ${data.message} - 💰 ${data.totalAmount}`);
    });

    // Cleanup khi component bị hủy
    return () => {
      connection.stop();
    };
  }, []);

  // Component này không cần hiển thị gì cả (nó chạy ngầm)
  return null; 
}