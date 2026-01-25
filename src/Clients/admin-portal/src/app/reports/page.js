"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Cookies from "js-cookie";
import { Table, Button, Card, Space, Typography, Tag, message } from "antd";
import { FilePdfOutlined, ArrowLeftOutlined } from "@ant-design/icons";
import axios from "axios";
import { saveAs } from "file-saver";
import { numberToVietnameseWords } from "@/utils/numberToWords";

const { Title, Text } = Typography;

export default function ReportsPage() {
  const router = useRouter();
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = Cookies.get("accessToken");
    if (!token) {
      router.push("/login");
      return;
    }
    fetchCashBook(token);
  }, [router]);

  const fetchCashBook = async (token) => {
    try {
      const response = await axios.get("http://localhost:5000/api/Accounting/cash-book", {
        headers: { Authorization: `Bearer ${token}` }
      });
      setLogs(response.data);
    } catch (err) {
      console.error(err);
      message.error("Không thể tải dữ liệu sổ quỹ.");
    } finally {
      setLoading(false);
    }
  };

  const handleExportPdf = async (record) => {
    try {
      message.loading({ content: "Đang tạo PDF...", key: "export" });
      const token = Cookies.get("accessToken");
      const amount = Math.abs(record.amount);
      
      const pdfData = {
        businessName: "BIZFLOW SYSTEM",
        businessAddress: "123 Tech Street, Digital City",
        receiptDate: new Date().toISOString(),
        bookNumber: "BK-2026",
        receiptNumber: record.id.toString().substring(0, 8).toUpperCase(),
        payerName: record.customerName || "Khách lẻ",
        payerAddress: "Địa chỉ khách hàng",
        reasonForPayment: record.reason || "Thanh toán đơn hàng",
        amount: amount,
        amountInWords: numberToVietnameseWords(amount),
        attachedDocuments: "Hóa đơn kèm theo",
        originalDocuments: "Chứng từ gốc"
      };

      const response = await axios.post(
        "http://localhost:5000/api/Pdf/generate-phieuthu",
        pdfData,
        { 
          responseType: "blob",
          headers: { Authorization: `Bearer ${token}` }
        }
      );

      saveAs(response.data, `PhieuThu_${pdfData.receiptNumber}.pdf`);
      message.success({ content: "Xuất PDF thành công!", key: "export" });
    } catch (err) {
      console.error(err);
      message.error({ content: "Lỗi khi xuất PDF.", key: "export" });
    }
  };

  const columns = [
    {
      title: "Ngày tạo",
      dataIndex: "createdAt",
      key: "createdAt",
      render: (text) => new Date(text).toLocaleString("vi-VN"),
    },
    {
      title: "Khách hàng",
      dataIndex: "customerName",
      key: "customerName",
    },
    {
      title: "Lý do",
      dataIndex: "reason",
      key: "reason",
    },
    {
      title: "Loại",
      dataIndex: "action",
      key: "action",
      render: (action) => (
        <Tag color={action === "Ghi nợ" ? "red" : "green"}>
          {action}
        </Tag>
      ),
    },
    {
      title: "Số tiền",
      dataIndex: "amount",
      key: "amount",
      render: (amount, record) => (
        <Text strong style={{ color: record.action === "Thu tiền" ? "#52c41a" : "#f5222d" }}>
          {amount.toLocaleString("vi-VN")} đ
        </Text>
      ),
    },
    {
      title: "Thao tác",
      key: "action",
      render: (_, record) => (
        <Button 
          type="primary" 
          icon={<FilePdfOutlined />} 
          onClick={() => handleExportPdf(record)}
        >
          Xuất PDF
        </Button>
      ),
    },
  ];

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-7xl mx-auto">
        <Space direction="vertical" size="large" style={{ width: "100%" }}>
          <div className="flex items-center gap-4">
            <Button icon={<ArrowLeftOutlined />} onClick={() => router.push("/merchant/dashboard")} />
            <Title level={2} style={{ margin: 0 }}>Sổ Quỹ & Báo Cáo</Title>
          </div>
          <Card title="Lịch sử giao dịch (Sổ quỹ)">
            <Table 
              columns={columns} 
              dataSource={logs} 
              rowKey="id" 
              loading={loading}
              pagination={{ pageSize: 10 }}
            />
          </Card>
        </Space>
      </div>
    </div>
  );
}
