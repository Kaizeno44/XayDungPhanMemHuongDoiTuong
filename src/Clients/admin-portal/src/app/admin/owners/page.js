"use client";
import { useState, useEffect } from "react";
import axios from "axios";
import Cookies from "js-cookie";
import Link from "next/link";
import { Search, Lock, Unlock, Plus } from "lucide-react";

export default function OwnerManagementPage() {
  const [owners, setOwners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");

  // 1. Load dữ liệu từ API
  const fetchOwners = async () => {
    try {
      const token = Cookies.get("accessToken");
      // Gọi đúng API AdminController bạn vừa thêm
      const res = await axios.get("http://localhost:5000/api/admin/users?role=Owner", {
        headers: { Authorization: `Bearer ${token}` }
      });
      setOwners(res.data);
    } catch (err) {
      console.error("Lỗi tải danh sách:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOwners();
  }, []);

  // 2. Xử lý Khóa/Mở khóa
  const toggleStatus = async (id, currentStatus) => {
    if(!confirm("Bạn có chắc muốn thay đổi trạng thái tài khoản này?")) return;
    try {
        const token = Cookies.get("accessToken");
        // Gọi API PUT Status mới
        await axios.put(`http://localhost:5000/api/admin/users/${id}/status`, {}, {
            headers: { Authorization: `Bearer ${token}` }
        });
        // Load lại danh sách cho chuẩn
        fetchOwners();
        alert("Cập nhật thành công!");
    } catch (error) {
        alert("Lỗi cập nhật trạng thái");
    }
  };

  const filteredOwners = owners.filter(u => 
    u.fullName?.toLowerCase().includes(searchTerm.toLowerCase()) || 
    u.email?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="p-8 bg-white rounded-xl shadow-sm m-6 min-h-[80vh]">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-800">🏢 Quản lý Chủ hộ</h1>
        <div className="flex gap-3">
            <div className="relative">
                <Search className="absolute left-3 top-3 text-gray-400" size={18} />
                <input 
                    className="pl-10 pr-4 py-2 border rounded-lg w-64 focus:ring-2 focus:ring-blue-500 outline-none"
                    placeholder="Tìm tên hoặc email..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                />
            </div>
            <Link href="/admin/owners/create" className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center font-medium transition">
                <Plus size={18} className="mr-2"/> Thêm mới
            </Link>
        </div>
      </div>

      <table className="w-full text-left border-collapse">
        <thead className="bg-gray-100 text-gray-600 uppercase text-sm font-semibold">
          <tr>
            <th className="p-4 rounded-tl-lg">Họ tên</th>
            <th className="p-4">Email</th>
            <th className="p-4">Cửa hàng</th>
            <th className="p-4 text-center">Trạng thái</th>
            <th className="p-4 text-center rounded-tr-lg">Hành động</th>
          </tr>
        </thead>
        <tbody>
          {loading ? (
             <tr><td colSpan="5" className="p-8 text-center text-gray-500">Đang tải dữ liệu...</td></tr>
          ) : filteredOwners.length === 0 ? (
             <tr><td colSpan="5" className="p-8 text-center text-gray-500">Chưa có dữ liệu</td></tr>
          ) : (
            filteredOwners.map((owner) => (
              <tr key={owner.id} className="border-b hover:bg-gray-50 transition">
                <td className="p-4 font-medium">{owner.fullName}</td>
                <td className="p-4 text-gray-500">{owner.email}</td>
                <td className="p-4 text-blue-600 font-semibold">{owner.storeName}</td>
                <td className="p-4 text-center">
                  <span className={`px-3 py-1 rounded-full text-xs font-bold ${
                    owner.status === 'Active' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                  }`}>
                    {owner.status === 'Active' ? 'Hoạt động' : 'Đã khóa'}
                  </span>
                </td>
                <td className="p-4 text-center">
                  <button 
                    onClick={() => toggleStatus(owner.id, owner.status)}
                    className={`p-2 rounded-full hover:bg-gray-200 transition ${owner.status === 'Active' ? 'text-red-500' : 'text-green-500'}`}
                    title="Đổi trạng thái"
                  >
                    {owner.status === 'Active' ? <Lock size={18} /> : <Unlock size={18} />}
                  </button>
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}