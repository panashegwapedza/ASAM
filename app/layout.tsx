import './globals.css';
import type { Metadata } from 'next';
export const metadata: Metadata = { title: 'Wren — Sales & Marketing Intelligence', description: 'Wren is your operational sales and marketing workspace.' };
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}