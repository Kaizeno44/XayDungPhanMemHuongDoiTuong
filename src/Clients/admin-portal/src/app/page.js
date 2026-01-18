"use client";
import { useState } from "react";
import api from "@/utils/api";
import Cookies from "js-cookie";
import { useRouter } from "next/navigation";

// --- THÊM: Import các Component của Shadcn UI ---
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Loader2 } from "lucide-react" // Icon xoay xoay đẹp hơn

export default function LoginPage() {
  const [email, setEmail] = useState("admin@bizflow.com");
  const [password, setPassword] = useState("123456"); // Mật khẩu mặc định
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Gọi API Login của Identity Service
      const res = await api.post("/auth/login", { email, password });
      
      // Lưu token
      Cookies.set("accessToken", res.data.token);
      
      alert("Đăng nhập thành công!");
      // Chuyển hướng sang trang danh sách sản phẩm (Bạn hãy tạo folder app/dashboard sau)
      router.push("/dashboard"); 
    } catch (err) {
      console.error(err);
      alert("Đăng nhập thất bại! Kiểm tra lại API Identity.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex h-screen items-center justify-center bg-gray-100">
      <form onSubmit={handleLogin} className="bg-white p-8 rounded shadow-md w-96">
        <h1 className="text-2xl font-bold mb-6 text-center text-blue-600">BizFlow Admin</h1>
        
        <div className="mb-4">
          <label className="block text-gray-700 text-sm font-bold mb-2">Email</label>
          <input 
            type="email" 
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full border p-2 rounded text-black"
          />
        </div>

        <div className="mb-6">
          <label className="block text-gray-700 text-sm font-bold mb-2">Password</label>
          <input 
            type="password" 
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full border p-2 rounded text-black"
          />
        </div>

        <button 
          disabled={loading}
          className="w-full bg-blue-500 text-white font-bold py-2 px-4 rounded hover:bg-blue-700"
        >
          {loading ? "Đang xử lý..." : "Đăng Nhập"}
        </button>
      </form>
    </div>
  );
}