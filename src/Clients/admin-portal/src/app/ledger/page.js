"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Cookies from "js-cookie";
import Link from "next/link";
import { saveAs } from 'file-saver';

const accountingData = [
  { id: 1, date: '2025-12-01', description: 'Initial Capital', type: 'Credit', amount: 100000000, balance: 100000000 },
  { id: 2, date: '2025-12-02', description: 'Sales Revenue', type: 'Credit', amount: 5000000, balance: 105000000 },
  { id: 3, date: '2025-12-03', description: 'Office Supplies', type: 'Debit', amount: 1000000, balance: 104000000 },
  { id: 4, date: '2025-12-04', description: 'Sales Revenue', type: 'Credit', amount: 7000000, balance: 111000000 },
  { id: 5, date: '2025-12-05', description: 'Rent Payment', type: 'Debit', amount: 15000000, balance: 96000000 },
];

export default function LedgerPage() {
  const router = useRouter();
  const [user, setUser] = useState(null);
  const [ledgerEntries, setLedgerEntries] = useState(accountingData); // Using mock data for now

  useEffect(() => {
    // Temporarily bypass authentication for demonstration
    setUser({ name: "Admin (Person A)" });
    // const token = Cookies.get("accessToken");
    // if (!token) {
    //   router.push("/");
    // } else {
    //     setUser({ name: "Admin (Person A)" }); 
    //     // In a real application, you would fetch data here:
    //     // fetchAccountingData();
    // }
  }, []); // Removed router from dependency array as it's not used in the bypassed logic

  // Placeholder for fetching real accounting data
  const fetchAccountingData = async () => {
    try {
      // TODO: Replace with actual Accounting API endpoint
      const response = await fetch("/api/accounting-data"); 
      const data = await response.json();
      setLedgerEntries(data);
    } catch (error) {
      console.error("Error fetching accounting data:", error);
    }
  };

  const handleLogout = () => {
    Cookies.remove("accessToken");
    router.push("/");
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
              {ledgerEntries.map((entry) => (
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
              ))}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}
