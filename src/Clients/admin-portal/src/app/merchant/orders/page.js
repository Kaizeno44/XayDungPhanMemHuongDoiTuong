"use client";
import { useEffect, useState } from "react";
import { Table, Card, Typography, Tag, message, Button, Space, Modal, Descriptions, Divider } from "antd";
import { ReloadOutlined, EyeOutlined } from "@ant-design/icons";
import axios from "axios";
import Cookies from "js-cookie";
import { jwtDecode } from "jwt-decode";

const { Title, Text } = Typography;

export default function OrdersPage() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [detailLoading, setDetailLoading] = useState(false);
  const [confirmLoading, setConfirmLoading] = useState(null);

  useEffect(() => {
    fetchOrders();
  }, []);

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const token = Cookies.get("accessToken");
      let storeId = "";
      try {
        const decoded = jwtDecode(token);
        storeId = decoded.StoreId || decoded.storeId || "";
      } catch (e) {}

      const response = await axios.get(`http://localhost:5000/api/orders${storeId ? `?storeId=${storeId}` : ''}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      // Lọc bỏ các đơn hàng tĩnh ORD001, ORD002, ORD003 ở phía Frontend
      const filteredOrders = response.data.filter(o => {
        const code = o.orderCode || o.OrderCode || "";
        return !["ORD001", "ORD002", "ORD003"].includes(code);
      });
      
      setOrders(filteredOrders);
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
      
      const orderData = response.data;
      const items = orderData.orderItems || orderData.OrderItems || [];

      // Lấy tên sản phẩm động từ ProductAPI (Vì API gốc không trả về tên)
      const itemsWithNames = await Promise.all(items.map(async (item) => {
        try {
          const pRes = await axios.get(`http://localhost:5000/api/products/${item.productId || item.ProductId}`, {
            headers: { Authorization: `Bearer ${token}` }
          });
          const product = pRes.data;
          const unit = product.productUnits?.find(u => u.id === (item.unitId || item.UnitId));
          return {
            ...item,
            productName: product.name,
            unitName: unit?.unitName || "N/A"
          };
        } catch (e) {
          return { ...item, productName: `Sản phẩm #${item.productId || item.ProductId}`, unitName: "N/A" };
        }
      }));

      setSelectedOrder({ ...orderData, orderItems: itemsWithNames });
      setIsModalVisible(true);
    } catch (err) {
      console.error("Lỗi tải chi tiết đơn hàng:", err);
      const errorMsg = err.response?.data?.message || err.response?.data || err.message;
      message.error(`Lỗi: ${errorMsg}. (ID: ${id})`);
    } finally {
      setDetailLoading(false);
    }
  };

  const handleConfirmOrder = async (id) => {
    setConfirmLoading(id);
    try {
      const token = Cookies.get("accessToken");
      await axios.put(`http://localhost:5000/api/orders/${id}/status?status=Confirmed`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      });
      message.success("Đã xác nhận đơn hàng!");
      fetchOrders();
    } catch (err) {
      console.error("Lỗi xác nhận đơn:", err);
      message.error("Không thể xác nhận đơn hàng.");
    } finally {
      setConfirmLoading(null);
    }
  };

  const columns = [
    { 
      title: "Mã đơn hàng", 
      dataIndex: "orderCode", 
      key: "orderCode",
      render: (text, record) => <strong>{text || record.OrderCode}</strong>
    },
    { 
      title: "Ngày tạo", 
      dataIndex: "orderDate", 
      key: "orderDate",
      render: (date, record) => new Date(date || record.OrderDate).toLocaleString("vi-VN")
    },
    { 
      title: "Tổng tiền", 
      dataIndex: "totalAmount", 
      key: "totalAmount",
      render: (amount, record) => <span className="text-blue-600 font-bold">{(amount || record.TotalAmount)?.toLocaleString("vi-VN")} đ</span>
    },
    { 
      title: "Thanh toán", 
      dataIndex: "paymentMethod", 
      key: "paymentMethod",
      render: (method, record) => {
        const val = method || record.PaymentMethod;
        return (
          <Tag color={val === "Debt" ? "red" : "green"}>
            {val === "Debt" ? "Ghi nợ" : "Tiền mặt"}
          </Tag>
        );
      }
    },
    { 
      title: "Trạng thái", 
      dataIndex: "status", 
      key: "status",
      render: (status, record) => {
        const val = status || record.Status;
        let color = "blue";
        let text = val;
        if (val === "Pending" || val === "Draft") {
          color = "orange";
          text = "Chờ xác nhận";
        } else if (val === "Confirmed") {
          color = "green";
          text = "Đã xác nhận";
        }
        return <Tag color={color}>{text}</Tag>;
      }
    },
    {
      title: "Thao tác",
      key: "action",
      render: (_, record) => {
        const orderId = record.id || record.Id || record.ID;
        const status = record.status || record.Status;
        return (
          <Space>
            <Button 
              icon={<EyeOutlined />} 
              onClick={() => fetchOrderDetail(orderId)}
              loading={detailLoading && (selectedOrder?.id === orderId || selectedOrder?.Id === orderId)}
            >
              Chi tiết
            </Button>
            {(status === "Pending" || status === "Draft") && (
              <Button 
                type="primary" 
                onClick={() => handleConfirmOrder(orderId)}
                loading={confirmLoading === orderId}
              >
                Xác nhận
              </Button>
            )}
          </Space>
        );
      },
    },
  ];

  const itemColumns = [
    { 
      title: "Sản phẩm", 
      dataIndex: "productName", 
      key: "productName",
      render: (name, record) => (
        <Space direction="vertical" size={0}>
          <Text strong>{name || record.ProductName || `Sản phẩm #${record.productId || record.ProductId}`}</Text>
          <Text type="secondary" size="small">Đơn vị: {record.unitName || record.UnitName}</Text>
        </Space>
      )
    },
    { 
      title: "Số lượng", 
      dataIndex: "quantity", 
      key: "quantity",
      align: "right",
      render: (val, record) => val || record.Quantity
    },
    { 
      title: "Đơn giá", 
      dataIndex: "unitPrice", 
      key: "unitPrice",
      align: "right",
      render: (val, record) => `${(val || record.UnitPrice)?.toLocaleString("vi-VN")} đ`
    },
    { 
      title: "Thành tiền", 
      dataIndex: "total", 
      key: "total",
      align: "right",
      render: (val, record) => <Text strong>{(val || record.Total)?.toLocaleString("vi-VN")} đ</Text>
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
          rowKey={(record) => record.id || record.Id} 
          loading={loading}
        />
      </Card>

      <Modal
        title={`Chi tiết đơn hàng: ${selectedOrder?.orderCode || selectedOrder?.OrderCode}`}
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
              <Descriptions.Item label="Mã đơn">{selectedOrder.orderCode || selectedOrder.OrderCode}</Descriptions.Item>
              <Descriptions.Item label="Ngày tạo">{new Date(selectedOrder.orderDate || selectedOrder.OrderDate).toLocaleString("vi-VN")}</Descriptions.Item>
              <Descriptions.Item label="Thanh toán">
                <Tag color={(selectedOrder.paymentMethod || selectedOrder.PaymentMethod) === "Debt" ? "red" : "green"}>
                  {(selectedOrder.paymentMethod || selectedOrder.PaymentMethod) === "Debt" ? "Ghi nợ" : "Tiền mặt"}
                </Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Trạng thái">
                <Tag color="blue">{selectedOrder.status || selectedOrder.Status}</Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Tổng cộng" span={2}>
                <Text type="danger" strong style={{ fontSize: 18 }}>
                  {(selectedOrder.totalAmount || selectedOrder.TotalAmount)?.toLocaleString("vi-VN")} đ
                </Text>
              </Descriptions.Item>
            </Descriptions>

            <Divider orientation="left">Danh sách sản phẩm</Divider>
            
            <Table
              dataSource={selectedOrder.orderItems || selectedOrder.OrderItems || []}
              columns={itemColumns}
              pagination={false}
              rowKey={(record) => record.id || record.Id || Math.random()}
              size="small"
            />
          </>
        )}
      </Modal>
    </div>
  );
}
