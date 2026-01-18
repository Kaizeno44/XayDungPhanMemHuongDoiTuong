import Providers from '@/components/providers'
import './globals.css' // <--- THÊM DÒNG QUAN TRỌNG NÀY
export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}