// In production the browser talks to the same origin and Next proxies /api to
// FastAPI. NEXT_PUBLIC_API_URL remains available for split deployments.
export const API = process.env.NEXT_PUBLIC_API_URL || "";
export async function api<T>(path:string, init?:RequestInit):Promise<T>{
  const res=await fetch(`${API}${path}`,{...init,headers:{"Content-Type":"application/json",...(init?.headers||{})}});
  if(!res.ok) throw new Error((await res.json().catch(()=>({detail:"Request failed"}))).detail||"Request failed");
  return res.json();
}
