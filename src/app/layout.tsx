import type { Metadata } from "next";
import "./globals.css";
import MetaPixel from "./MetaPixel";
import GoogleAnalytics from "./GoogleAnalytics";
import TikTokPixel from "./TikTokPixel";

export const metadata: Metadata = {
  title: "Ya Toca",
  description: "Ya Toca",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`antialiased`}
      >
        <MetaPixel />
        <GoogleAnalytics />
        <TikTokPixel />
        {children}
      </body>
    </html>
  );
}
