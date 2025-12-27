"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Cookies from "js-cookie";
import Link from "next/link";
import { saveAs } from 'file-saver';

export default function LedgerPage() {
  const router = useRouter();
  const [user, setUser] = useState(null);
  const [ledgerEntries, setLedgerEntries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const token = Cookies.get("accessToken");

    if (!token) {
      router.push("/login");
      return;
    }

    setUser({ name: "Admin (Person A)" }); // Assuming user is authenticated

    const fetchOrderData = async () => {
      try {
        // TODO: Replace with dynamic storeId if applicable
        const response = await fetch("http://localhost:5103/api/Orders", {
          method: "GET",
          headers: {
            "Authorization": `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        });

        if (!response.ok) {
          throw new Error("Không thể tải dữ liệu đơn hàng.");
        }

        const orders = await response.json();
        
        // Transform order data to ledger entry format (Sổ S1 - simplified)
        let balance = 0;
        const transformedEntries = orders.map((order, index) => {
          const revenue = order.totalAmount;
          // For Sổ S1, we might need to differentiate between revenue and deductions.
          // For now, we'll treat totalAmount as revenue (Credit).
          balance += revenue;

          return {
            id: order.id,
            date: new Date(order.orderDate).toLocaleDateString('vi-VN'),
            description: `Đơn hàng ${order.orderCode}`,
            type: 'Credit', // Assuming all orders are revenue for now
            amount: revenue,
            balance: balance,
            orderItems: order.orderItems // Keep order items for potential detailed view
          };
        });
        setLedgerEntries(transformedEntries);
      } catch (err) {
        console.error("Error fetching order data:", err);
        setError("Không thể tải dữ liệu đơn hàng từ Server.");
      } finally {
        setLoading(false);
      }
    };

    fetchOrderData();
  }, [router]);

  const handleLogout = () => {
    Cookies.remove("accessToken");
    router.push("/login"); // Ensure it redirects to /login
  };

  const handleExportPdf = async () => {
    try {
      const phieuThuData = {
        id: "PT20251227001",
        customerName: "Nguyễn Văn A",
        address: "123 Đường ABC, Quận 1, TP.HCM",
        phoneNumber: "0901234567",
        amount: 15000000,
        amountInWords: "Mười lăm triệu đồng chẵn",
        reason: "Thanh toán tiền hàng tháng 12/2025",
        creatorName: "Admin (Person A)",
        createdDate: "27/12/2025",
        details: [
          {
            description: "Tiền hàng tháng 12",
            quantity: 1,
            unitPrice: 15000000,
            total: 15000000,
          },
        ],
      };

      const response = await fetch("http://localhost:5103/api/Pdf/generate-phieuthu", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(phieuThuData),
      });

      if (response.ok) {
        const blob = await response.blob();
        saveAs(blob, `PhieuThu_${phieuThuData.id}.pdf`);
      } else {
        console.error("Failed to generate PDF:", response.statusText);
      }
    } catch (error) {
      console.error("Error exporting PDF:", error);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Navbar */}
      <header className="bg-white shadow p-4 flex justify-between items-center">
        <h1 className="text-xl font-bold text-blue-600">BizFlow Admin</h1>
        <div className="flex items-center gap-4">
            <span className="text-gray-600">Xin chào, {user?.name}</span>
            <button 
                onClick={handleLogout}
                className="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600 text-sm"
            >
                Đăng Xuất
            </button>
        </div>
      </header>

      {/* Content */}
      <main className="flex-1 p-8">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-2xl font-bold text-gray-800">Sổ Quỹ (Ledger)</h2>
          <button
            onClick={handleExportPdf}
            className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 text-sm"
          >
            Export PDF
          </button>
        </div>
        
        <div className="bg-white p-6 rounded shadow overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  ID
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Description
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Type
                </th>
                <th scope="col" className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Amount
                </th>
                <th scope="col" className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Balance
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {loading ? (
                <tr>
                  <td colSpan="6" className="px-6 py-4 text-center text-gray-500">
                    ⏳ Đang tải dữ liệu sổ quỹ...
                  </td>
                </tr>
              ) : error ? (
                <tr>
                  <td colSpan="6" className="px-6 py-4 text-center text-red-500 bg-red-50">
                    ⚠️ {error}
                  </td>
                </tr>
              ) : ledgerEntries.length === 0 ? (
                <tr>
                  <td colSpan="6" className="px-6 py-4 text-center text-gray-500">
                    Không có dữ liệu sổ quỹ nào.
                  </td>
                </tr>
              ) : (
                ledgerEntries.map((entry) => (
                  <tr key={entry.id}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {entry.id}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {entry.date}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {entry.description}
                    </td>
                    <td className={`px-6 py-4 whitespace-nowrap text-sm ${entry.type === 'Credit' ? 'text-green-600' : 'text-red-600'}`}>
                      {entry.type}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-right text-gray-500">
                      {entry.amount.toLocaleString('vi-VN')} VND
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-right text-gray-900">
                      {entry.balance.toLocaleString('vi-VN')} VND
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}
