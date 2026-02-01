import Providers from '@/components/providers'
import SignalRListener from './SignalRListener'
import { NotificationProvider } from '@/components/NotificationProvider'
import NotificationDisplay from '@/components/NotificationDisplay'
import './globals.css' // <--- THÊM DÒNG QUAN TRỌNG NÀY
export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <Providers>
          <NotificationProvider>
            <SignalRListener />
            {children}
            <NotificationDisplay />
          </NotificationProvider>
        </Providers>
      </body>
    </html>
  )
}
