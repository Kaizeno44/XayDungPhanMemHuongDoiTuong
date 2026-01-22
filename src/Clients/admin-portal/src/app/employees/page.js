"use client";
import { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeftOutlined, UserAddOutlined, DeleteOutlined, TeamOutlined } from "@ant-design/icons";
import { Button, Table, Tag, Space, Typography, Card, message, Popconfirm } from "antd";
import api from "@/utils/api";

const { Title, Text } = Typography;

export default function EmployeesPage() {
  const router = useRouter();
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(true);

  // Hàm tải dữ liệu
  const fetchEmployees = async () => {
    try {
      const res = await api.get("/users");
      
      // 1. Lọc bỏ tài khoản SuperAdmin
      // 2. Sắp xếp: Owner luôn nằm trên Employee
      const processedData = res.data
        .filter(user => user.role?.toLowerCase() !== "superadmin")
        .sort((a, b) => {
          const roleOrder = { "owner": 1, "admin": 2, "employee": 3 };
          const orderA = roleOrder[a.role?.toLowerCase()] || 99;
          const orderB = roleOrder[b.role?.toLowerCase()] || 99;
          return orderA - orderB;
        });

      setEmployees(processedData);
    } catch (err) {
      console.error("Lỗi tải nhân viên:", err);
      message.error("Không tải được danh sách nhân viên!");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEmployees();
  }, []);

  const columns = [
    {
      title: "Họ và Tên",
      dataIndex: "fullName",
      key: "fullName",
      render: (text) => <Text strong>{text}</Text>,
    },
    {
      title: "Email",
      dataIndex: "email",
      key: "email",
    },
    {
      title: "Vai trò",
      dataIndex: "role",
      key: "role",
      render: (role) => (
        <Tag color={role === "Admin" || role === "Owner" ? "purple" : "blue"}>
          {role?.toUpperCase()}
        </Tag>
      ),
    },
    {
      title: "Hành động",
      key: "action",
      align: "right",
      render: (_, record) => {
        const isSuperAdmin = record.role === "SuperAdmin";
        const isOwner = record.role === "Owner";
        
        const handleDelete = async () => {
          try {
            await api.delete(`/users/${record.id}`);
            message.success("Đã xóa nhân viên thành công!");
            fetchEmployees(); // Tải lại danh sách
          } catch (err) {
            console.error("Lỗi khi xóa:", err);
            message.error(err.response?.data?.message || "Không thể xóa nhân viên!");
          }
        };

        return (
          <Popconfirm
            title="Xóa nhân viên"
            description={isSuperAdmin || isOwner ? `Không thể xóa ${record.role}` : "Bạn có chắc chắn muốn xóa nhân viên này không?"}
            onConfirm={handleDelete}
            okText="Có"
            cancelText="Không"
            disabled={isSuperAdmin || isOwner}
          >
            <Button 
              type="text" 
              danger 
              icon={<DeleteOutlined />} 
              disabled={isSuperAdmin || isOwner}
              title={isSuperAdmin || isOwner ? `Không có quyền xóa ${record.role}` : ""}
            >
              Xóa
            </Button>
          </Popconfirm>
        );
      },
    },
  ];

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-6xl mx-auto">
        <Card className="shadow-sm border-0">
          <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-8">
            <Space direction="vertical" size={0}>
              <div className="flex items-center gap-3">
                <Button 
                  icon={<ArrowLeftOutlined />} 
                  onClick={() => router.push("/merchant/dashboard")}
                  className="hover:text-blue-600"
                />
                <Title level={2} style={{ margin: 0 }}>Quản lý Nhân viên</Title>
              </div>
              <Text type="secondary" className="ml-12">
                <TeamOutlined className="mr-1" /> Quản lý đội ngũ nhân sự của cửa hàng
              </Text>
            </Space>

            <Link href="/employees/create">
              <Button type="primary" size="large" icon={<UserAddOutlined />} className="shadow-md">
                Thêm Nhân viên mới
              </Button>
            </Link>
          </div>

          <Table 
            columns={columns} 
            dataSource={employees} 
            rowKey="id" 
            loading={loading}
            pagination={{ pageSize: 10 }}
            className="border rounded-lg overflow-hidden"
          />
        </Card>
      </div>
    </div>
  );
}
