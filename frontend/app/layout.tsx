import type { Metadata } from "next";
import "./globals.css";
export const metadata:Metadata={title:"Paytm Intent Mesh",description:"Human language becomes the merchant API"};
export default function Layout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}

