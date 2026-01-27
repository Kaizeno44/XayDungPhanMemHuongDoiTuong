"use client";
import { useState, useEffect } from "react";
import axios from "axios";
import Cookies from "js-cookie";
import { message, Switch } from "antd";

export default function AdminSettingsPage() {
  const [isMaintenance, setIsMaintenance] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStatus = async () => {
      try {
        const token = Cookies.get("accessToken");
        const res = await axios.get("http://localhost:5000/api/admin/maintenance", {
          headers: { Authorization: `Bearer ${token}` }
        });
        setIsMaintenance(res.data.isMaintenance);
      } catch (err) {
        console.error("Lỗi tải trạng thái bảo trì:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchStatus();
  }, []);

  const handleToggle = async (checked) => {
    try {
      const token = Cookies.get("accessToken");
      await axios.post("http://localhost:5000/api/admin/maintenance", checked, {
        headers: { 
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json"
        }
      });
      setIsMaintenance(checked);
      message.success(checked ? "Đã bật chế độ bảo trì hệ thống!" : "Đã tắt chế độ bảo trì hệ thống!");
    } catch (err) {
      message.error("Lỗi cập nhật trạng thái bảo trì");
    }
  };

  return (
    <div className="p-8 max-w-2xl">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">⚙️ Cấu hình Hệ thống</h1>
      <div className="bg-white p-6 rounded-xl shadow-sm border space-y-6">
        <div>
            <label className="block text-sm font-medium mb-1 text-gray-500">Tên Hệ Thống</label>
            <input type="text" value="BizFlow Platform" disabled className="w-full p-3 border rounded-lg bg-gray-50 text-gray-700 font-medium" />
        </div>
        
        <div className="flex items-center justify-between p-4 bg-orange-50 rounded-lg border border-orange-100">
            <div>
                <span className="font-bold text-gray-800 block">Chế độ bảo trì toàn hệ thống</span>
                <span className="text-xs text-gray-500">Khi bật, chỉ SuperAdmin mới có thể truy cập các tính năng.</span>
            </div>
            <Switch 
                checked={isMaintenance} 
                onChange={handleToggle} 
                loading={loading}
                className={isMaintenance ? 'bg-red-500' : ''}
            />
        </div>

        <div className="p-4 bg-blue-50 rounded-lg border border-blue-100">
            <span className="font-bold text-gray-800 block mb-2">Thông tin phiên bản</span>
            <div className="flex justify-between text-sm">
                <span className="text-gray-600">Phiên bản hiện tại:</span>
                <span className="font-mono font-bold text-blue-600">v1.2.0-stable</span>
            </div>
        </div>
      </div>
    </div>
  );
}
