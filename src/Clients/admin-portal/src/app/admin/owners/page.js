"use client";
import { useState, useEffect } from "react";
import axios from "axios";
import Cookies from "js-cookie";
import Link from "next/link";
// 👇 1. Nhớ import thêm icon Trash2 (Thùng rác)
import { Search, Lock, Unlock, Plus, Trash2 } from "lucide-react";

export default function OwnerManagementPage() {
  const [owners, setOwners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");

  const fetchOwners = async () => {
    try {
      const token = Cookies.get("accessToken");
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

  const toggleStatus = async (id, currentStatus) => {
    if(!confirm("Bạn có chắc muốn thay đổi trạng thái tài khoản này?")) return;
    
    // 1. Tính toán trạng thái mới (Nếu đang Active thì thành Locked và ngược lại)
    const newStatus = currentStatus === 'Active' ? 'Locked' : 'Active';

    try {
        const token = Cookies.get("accessToken");
        
        // 2. Gọi API báo cho Server biết
        await axios.put(`http://localhost:5000/api/admin/users/${id}/status`, {}, {
            headers: { Authorization: `Bearer ${token}` }
        });

        // 3. QUAN TRỌNG: Tự cập nhật lại danh sách trên màn hình (Không cần gọi fetchOwners)
        setOwners(prevOwners => prevOwners.map(owner => 
            owner.id === id ? { ...owner, status: newStatus } : owner
        ));

        // (Tùy chọn) Bỏ alert đi cho đỡ phải bấm OK, trải nghiệm mượt hơn
        // alert("Cập nhật thành công!"); 

    } catch (error) {
        // Nếu API lỗi thì mới hiện thông báo và load lại dữ liệu cũ
        alert("Lỗi cập nhật trạng thái");
        fetchOwners(); 
    }
  };

  // 👇 2. Hàm xử lý Xóa
  const handleDelete = async (id) => {
    if(!confirm("⚠️ CẢNH BÁO: Hành động này không thể hoàn tác!\nBạn có chắc chắn muốn XÓA VĨNH VIỄN chủ hộ này không?")) return;
    
    try {
        const token = Cookies.get("accessToken");
        // Gọi API xóa bên Backend
        await axios.delete(`http://localhost:5000/api/admin/users/${id}`, {
            headers: { Authorization: `Bearer ${token}` }
        });
        
        alert("Đã xóa thành công!");
        fetchOwners(); // Load lại danh sách sau khi xóa
    } catch (error) {
        console.error(error);
        alert("Lỗi khi xóa: " + (error.response?.data?.message || error.message));
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
            <th className="p-4">Gói dịch vụ</th>
            <th className="p-4 text-center">Trạng thái</th>
            <th className="p-4 text-center rounded-tr-lg">Hành động</th>
          </tr>
        </thead>
        <tbody>
          {loading ? (
             <tr><td colSpan="6" className="p-8 text-center text-gray-500">Đang tải dữ liệu...</td></tr>
          ) : filteredOwners.length === 0 ? (
             <tr><td colSpan="6" className="p-8 text-center text-gray-500">Chưa có dữ liệu</td></tr>
          ) : (
            filteredOwners.map((owner) => (
              <tr key={owner.id} className="border-b hover:bg-gray-50 transition">
                <td className="p-4 font-medium">{owner.fullName}</td>
                <td className="p-4 text-gray-500">{owner.email}</td>
                <td className="p-4 text-blue-600 font-semibold">{owner.storeName}</td>
                
                <td className="p-4">
                    <span className="bg-purple-100 text-purple-700 px-3 py-1 rounded-full text-xs font-bold">
                        {owner.planName || "Chưa đăng ký"}
                    </span>
                </td>

                <td className="p-4 text-center">
                  <span className={`px-3 py-1 rounded-full text-xs font-bold ${
                    owner.status === 'Active' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                  }`}>
                    {owner.status === 'Active' ? 'Hoạt động' : 'Đã khóa'}
                  </span>
                </td>

                {/* 👇 3. Cột Hành động (Gồm nút Khóa và Xóa) */}
                <td className="p-4 text-center">
                  <div className="flex justify-center gap-2"> 
                      <button 
                        onClick={() => toggleStatus(owner.id, owner.status)}
                        className={`p-2 rounded-full hover:bg-gray-200 transition ${owner.status === 'Active' ? 'text-orange-500' : 'text-green-500'}`}
                        title={owner.status === 'Active' ? "Khóa tài khoản" : "Mở khóa"}
                      >
                        {owner.status === 'Active' ? <Lock size={18} /> : <Unlock size={18} />}
                      </button>

                      {/* Nút Xóa Mới */}
                      <button 
                        onClick={() => handleDelete(owner.id)}
                        className="p-2 rounded-full hover:bg-red-100 text-red-500 transition"
                        title="Xóa vĩnh viễn"
                      >
                        <Trash2 size={18} />
                      </button>
                  </div>
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}