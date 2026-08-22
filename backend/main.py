from __future__ import annotations

import asyncio, json, math, os, re, sqlite3, uuid
from contextlib import asynccontextmanager
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

ROOT = Path(__file__).parent
load_dotenv(ROOT / ".env")
DB_PATH = ROOT / "intent_mesh.db"
MERCHANTS = json.loads((ROOT / "data/merchants.json").read_text())
MERCHANT_BY_ID = {m["id"]: m for m in MERCHANTS}
subscribers: dict[str, list[asyncio.Queue]] = {}

@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield


app = FastAPI(title="Paytm Intent Mesh API", version="1.0.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


class IntentIn(BaseModel):
    text: str = Field(min_length=3, max_length=500)
    location: dict[str, float] = {"lat": 17.397, "lng": 78.490}


class IntentPacket(BaseModel):
    category: str
    request_type: str
    item_or_service: str
    attributes: dict[str, Any] = {}
    budget_min: float | None = None
    budget_max: float | None = None
    needed_by: str | None = None
    location: dict[str, float] | None = None
    radius_km: float = 5
    fulfilment_preferences: list[str] = []
    hard_constraints: list[str] = []
    soft_preferences: list[str] = []


class IntentCreate(BaseModel):
    raw_text: str
    parsed: dict[str, Any]


class MerchantResponse(BaseModel):
    intent_id: str
    can_fulfil: bool = True
    price: int | None = None
    ready_at: str | None = None
    delivery: bool = False
    notes: str | None = None
    transcript: str | None = None


class MerchantReplyIn(BaseModel):
    text: str = Field(min_length=2, max_length=300)


class MerchantReplyPacket(BaseModel):
    can_fulfil: bool = True
    price: int | None = None
    ready_at: str | None = None
    delivery: bool = False
    notes: str | None = None


class AcceptOffer(BaseModel):
    user_id: str = "U001"


class PaymentIn(BaseModel):
    offer_id: str
    method: str = "UPI •••• 4821"


def db() -> sqlite3.Connection:
    con = sqlite3.connect(DB_PATH)
    con.row_factory = sqlite3.Row
    return con


def init_db() -> None:
    con = db()
    con.executescript("""
    CREATE TABLE IF NOT EXISTS intents(id TEXT PRIMARY KEY, raw_text TEXT, parsed TEXT, status TEXT, created_at TEXT);
    CREATE TABLE IF NOT EXISTS matches(intent_id TEXT, merchant_id TEXT, score REAL, status TEXT, PRIMARY KEY(intent_id,merchant_id));
    CREATE TABLE IF NOT EXISTS offers(id TEXT PRIMARY KEY, intent_id TEXT, merchant_id TEXT, price INTEGER, ready_at TEXT, delivery INTEGER, notes TEXT, score REAL, status TEXT, created_at TEXT);
    CREATE TABLE IF NOT EXISTS payments(id TEXT PRIMARY KEY, offer_id TEXT, amount INTEGER, method TEXT, status TEXT, created_at TEXT);
    """)
    con.commit(); con.close()


def parse_demo(text: str) -> dict[str, Any]:
    t = text.lower()
    now = datetime.now()
    budget_patterns = [
        r"(?:₹|rs\.?)\s*(\d[\d,]*)",
        r"(?:under|below|within)\s*(?:₹|rs\.?)?\s*(\d[\d,]*)",
        r"(\d[\d,]*)\s*(?:rupaye|rupees|rs\.?)\s*(?:ke\s+)?(?:andar|tak|below|under)",
        r"(?:budget|andar|lopu)\D{0,8}(\d[\d,]*)",
    ]
    short_budget=re.search(r"\b(\d+(?:\.\d+)?)\s*k\b",t)
    price=int(float(short_budget.group(1))*1000) if short_budget else None
    if price is None:
        for pattern in budget_patterns:
            match = re.search(pattern, t)
            if match:
                price = int(match.group(1).replace(",", "")); break
    if price is None:
        nums = [int(x) for x in re.findall(r"\b(\d{3,5})\b", t)]
        price = max(nums) if nums else None
    if any(x in t for x in ["cake", "bakery", "eggless"]):
        category, request_type, item = "bakery", "custom_cake", "chocolate cake" if "chocolate" in t else "cake"
        attrs = {"weight": "1 kg" if re.search(r"1\s*(kg|kilo)", t) else None, "flavour": "chocolate" if "chocolate" in t else None, "eggless": "eggless" in t}
        constraints = [x for x, ok in [("eggless", attrs["eggless"]), (f"budget ≤ ₹{price}", price is not None), ("needed by deadline", True)] if ok]
    elif any(x in t for x in ["iphone", "screen", "mobile", "phone"]):
        category, request_type, item = "phone_repair", "screen_replacement", "iPhone 15" if "iphone 15" in t else "phone"
        attrs = {"service": "screen replacement", "quality": "genuine or premium compatible" if any(x in t for x in ["genuine", "quality"]) else None}
        constraints = ["same day"] if any(x in t for x in ["today", "aaj"]) else []
        if price: constraints.append(f"budget ≤ ₹{price}")
    elif any(x in t for x in ["blouse", "stitch", "tailor", "alteration"]):
        category, request_type, item = "tailor", "blouse_stitching", "blouse stitching"
        attrs = {"alteration_included": "alteration" in t}
        constraints = ["alteration included"] if attrs["alteration_included"] else []
        if price: constraints.append(f"budget ≤ ₹{price}")
    elif any(x in t for x in ["medicine","tablet","chemist","pharmacy","prescription","dawai"]):
        category,request_type,item,attrs,constraints="pharmacy","medicine_request",text.strip(),{},[]
    elif any(x in t for x in ["haircut","salon","facial","bridal","beauty","parlour"]):
        category,request_type,item,attrs,constraints="salon","appointment",text.strip(),{},[]
    elif any(x in t for x in ["catering","lunch","meals","tiffin","food order","party food","biryani","pizza","dinner"]):
        category,request_type,item,attrs,constraints="home_catering","food_order",text.strip(),{},[]
    elif any(x in t for x in ["flower","bouquet","florist","garland"]):
        category,request_type,item,attrs,constraints="florist","custom_order",text.strip(),{},[]
    elif any(x in t for x in ["grocery","kirana","rice","atta","dal","vegetables"]):
        category,request_type,item,attrs,constraints="grocery","product_request",text.strip(),{},[]
    elif any(x in t for x in ["print","photocopy","xerox","banner","visiting card"]):
        category,request_type,item,attrs,constraints="printing","print_order",text.strip(),{},[]
    elif any(x in t for x in ["plumber","leak","tap repair","pipe repair"]):
        category,request_type,item,attrs,constraints="plumber","home_service",text.strip(),{},[]
    elif any(x in t for x in ["stationery","notebook","pen","school supplies"]):
        category,request_type,item,attrs,constraints="stationery","product_request",text.strip(),{},[]
    else:
        category, request_type, item, attrs, constraints = "general", "local_request", text.strip(), {}, []
    tomorrow = now + timedelta(days=1)
    needed = tomorrow.replace(hour=19, minute=0, second=0, microsecond=0) if any(x in t for x in ["tomorrow", "kal", "repu"]) else None
    return {"category":category,"request_type":request_type,"item_or_service":item,"attributes":attrs,"budget_min":None,"budget_max":price,"needed_by":needed.isoformat() if needed else ("today" if any(x in t for x in ["today","aaj"]) else None),"location":{"lat":17.397,"lng":78.490},"radius_km":5,"fulfilment_preferences":["delivery","pickup"] if "delivery" not in t else ["delivery"],"hard_constraints":constraints,"soft_preferences":["nearby","well-rated","earlier better"]}


def normalize_category(category:str, text:str) -> str:
    value=(category or "general").lower().strip().replace(" ","_")
    aliases={"food":"home_catering","restaurant":"home_catering","catering":"home_catering","medicine":"pharmacy","medical":"pharmacy","chemist":"pharmacy","beauty":"salon","beauty_salon":"salon","mobile_repair":"phone_repair","electronics_repair":"phone_repair","seamstress":"tailor","fashion":"tailor","flowers":"florist","flower_shop":"florist","kirana":"grocery","supermarket":"grocery","print_shop":"printing","print_service":"printing","plumbing":"plumber","office_supplies":"stationery"}
    value=aliases.get(value,value)
    supported={m["category"] for m in MERCHANTS}
    if value in supported: return value
    inferred=parse_demo(text)["category"]
    return inferred if inferred in supported else "general"


async def parse_with_sarvam(text: str) -> dict[str, Any] | None:
    key = os.getenv("SARVAM_API_KEY")
    if not key: return None
    categories="bakery, cafe, phone_repair, tailor, salon, pharmacy, home_catering, florist, grocery, printing, plumber, stationery, general"
    payload={"model":"sarvam-105b-conversations","messages":[{"role":"system","content":f"Extract a local-commerce intent. category MUST be exactly one of: {categories}. Choose the closest supported category; use general only when none apply. Respond as one JSON object with exactly these keys: category, request_type, item_or_service, attributes, budget_min, budget_max, needed_by, radius_km, fulfilment_preferences, hard_constraints, soft_preferences. Never invent missing requirements; use null. hard_constraints and soft_preferences must be arrays of strings. Normalize dates to ISO-8601. In Indian code-mixed commerce, 'kal 7 baje tak' means tomorrow at 19:00 unless AM/morning is explicit."},{"role":"user","content":f"Current local date: {datetime.now().date().isoformat()}\nCustomer request: {text}"}],"response_format":{"type":"json_object"},"reasoning_effort":None,"temperature":0.1,"max_tokens":600}
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            res=await client.post("https://api.sarvam.ai/v1/chat/completions",headers={"api-subscription-key":key},json=payload)
            res.raise_for_status(); content=res.json()["choices"][0]["message"].get("content")
            if not content: return None
            raw=json.loads(content); fallback=parse_demo(text)
            is_general=fallback["category"]=="general"
            semantic_keys=("category","request_type","item_or_service","attributes") if is_general else ("item_or_service",)
            preference_keys=("hard_constraints","soft_preferences") if is_general else ()
            for key in (*semantic_keys,"budget_min","budget_max","needed_by","radius_km","fulfilment_preferences",*preference_keys):
                value=raw.get(key)
                if value is not None and (not isinstance(value,(list,dict,str)) or len(value)>0): fallback[key]=value
            fallback["location"]={"lat":17.397,"lng":78.490}
            return IntentPacket.model_validate(fallback).model_dump()
    except Exception as exc:
        print(f"Sarvam intent extraction unavailable: {type(exc).__name__}: {str(exc)[:240]}")
        return None


def parse_merchant_fallback(text: str) -> dict[str, Any]:
    t=text.lower(); nums=[int(x) for x in re.findall(r"\d+",t)]
    price=next((n for n in nums if 100 <= n <= 100000),None)
    hour,minute=18,30
    time_matches=[m for m in re.finditer(r"\b(\d{1,2})(?::(\d{2}))\s*(am|pm)?",t) if int(m.group(1))<=23]
    if time_matches:
        time_match=time_matches[-1]; candidate=int(time_match.group(1)); suffix=time_match.group(3)
        hour=candidate + (12 if suffix=="pm" and candidate<12 else 0); minute=int(time_match.group(2))
    return {"can_fulfil":not any(x in t for x in ["can't","cannot","nahi","ledu","unable"]),"price":price,"ready_at":f"{hour:02d}:{minute:02d}","delivery":any(x in t for x in ["delivery","deliver"," పంపిస్త","bhej"]),"notes":None}


async def parse_merchant_with_sarvam(text:str) -> dict[str,Any] | None:
    key=os.getenv("SARVAM_API_KEY")
    if not key: return None
    payload={"model":"sarvam-105b-conversations","messages":[{"role":"system","content":"Extract a merchant's response to a customer request. Return JSON with exactly: can_fulfil (boolean), price (integer or null), ready_at (24-hour HH:MM or null), delivery (boolean), notes (string or null). Do not invent. Indian phrases like 'chestam' or 'kar denge' mean can fulfil. For shop readiness, an unqualified time such as 6:30 means 18:30 unless morning or AM is explicit."},{"role":"user","content":text}],"response_format":{"type":"json_object"},"reasoning_effort":None,"temperature":0.1,"max_tokens":220}
    try:
        async with httpx.AsyncClient(timeout=8) as client:
            res=await client.post("https://api.sarvam.ai/v1/chat/completions",headers={"api-subscription-key":key},json=payload); res.raise_for_status()
            content=res.json()["choices"][0]["message"].get("content")
            return MerchantReplyPacket.model_validate(json.loads(content)).model_dump() if content else None
    except Exception as exc:
        print(f"Sarvam merchant extraction unavailable: {type(exc).__name__}: {str(exc)[:180]}")
        return None


def distance_km(a: dict, b: dict) -> float:
    return math.sqrt((a["lat"]-b["lat"])**2+(a["lng"]-b["lng"])**2)*111


def required_caps(p: dict) -> list[str]:
    if p["category"]=="bakery": return ["eggless","chocolate_cake","1kg_cake"]
    if p["category"]=="phone_repair": return ["screen_replacement","iphone_15","same_day"]
    if p["category"]=="tailor": return ["blouse_stitching","alteration"]
    return []


def rank_merchants(p: dict) -> list[dict]:
    req=required_caps(p); loc=p.get("location") or {"lat":17.397,"lng":78.490}; ranked=[]
    for m in MERCHANTS:
        if m["category"] != p["category"]: continue
        caps=m["capabilities"]; cap=sum(caps.get(x,0) for x in req)/max(1,len(req))
        if req and any(caps.get(x,0)<.5 for x in req): continue
        dist=distance_km(loc,m); proximity=max(0,1-dist/max(p.get("radius_km",5),1))
        score=.30*cap+.20*cap+.15*proximity+.10*(m["rating"]/5)+.10*max(0,1-m["avg_response_time"]/120)+.10*m["fulfilment_rate"]+.05*(1 if m["delivery"] else .7)
        ranked.append({**m,"distance_km":round(dist,1),"match_score":round(score,3)})
    return sorted(ranked,key=lambda x:x["match_score"],reverse=True)[:5]


async def publish(session: str, event: str, data: dict) -> None:
    for q in subscribers.get(session,[]): await q.put({"event":event,"data":data})


@app.get("/api/health")
def health(): return {"status":"ok","service":"Paytm Intent Mesh","merchants":len(MERCHANTS),"sarvam_configured":bool(os.getenv("SARVAM_API_KEY"))}


@app.post("/api/intents/parse")
async def parse_intent(body: IntentIn):
    sarvam_parsed=await parse_with_sarvam(body.text)
    parsed=sarvam_parsed or parse_demo(body.text); parsed["location"]=body.location
    parsed["category"]=normalize_category(parsed.get("category","general"),body.text)
    parsed=IntentPacket.model_validate(parsed).model_dump()
    return {"transcript":body.text,"parsed":parsed,"engine":"sarvam-105b-conversations" if sarvam_parsed else "demo-fallback"}


@app.post("/api/merchant-responses/parse")
async def parse_merchant_reply(body:MerchantReplyIn):
    parsed=await parse_merchant_with_sarvam(body.text)
    return {"transcript":body.text,"parsed":parsed or parse_merchant_fallback(body.text),"engine":"sarvam-105b-conversations" if parsed else "demo-fallback"}


@app.post("/api/intents")
async def create_intent(body: IntentCreate):
    iid="I"+uuid.uuid4().hex[:8].upper(); matches=rank_merchants(body.parsed); con=db()
    con.execute("INSERT INTO intents VALUES(?,?,?,?,?)",(iid,body.raw_text,json.dumps(body.parsed),"routing",datetime.now().isoformat()))
    for m in matches: con.execute("INSERT INTO matches VALUES(?,?,?,?)",(iid,m["id"],m["match_score"],"notified"))
    con.commit(); con.close()
    return {"id":iid,"status":"routing","matches":matches,"session_id":iid}


@app.get("/api/intents/{iid}")
def get_intent(iid:str):
    con=db(); row=con.execute("SELECT * FROM intents WHERE id=?",(iid,)).fetchone(); con.close()
    if not row: raise HTTPException(404,"Intent not found")
    return {**dict(row),"parsed":json.loads(row["parsed"])}


@app.get("/api/intents/{iid}/matches")
def get_matches(iid:str):
    con=db(); rows=con.execute("SELECT * FROM matches WHERE intent_id=? ORDER BY score DESC",(iid,)).fetchall(); intent=con.execute("SELECT parsed FROM intents WHERE id=?",(iid,)).fetchone(); con.close()
    loc=(json.loads(intent["parsed"]).get("location") if intent else None) or {"lat":17.397,"lng":78.490}
    return [{**MERCHANT_BY_ID[r["merchant_id"]],"distance_km":round(distance_km(loc,MERCHANT_BY_ID[r["merchant_id"]]),1),"match_score":r["score"],"status":r["status"]} for r in rows]


@app.get("/api/merchant/{mid}/requests")
def merchant_requests(mid:str):
    con=db(); rows=con.execute("SELECT i.*,m.score FROM matches m JOIN intents i ON i.id=m.intent_id WHERE m.merchant_id=? AND m.status='notified' ORDER BY i.created_at DESC",(mid,)).fetchall(); con.close()
    return [{**dict(r),"parsed":json.loads(r["parsed"])} for r in rows]


@app.post("/api/merchant/{mid}/respond")
async def merchant_respond(mid:str, body:MerchantResponse):
    if mid not in MERCHANT_BY_ID: raise HTTPException(404,"Merchant not found")
    con=db(); match=con.execute("SELECT score FROM matches WHERE intent_id=? AND merchant_id=?",(body.intent_id,mid)).fetchone(); intent_row=con.execute("SELECT parsed FROM intents WHERE id=?",(body.intent_id,)).fetchone()
    if not match: con.close(); raise HTTPException(404,"Request was not routed to this merchant")
    con.execute("UPDATE matches SET status=? WHERE intent_id=? AND merchant_id=?",("responded" if body.can_fulfil else "declined",body.intent_id,mid))
    if not body.can_fulfil: con.commit(); con.close(); await publish(body.intent_id,"merchant_declined",{"merchant_id":mid}); return {"status":"declined"}
    oid="O"+uuid.uuid4().hex[:8].upper(); price=body.price or 750
    price_fit=max(0,1-abs(price-750)/750); offer_score=.50*match["score"]+.20*.95+.15*(MERCHANT_BY_ID[mid]["rating"]/5)+.10*price_fit+.05*(1 if body.delivery else .8)
    con.execute("DELETE FROM offers WHERE intent_id=? AND merchant_id=?",(body.intent_id,mid))
    con.execute("INSERT INTO offers VALUES(?,?,?,?,?,?,?,?,?,?)",(oid,body.intent_id,mid,price,body.ready_at or "18:30",int(body.delivery),body.notes,offer_score,"available",datetime.now().isoformat())); con.commit(); con.close()
    loc=(json.loads(intent_row["parsed"]).get("location") if intent_row else None) or {"lat":17.397,"lng":78.490}
    offer={"id":oid,"intent_id":body.intent_id,"merchant":{**MERCHANT_BY_ID[mid],"distance_km":round(distance_km(loc,MERCHANT_BY_ID[mid]),1)},"price":price,"ready_at":body.ready_at or "18:30","delivery":body.delivery,"notes":body.notes,"score":round(offer_score,3),"status":"available"}
    await publish(body.intent_id,"offer_received",offer); return offer


@app.get("/api/intents/{iid}/offers")
def offers(iid:str):
    con=db(); rows=con.execute("SELECT * FROM offers WHERE intent_id=? ORDER BY score DESC",(iid,)).fetchall(); intent=con.execute("SELECT parsed FROM intents WHERE id=?",(iid,)).fetchone(); con.close()
    loc=(json.loads(intent["parsed"]).get("location") if intent else None) or {"lat":17.397,"lng":78.490}
    return [{**dict(r),"delivery":bool(r["delivery"]),"merchant":{**MERCHANT_BY_ID[r["merchant_id"]],"distance_km":round(distance_km(loc,MERCHANT_BY_ID[r["merchant_id"]]),1)}} for r in rows]


@app.post("/api/offers/{oid}/accept")
async def accept(oid:str, body:AcceptOffer):
    con=db(); row=con.execute("SELECT * FROM offers WHERE id=?",(oid,)).fetchone()
    if not row: con.close(); raise HTTPException(404,"Offer not found")
    con.execute("UPDATE offers SET status=CASE WHEN id=? THEN 'accepted' ELSE 'not_selected' END WHERE intent_id=?",(oid,row["intent_id"])); con.commit(); con.close()
    await publish(row["intent_id"],"offer_accepted",{"offer_id":oid}); return {"status":"accepted","offer_id":oid}


@app.post("/api/payments/simulate")
async def payment(body:PaymentIn):
    con=db(); offer=con.execute("SELECT * FROM offers WHERE id=?",(body.offer_id,)).fetchone()
    if not offer: con.close(); raise HTTPException(404,"Offer not found")
    existing=con.execute("SELECT * FROM payments WHERE offer_id=? AND status='success'",(body.offer_id,)).fetchone()
    if existing:
        con.close()
        return {**dict(existing),"intent_id":offer["intent_id"],"merchant":MERCHANT_BY_ID[offer["merchant_id"]]}
    pid="P"+uuid.uuid4().hex[:10].upper(); con.execute("INSERT INTO payments VALUES(?,?,?,?,?,?)",(pid,body.offer_id,offer["price"],body.method,"success",datetime.now().isoformat())); con.execute("UPDATE intents SET status='paid' WHERE id=?",(offer["intent_id"],)); con.commit(); con.close()
    result={"id":pid,"offer_id":body.offer_id,"intent_id":offer["intent_id"],"amount":offer["price"],"status":"success","method":body.method,"merchant":MERCHANT_BY_ID[offer["merchant_id"]]}
    await publish(offer["intent_id"],"payment_received",result); return result


@app.get("/api/merchant/{mid}/opportunities")
def opportunities(mid:str):
    return {"period":"This week","potential_demand":18400,"requests":43,"trends":[{"label":"Eggless cakes under ₹600","count":18,"change":41,"unfulfilled":12,"value":8200},{"label":"Same-day custom cakes","count":12,"change":18,"unfulfilled":7,"value":6100},{"label":"500g cakes after 8 PM","count":9,"change":12,"unfulfilled":6,"value":4100}]}


@app.get("/api/events/{session_id}")
async def events(session_id:str):
    q=asyncio.Queue(); subscribers.setdefault(session_id,[]).append(q)
    async def stream():
        try:
            yield "event: connected\ndata: {}\n\n"
            while True:
                try: item=await asyncio.wait_for(q.get(),15); yield f"event: {item['event']}\ndata: {json.dumps(item['data'])}\n\n"
                except asyncio.TimeoutError: yield "event: ping\ndata: {}\n\n"
        finally: subscribers[session_id].remove(q)
    return StreamingResponse(stream(),media_type="text/event-stream",headers={"Cache-Control":"no-cache","X-Accel-Buffering":"no"})


@app.post("/api/speech/transcribe")
async def transcribe(audio:UploadFile=File(...)):
    data=await audio.read(); key=os.getenv("SARVAM_API_KEY")
    if key:
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                res=await client.post("https://api.sarvam.ai/speech-to-text",headers={"api-subscription-key":key},files={"file":(audio.filename or "audio.webm",data,audio.content_type)},data={"model":"saaras:v3","mode":"codemix"}); res.raise_for_status(); return {"transcript":res.json().get("transcript","") ,"engine":"sarvam"}
        except Exception: pass
    return {"transcript":"Mujhe kal 7 baje tak ₹800 ke andar 1 kg eggless chocolate cake chahiye.","engine":"demo-fallback"}
