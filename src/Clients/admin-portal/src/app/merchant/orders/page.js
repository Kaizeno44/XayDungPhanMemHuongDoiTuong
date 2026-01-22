"use client";
import { useEffect, useState } from "react";
import { Table, Card, Typography, Tag, message, Button, Space, Modal, Descriptions, Divider } from "antd";
import { ReloadOutlined, EyeOutlined } from "@ant-design/icons";
import axios from "axios";
import Cookies from "js-cookie";

const { Title, Text } = Typography;

export default function OrdersPage() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [detailLoading, setDetailLoading] = useState(false);

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

  const fetchOrderDetail = async (id) => {
    setDetailLoading(true);
    try {
      const token = Cookies.get("accessToken");
      const response = await axios.get(`http://localhost:5000/api/orders/${id}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setSelectedOrder(response.data);
      setIsModalVisible(true);
    } catch (err) {
      console.error("Lỗi tải chi tiết:", err);
      message.error("Không thể tải chi tiết đơn hàng. Vui lòng đảm bảo BizFlow.OrderAPI đã được khởi động lại với code mới.");
    } finally {
      setDetailLoading(false);
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
        <Button 
          icon={<EyeOutlined />} 
          onClick={() => fetchOrderDetail(record.id)}
          loading={detailLoading && selectedOrder?.id === record.id}
        >
          Chi tiết
        </Button>
      ),
    },
  ];

  const itemColumns = [
    { 
      title: "Sản phẩm", 
      dataIndex: "productId", 
      key: "productId",
      render: (id, record) => (
        <Space direction="vertical" size={0}>
          <Text strong>ID: {id}</Text>
          <Text type="secondary" size="small">Đơn vị: {record.unitName}</Text>
        </Space>
      )
    },
    { 
      title: "Số lượng", 
      dataIndex: "quantity", 
      key: "quantity",
      align: "right"
    },
    { 
      title: "Đơn giá", 
      dataIndex: "unitPrice", 
      key: "unitPrice",
      align: "right",
      render: (val) => `${val?.toLocaleString("vi-VN")} đ`
    },
    { 
      title: "Thành tiền", 
      dataIndex: "total", 
      key: "total",
      align: "right",
      render: (val) => <Text strong>{val?.toLocaleString("vi-VN")} đ</Text>
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

      <Modal
        title={`Chi tiết đơn hàng: ${selectedOrder?.orderCode}`}
        open={isModalVisible}
        onCancel={() => setIsModalVisible(false)}
        footer={[
          <Button key="close" onClick={() => setIsModalVisible(false)}>Đóng</Button>
        ]}
        width={800}
      >
        {selectedOrder && (
          <>
            <Descriptions bordered column={2}>
              <Descriptions.Item label="Mã đơn">{selectedOrder.orderCode}</Descriptions.Item>
              <Descriptions.Item label="Ngày tạo">{new Date(selectedOrder.orderDate).toLocaleString("vi-VN")}</Descriptions.Item>
              <Descriptions.Item label="Thanh toán">
                <Tag color={selectedOrder.paymentMethod === "Debt" ? "red" : "green"}>
                  {selectedOrder.paymentMethod === "Debt" ? "Ghi nợ" : "Tiền mặt"}
                </Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Trạng thái">
                <Tag color="blue">{selectedOrder.status}</Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Tổng cộng" span={2}>
                <Text type="danger" strong style={{ fontSize: 18 }}>
                  {selectedOrder.totalAmount?.toLocaleString("vi-VN")} đ
                </Text>
              </Descriptions.Item>
            </Descriptions>

            <Divider orientation="left">Danh sách sản phẩm</Divider>
            
            <Table
              dataSource={selectedOrder.orderItems}
              columns={itemColumns}
              pagination={false}
              rowKey="id"
              size="small"
            />
          </>
        )}
      </Modal>
    </div>
  );
}
