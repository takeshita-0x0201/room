import type { Metadata } from "next";
import { headers } from "next/headers";
import "./globals.css";

const title = "Room — See what’s full. Make room.";
const description = "A lightweight open-source macOS menu bar app for memory pressure, storage, and safety-first cleanup.";

export async function generateMetadata(): Promise<Metadata> {
  const requestHeaders = await headers();
  const host = requestHeaders.get("x-forwarded-host") ?? requestHeaders.get("host") ?? "localhost:3000";
  const protocol = requestHeaders.get("x-forwarded-proto") ?? (host.startsWith("localhost") ? "http" : "https");
  return {
    metadataBase: new URL(`${protocol}://${host}`), title, description,
    icons: { icon: "/room-app-icon.png", shortcut: "/room-app-icon.png" },
    openGraph: { title, description, type: "website", images: [{ url: "/og.png", width: 1792, height: 1024, alt: "Room — See what’s full. Make room." }] },
    twitter: { card: "summary_large_image", title, description, images: ["/og.png"] },
  };
}

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
