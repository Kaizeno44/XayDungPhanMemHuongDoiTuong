"use client";
import { useState, useEffect } from "react";
import axios from "axios";
import Cookies from "js-cookie";
import { CheckCircle, Clock, MessageSquare, User, Store } from "lucide-react";
import { format } from "date-fns";
import { vi } from "date-fns/locale";

export default function AdminFeedbackPage() {
  const [feedbacks, setFeedbacks] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchFeedbacks = async () => {
    try {
      const token = Cookies.get("accessToken");
      const res = await axios.get("http://localhost:5000/api/feedback", {
        headers: { Authorization: `Bearer ${token}` }
      });
      setFeedbacks(res.data);
    } catch (err) {
      console.error("Lỗi tải phản hồi:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFeedbacks();
  }, []);

  const handleResolve = async (id) => {
    try {
      const token = Cookies.get("accessToken");
      await axios.put(`http://localhost:5000/api/feedback/${id}/resolve`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      });
      fetchFeedbacks();
      alert("Đã đánh dấu xử lý thành công!");
    } catch (err) {
      alert("Lỗi khi cập nhật trạng thái");
    }
  };

  return (
    <div className="p-8 bg-white rounded-xl shadow-sm m-6 min-h-[80vh]">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-2xl font-bold text-gray-800 flex items-center gap-3">
          <MessageSquare className="text-blue-600" size={28} />
          Ý kiến & Phản hồi
        </h1>
        <div className="text-sm text-gray-500 bg-gray-100 px-4 py-2 rounded-full">
          Tổng số: <strong>{feedbacks.length}</strong> phản hồi
        </div>
      </div>

      {loading ? (
        <div className="flex justify-center items-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
      ) : feedbacks.length === 0 ? (
        <div className="text-center py-20 bg-gray-50 rounded-xl border-2 border-dashed">
          <MessageSquare size={48} className="mx-auto text-gray-300 mb-4" />
          <p className="text-gray-500">Chưa có phản hồi nào từ người dùng.</p>
        </div>
      ) : (
        <div className="grid gap-6">
          {feedbacks.map((fb) => (
            <div 
              key={fb.id} 
              className={`p-6 rounded-xl border transition-all ${
                fb.isResolved ? "bg-gray-50 border-gray-200" : "bg-white border-blue-100 shadow-md"
              }`}
            >
              <div className="flex justify-between items-start mb-4">
                <div>
                  <h3 className="text-lg font-bold text-gray-800 mb-1">{fb.title}</h3>
                  <div className="flex flex-wrap gap-4 text-sm text-gray-500">
                    <span className="flex items-center gap-1">
                      <User size={14} /> {fb.userName} ({fb.userEmail})
                    </span>
                    <span className="flex items-center gap-1">
                      <Store size={14} /> {fb.storeName}
                    </span>
                    <span className="flex items-center gap-1">
                      <Clock size={14} /> {format(new Date(fb.createdAt), "HH:mm, dd/MM/yyyy", { locale: vi })}
                    </span>
                  </div>
                </div>
                {fb.isResolved ? (
                  <span className="flex items-center gap-1 text-green-600 bg-green-50 px-3 py-1 rounded-full text-xs font-bold">
                    <CheckCircle size={14} /> Đã xử lý
                  </span>
                ) : (
                  <button 
                    onClick={() => handleResolve(fb.id)}
                    className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition shadow-sm"
                  >
                    Đánh dấu đã xử lý
                  </button>
                )}
              </div>
              <div className="bg-white p-4 rounded-lg border border-gray-100 text-gray-700 whitespace-pre-wrap">
                {fb.content}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
