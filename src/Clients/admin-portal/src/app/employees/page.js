"use client";
import { useState, useEffect } from "react";
import Link from "next/link";
import api from "@/utils/api";

export default function EmployeesPage() {
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(true);

  // Hàm tải dữ liệu
  const fetchEmployees = async () => {
    try {
      const res = await api.get("/users"); // Gọi vào API vừa viết
      setEmployees(res.data);
    } catch (err) {
      console.error("Lỗi tải nhân viên:", err);
      // alert("Không tải được danh sách nhân viên!");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEmployees();
  }, []);

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">Danh sách Nhân viên</h1>
          <p className="text-gray-500 text-sm">Dữ liệu thực từ PostgreSQL</p>
        </div>
        <Link href="/employees/create">
          <button className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded shadow flex items-center gap-2">
            <span>+</span> Thêm Nhân viên
          </button>
        </Link>
      </div>

      <div className="bg-white rounded shadow overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead className="bg-gray-100 border-b">
            <tr>
              <th className="p-4 text-sm font-semibold text-gray-600">Họ và Tên</th>
              <th className="p-4 text-sm font-semibold text-gray-600">Email</th>
              <th className="p-4 text-sm font-semibold text-gray-600">Vai trò</th>
              <th className="p-4 text-sm font-semibold text-gray-600 text-right">Hành động</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan="4" className="p-4 text-center">Đang tải dữ liệu...</td></tr>
            ) : employees.length === 0 ? (
              <tr><td colSpan="4" className="p-4 text-center text-gray-500">Chưa có nhân viên nào.</td></tr>
            ) : (
              employees.map((emp) => (
                <tr key={emp.id} className="border-b hover:bg-gray-50 transition">
                  <td className="p-4 font-medium text-gray-800">{emp.fullName}</td>
                  <td className="p-4 text-gray-600">{emp.email}</td>
                  <td className="p-4">
                    <span className={`px-2 py-1 rounded text-xs font-semibold ${
                      emp.role === 'Admin' ? 'bg-purple-100 text-purple-700' : 'bg-blue-100 text-blue-700'
                    }`}>
                      {emp.role}
                    </span>
                  </td>
                  <td className="p-4 text-right space-x-2">
                    <button className="text-red-600 hover:text-red-800 text-sm font-medium">Xóa</button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}