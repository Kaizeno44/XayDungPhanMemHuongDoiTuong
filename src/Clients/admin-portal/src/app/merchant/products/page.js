"use client";
import { useEffect, useState } from "react";
import { Table, Button, Card, Space, Typography, Tag, message, Input, Modal, Form, InputNumber, Select } from "antd";
import { PlusOutlined, EditOutlined, DeleteOutlined, ReloadOutlined } from "@ant-design/icons";
import axios from "axios";
import Cookies from "js-cookie";

const { Title } = Typography;

export default function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [form] = Form.useForm();

  useEffect(() => {
    fetchProducts();
    fetchCategories();
  }, []);

  const fetchCategories = async () => {
    try {
      const token = Cookies.get("accessToken");
      const response = await axios.get("http://localhost:5000/api/categories", {
        headers: { Authorization: `Bearer ${token}` }
      });
      setCategories(response.data);
    } catch (err) {
      console.error("Lỗi tải danh mục:", err);
    }
  };

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
      // Map dữ liệu từ form sang DTO của Backend
      const payload = {
        name: values.name,
        sku: values.sku,
        categoryId: values.categoryId,
        baseUnitName: values.baseUnitName || "Cái",
        basePrice: values.price,
        initialStock: values.initialStock || 0,
        imageUrl: "",
        description: values.description || ""
      };

      await axios.post("http://localhost:5000/api/products", payload, {
        headers: { Authorization: `Bearer ${token}` }
      });
      message.success("Thêm sản phẩm thành công!");
      setIsModalVisible(false);
      form.resetFields();
      fetchProducts();
    } catch (err) {
      console.error(err);
      message.error("Lỗi khi thêm sản phẩm: " + (err.response?.data?.message || err.message));
    }
  };

  const columns = [
    { title: "Mã SP", dataIndex: "sku", key: "sku" },
    { title: "Tên sản phẩm", dataIndex: "name", key: "name", render: (text) => <strong>{text}</strong> },
    { 
      title: "Danh mục", 
      key: "category",
      render: (_, record) => record.categoryName || record.CategoryName || record.category?.name || record.Category?.Name || "Chưa phân loại"
    },
    { 
      title: "Đơn vị tính", 
      key: "units",
      render: (_, record) => {
        const units = record.productUnits || record.ProductUnits || [];
        return (
          <Space direction="vertical" size={0}>
            {units.map((u, idx) => (
              <Tag key={idx} color={u.isBaseUnit ? "blue" : "default"}>
                {u.unitName} {u.conversionValue > 1 ? `(x${u.conversionValue})` : ""}
              </Tag>
            ))}
          </Space>
        );
      }
    },
    { 
      title: "Giá bán", 
      key: "price",
      render: (_, record) => {
        const units = record.productUnits || record.ProductUnits || [];
        return (
          <Space direction="vertical" size={0}>
            {units.map((u, idx) => (
              <div key={idx}>
                <span className="text-red-600 font-bold">
                  {u.price?.toLocaleString("vi-VN")} đ
                </span>
                <small className="text-gray-400"> /{u.unitName}</small>
              </div>
            ))}
          </Space>
        );
      }
    },
    { 
      title: "Tồn kho", 
      key: "stock",
      render: (_, record) => {
        const stock = record.inventory?.quantity ?? record.Inventory?.Quantity ?? 0;
        const unit = record.baseUnit ?? record.BaseUnit ?? 'Cái';
        return (
          <Tag color={stock < 10 ? "volcano" : "green"} style={{ fontSize: '14px', padding: '4px 8px' }}>
            <strong>{stock}</strong> {unit}
          </Tag>
        );
      }
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
        width={600}
      >
        <Form form={form} layout="vertical" onFinish={handleAddProduct} initialValues={{ baseUnitName: 'Cái', initialStock: 0 }}>
          <div className="grid grid-cols-2 gap-4">
            <Form.Item name="name" label="Tên sản phẩm" rules={[{ required: true }]} className="col-span-2">
              <Input placeholder="VD: Xi măng Hà Tiên" />
            </Form.Item>
            <Form.Item name="sku" label="Mã SKU" rules={[{ required: true }]}>
              <Input placeholder="VD: XM-HT-01" />
            </Form.Item>
            <Form.Item name="categoryId" label="Danh mục" rules={[{ required: true }]}>
              <Select placeholder="Chọn danh mục">
                {categories.map(cat => (
                  <Select.Option key={cat.id} value={cat.id}>{cat.name}</Select.Option>
                ))}
              </Select>
            </Form.Item>
            <Form.Item name="baseUnitName" label="Đơn vị tính gốc" rules={[{ required: true }]}>
              <Input placeholder="VD: Cái, Bao, Kg..." />
            </Form.Item>
            <Form.Item name="price" label="Giá bán (Đơn vị gốc)" rules={[{ required: true }]}>
              <InputNumber 
                className="w-full" 
                formatter={value => `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                parser={value => value.replace(/\$\s?|(,*)/g, '')}
              />
            </Form.Item>
            <Form.Item name="initialStock" label="Số lượng tồn kho ban đầu">
              <InputNumber className="w-full" min={0} />
            </Form.Item>
            <Form.Item name="description" label="Mô tả sản phẩm" className="col-span-2">
              <Input.TextArea rows={3} />
            </Form.Item>
          </div>
        </Form>
      </Modal>
    </div>
  );
}
