"use client";
import {Home,ScanLine,WalletCards,UserRound} from "lucide-react";
export default function PaytmShell({children,nav=true}:{children:React.ReactNode,nav?:boolean}){return <main className="phone"><header className="top"><div className="brand">pay<span>tm</span></div><div className="avatar">SS</div></header>{children}{nav&&<nav className="bottom"><span className="active"><Home size={19}/><br/>Home</span><span><ScanLine size={19}/><br/>Scan</span><span><WalletCards size={19}/><br/>Balance</span><span><UserRound size={19}/><br/>Profile</span></nav>}</main>}

