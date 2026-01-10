"use client";
import { useEffect, useState } from "react";
import { Table, Card, Typography, Tag, message, Button, Space } from "antd";
import { ReloadOutlined, EyeOutlined } from "@ant-design/icons";
import axios from "axios";
import Cookies from "js-cookie";

const { Title } = Typography;

export default function OrdersPage() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchOrders();
  }, []);

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const token = Cookies.get("accessToken");
      const response = await axios.get("http://localhost:5000/api/orders", {
        headers: { Authorization: `Bearer ${token}` }
      });
      setOrders(response.data);
    } catch (err) {
      console.error(err);
      message.error("Không thể tải danh sách đơn hàng.");
    } finally {
      setLoading(false);
    }
  };

  const columns = [
    { 
      title: "Mã đơn hàng", 
      dataIndex: "orderCode", 
      key: "orderCode",
      render: (text) => <strong>{text}</strong>
    },
    { 
      title: "Ngày tạo", 
      dataIndex: "orderDate", 
      key: "orderDate",
      render: (date) => new Date(date).toLocaleString("vi-VN")
    },
    { 
      title: "Tổng tiền", 
      dataIndex: "totalAmount", 
      key: "totalAmount",
      render: (amount) => <span className="text-blue-600 font-bold">{amount?.toLocaleString("vi-VN")} đ</span>
    },
    { 
      title: "Thanh toán", 
      dataIndex: "paymentMethod", 
      key: "paymentMethod",
      render: (method) => (
        <Tag color={method === "Debt" ? "red" : "green"}>
          {method === "Debt" ? "Ghi nợ" : "Tiền mặt"}
        </Tag>
      )
    },
    { 
      title: "Trạng thái", 
      dataIndex: "status", 
      key: "status",
      render: (status) => (
        <Tag color="blue">{status}</Tag>
      )
    },
    {
      title: "Thao tác",
      key: "action",
      render: (_, record) => (
        <Button icon={<EyeOutlined />}>Chi tiết</Button>
      ),
    },
  ];

  return (
    <div className="p-6">
      <Card>
        <div className="flex justify-between items-center mb-6">
          <Title level={2} style={{ margin: 0 }}>Lịch sử Đơn hàng</Title>
          <Button icon={<ReloadOutlined />} onClick={fetchOrders}>Làm mới</Button>
        </div>

        <Table 
          columns={columns} 
          dataSource={orders} 
          rowKey="id" 
          loading={loading}
        />
      </Card>
    </div>
  );
}
