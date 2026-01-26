"use client";
import { useState, useEffect } from "react";
import axios from "axios";
import Cookies from "js-cookie";
import { Check, Edit2 } from "lucide-react";
import { Modal, Form, Input, InputNumber, message } from "antd";

export default function SubscriptionsPage() {
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [editingPlan, setEditingPlan] = useState(null);
  const [form] = Form.useForm();

  const fetchPlans = async () => {
    try {
      const token = Cookies.get("accessToken");
      const res = await axios.get("http://localhost:5000/api/admin/plans", {
        headers: { Authorization: `Bearer ${token}` }
      });
      setPlans(res.data);
    } catch (err) {
      console.error("Lỗi tải gói cước:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPlans();
  }, []);

  const handleEdit = (plan) => {
    setEditingPlan(plan);
    form.setFieldsValue(plan);
    setIsModalVisible(true);
  };

  const handleUpdate = async (values) => {
    try {
      const token = Cookies.get("accessToken");
      await axios.put(`http://localhost:5000/api/admin/plans/${editingPlan.id}`, {
        ...editingPlan,
        ...values
      }, {
        headers: { Authorization: `Bearer ${token}` }
      });
      message.success("Cập nhật gói cước thành công!");
      setIsModalVisible(false);
      fetchPlans();
    } catch (err) {
      message.error("Lỗi cập nhật gói cước");
    }
  };

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold text-gray-800 mb-8">💳 Quản lý Gói Dịch Vụ</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        {plans.map((plan, idx) => (
          <div key={idx} className={`p-6 rounded-2xl shadow-sm border relative ${plan.color}`}>
            {plan.recommended && <span className="absolute top-0 right-0 bg-blue-600 text-white text-xs px-3 py-1 rounded-bl-lg rounded-tr-lg font-bold">Khuyên dùng</span>}
            <h3 className="text-xl font-bold text-gray-900">{plan.name}</h3>
            <div className="text-3xl font-bold text-blue-600 my-4">{plan.price.toLocaleString("vi-VN")} đ<span className="text-sm text-gray-500 font-normal">/tháng</span></div>
            <ul className="space-y-3 mb-6">
                <li className="flex items-center text-sm text-gray-600">
                    <Check size={16} className="text-green-500 mr-2"/> 
                    Tối đa {plan.maxEmployees} nhân viên
                </li>
                <li className="flex items-center text-sm text-gray-600">
                    <Check size={16} className="text-green-500 mr-2"/> 
                    {plan.allowAI ? "Hỗ trợ AI dự đoán" : "Không có AI"}
                </li>
                <li className="flex items-center text-sm text-gray-600">
                    <Check size={16} className="text-green-500 mr-2"/> 
                    Quản lý kho & Đơn hàng
                </li>
            </ul>
            <button 
                onClick={() => handleEdit(plan)}
                className="w-full py-2 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 font-medium flex items-center justify-center gap-2"
            >
                <Edit2 size={16}/> Chỉnh sửa
            </button>
          </div>
        ))}
      </div>

      <Modal
        title="Chỉnh sửa gói cước"
        open={isModalVisible}
        onCancel={() => setIsModalVisible(false)}
        onOk={() => form.submit()}
      >
        <Form form={form} layout="vertical" onFinish={handleUpdate}>
          <Form.Item name="name" label="Tên gói cước" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="price" label="Giá tiền (VND)" rules={[{ required: true }]}>
            <InputNumber className="w-full" formatter={value => `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')} parser={value => value.replace(/\$\s?|(,*)/g, '')} />
          </Form.Item>
          <Form.Item name="maxEmployees" label="Số lượng nhân viên tối đa" rules={[{ required: true }]}>
            <InputNumber className="w-full" min={1} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
