"use client";
import { useEffect, useState } from "react";
import { Table, Button, Card, Space, Typography, Tag, message, Input, Modal, Form, InputNumber, Select } from "antd";
import { PlusOutlined, EditOutlined, DeleteOutlined, ReloadOutlined } from "@ant-design/icons";
import axios from "axios";
import Cookies from "js-cookie";

const { Title } = Typography;

export default function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [form] = Form.useForm();

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    setLoading(true);
    try {
      const token = Cookies.get("accessToken");
      const response = await axios.get("http://localhost:5000/api/products", {
        headers: { Authorization: `Bearer ${token}` }
      });
      // API trả về { data: [...], totalItems: ... }
      setProducts(response.data.data || response.data);
    } catch (err) {
      console.error(err);
      message.error("Không thể tải danh sách sản phẩm.");
    } finally {
      setLoading(false);
    }
  };

  const handleAddProduct = async (values) => {
    try {
      const token = Cookies.get("accessToken");
      await axios.post("http://localhost:5000/api/products", values, {
        headers: { Authorization: `Bearer ${token}` }
      });
      message.success("Thêm sản phẩm thành công!");
      setIsModalVisible(false);
      form.resetFields();
      fetchProducts();
    } catch (err) {
      message.error("Lỗi khi thêm sản phẩm.");
    }
  };

  const columns = [
    { title: "Mã SP", dataIndex: "sku", key: "sku" },
    { title: "Tên sản phẩm", dataIndex: "name", key: "name", render: (text) => <strong>{text}</strong> },
    { title: "Danh mục", dataIndex: "categoryName", key: "categoryName" },
    { 
      title: "Giá bán", 
      dataIndex: "price", 
      key: "price",
      render: (price) => <span className="text-red-600 font-bold">{price?.toLocaleString("vi-VN")} đ</span>
    },
    { 
      title: "Tồn kho", 
      dataIndex: "inventoryQuantity", 
      key: "inventoryQuantity",
      render: (qty, record) => (
        <Tag color={qty < 10 ? "volcano" : "green"}>
          {qty} {record.unitName || 'Cái'}
        </Tag>
      )
    },
    {
      title: "Thao tác",
      key: "action",
      render: (_, record) => (
        <Space size="middle">
          <Button icon={<EditOutlined />} />
          <Button danger icon={<DeleteOutlined />} />
        </Space>
      ),
    },
  ];

  return (
    <div className="p-6">
      <Card>
        <div className="flex justify-between items-center mb-6">
          <Title level={2} style={{ margin: 0 }}>Quản lý Sản phẩm</Title>
          <Space>
            <Button icon={<ReloadOutlined />} onClick={fetchProducts}>Làm mới</Button>
            <Button type="primary" icon={<PlusOutlined />} onClick={() => setIsModalVisible(true)}>
              Thêm sản phẩm
            </Button>
          </Space>
        </div>

        <Table 
          columns={columns} 
          dataSource={products} 
          rowKey="id" 
          loading={loading}
        />
      </Card>

      <Modal
        title="Thêm sản phẩm mới"
        open={isModalVisible}
        onCancel={() => setIsModalVisible(false)}
        onOk={() => form.submit()}
      >
        <Form form={form} layout="vertical" onFinish={handleAddProduct}>
          <Form.Item name="name" label="Tên sản phẩm" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="sku" label="Mã SKU" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="price" label="Giá bán" rules={[{ required: true }]}>
            <InputNumber className="w-full" formatter={value => `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')} />
          </Form.Item>
          <Form.Item name="categoryId" label="Danh mục" rules={[{ required: true }]}>
            <Select>
              <Select.Option value={1}>Vật liệu xây dựng</Select.Option>
              <Select.Option value={2}>Điện nước</Select.Option>
            </Select>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
