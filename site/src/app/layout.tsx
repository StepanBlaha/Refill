import type { Metadata, Viewport } from "next";
import "./globals.css";
import SmoothScroll from "@/components/SmoothScroll";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Refresh from "@/components/Refresh";
import { AUTHOR, BASE, SITE_URL } from "@/lib/site";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  applicationName: "Refill",
  authors: [AUTHOR],
  creator: AUTHOR.name,
  publisher: AUTHOR.name,
  keywords: [
    "Refill",
    "macOS menu bar app",
    "AI usage limits",
    "Claude Code usage",
    "Codex usage",
    "Copilot quota",
    "Cursor usage",
    "Gemini CLI quota",
    "rate limit reset notification",
  ],
  formatDetection: { telephone: false, email: false, address: false },
  icons: {
    icon: [
      { url: `${BASE}/favicon.svg`, type: "image/svg+xml" },
      { url: `${BASE}/icon-32.png`, type: "image/png", sizes: "32x32" },
      { url: `${BASE}/icon-192.png`, type: "image/png", sizes: "192x192" },
    ],
    apple: [{ url: `${BASE}/apple-touch-icon.png`, sizes: "180x180", type: "image/png" }],
  },
};

export const viewport: Viewport = {
  themeColor: "#000000",
  colorScheme: "dark",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <a className="skip" href="#top">Skip to content</a>
        <SmoothScroll>
          <Refresh />
          <Header />
          {children}
          <Footer />
        </SmoothScroll>
      </body>
    </html>
  );
}
