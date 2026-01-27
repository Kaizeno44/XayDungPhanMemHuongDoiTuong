"use client";
import { useState } from "react";
import axios from "axios";
import Cookies from "js-cookie";
import { Send, MessageSquare, AlertCircle } from "lucide-react";

export default function MerchantFeedbackPage() {
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!title || !content) {
      alert("Vui lòng điền đầy đủ thông tin!");
      return;
    }

    setLoading(true);
    try {
      const token = Cookies.get("accessToken");
      await axios.post("http://localhost:5000/api/feedback", {
        title,
        content
      }, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      setSuccess(true);
      setTitle("");
      setContent("");
      setTimeout(() => setSuccess(false), 5000);
    } catch (err) {
      alert("Lỗi khi gửi phản hồi: " + (err.response?.data?.message || err.message));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-8 max-w-3xl mx-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-800 flex items-center gap-3">
          <MessageSquare className="text-blue-600" size={28} />
          Gửi Phản hồi & Khiếu nại
        </h1>
        <p className="text-gray-500 mt-2">
          Ý kiến của bạn giúp chúng tôi hoàn thiện hệ thống tốt hơn. Mọi khiếu nại sẽ được Admin xử lý trong vòng 24h.
        </p>
      </div>

      {success && (
        <div className="mb-6 p-4 bg-green-50 border border-green-200 text-green-700 rounded-lg flex items-center gap-3 animate-pulse">
          <AlertCircle size={20} />
          Gửi phản hồi thành công! Cảm ơn bạn đã đóng góp ý kiến.
        </div>
      )}

      <form onSubmit={handleSubmit} className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100 space-y-6">
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-2">Tiêu đề</label>
          <input 
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Ví dụ: Lỗi hiển thị đơn hàng, Góp ý tính năng mới..."
            className="w-full p-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none transition-all"
            required
          />
        </div>

        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-2">Nội dung chi tiết</label>
          <textarea 
            value={content}
            onChange={(e) => setContent(e.target.value)}
            placeholder="Mô tả chi tiết vấn đề hoặc ý kiến của bạn tại đây..."
            rows={8}
            className="w-full p-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none transition-all resize-none"
            required
          />
        </div>

        <div className="pt-4">
          <button 
            type="submit"
            disabled={loading}
            className={`w-full py-4 rounded-xl font-bold text-white flex items-center justify-center gap-2 transition-all ${
              loading ? "bg-gray-400 cursor-not-allowed" : "bg-blue-600 hover:bg-blue-700 shadow-lg shadow-blue-100"
            }`}
          >
            {loading ? (
              <div className="h-5 w-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
            ) : (
              <>
                <Send size={20} />
                Gửi phản hồi ngay
              </>
            )}
          </button>
        </div>
      </form>

      <div className="mt-12 grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="p-6 bg-blue-50 rounded-2xl border border-blue-100">
          <h4 className="font-bold text-blue-800 mb-2">Hỗ trợ kỹ thuật</h4>
          <p className="text-sm text-blue-600">Hotline: 1900 1234 (8:00 - 22:00)</p>
        </div>
        <div className="p-6 bg-purple-50 rounded-2xl border border-purple-100">
          <h4 className="font-bold text-purple-800 mb-2">Email góp ý</h4>
          <p className="text-sm text-purple-600">support@bizflow.com</p>
        </div>
      </div>
    </div>
  );
}
