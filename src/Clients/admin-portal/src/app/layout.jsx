import Providers from '@/components/providers'
import SignalRListener from './SignalRListener'
import './globals.css' // <--- THÊM DÒNG QUAN TRỌNG NÀY
export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <Providers>
          <SignalRListener />
          {children}
        </Providers>
      </body>
    </html>
  )
}
