import axios from 'axios';
// import Cookies from 'js-cookie'; // Tạm thời chưa dùng đến

const api = axios.create({
  baseURL: 'https://localhost:5000/api', // Trỏ thẳng vào Gateway cổng 5000
  headers: {
    'Content-Type': 'application/json',
  },
});

export default api;