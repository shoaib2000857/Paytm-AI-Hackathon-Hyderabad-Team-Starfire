import os, sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parents[1]))
os.environ["SARVAM_API_KEY"]=""
from fastapi.testclient import TestClient
from main import app

client=TestClient(app)

def test_complete_cake_flow():
    with client:
        parsed=client.post("/api/intents/parse",json={"text":"Mujhe kal 7 baje tak ₹800 ke andar 1 kg eggless chocolate cake chahiye.","location":{"lat":17.397,"lng":78.490}}).json()["parsed"]
        assert parsed["category"]=="bakery" and parsed["attributes"]["eggless"] is True and parsed["budget_max"]==800
        intent=client.post("/api/intents",json={"raw_text":"cake","parsed":parsed}).json()
        assert [m["id"] for m in intent["matches"]][:3]==["M001","M002","M003"]
        offer=client.post("/api/merchant/M001/respond",json={"intent_id":intent["id"],"can_fulfil":True,"price":750,"ready_at":"18:30","delivery":False}).json()
        assert offer["price"]==750
        assert client.post(f"/api/offers/{offer['id']}/accept",json={}).json()["status"]=="accepted"
        payment=client.post("/api/payments/simulate",json={"offer_id":offer["id"]}).json()
        assert payment["status"]=="success" and payment["amount"]==750

def test_hard_constraint_excludes_non_eggless():
    with client:
        parsed=client.post("/api/intents/parse",json={"text":"1 kg eggless chocolate cake under 800 tomorrow"}).json()["parsed"]
        result=client.post("/api/intents",json={"raw_text":"cake","parsed":parsed}).json()
        assert "M004" not in [m["id"] for m in result["matches"]]

def test_service_verticals():
    with client:
        phone=client.post("/api/intents/parse",json={"text":"iPhone 15 screen aaj replace karwana hai, 4k ke andar"}).json()["parsed"]
        tailor=client.post("/api/intents/parse",json={"text":"Blouse Saturday tak stitch chahiye, budget ₹900, ek alteration included"}).json()["parsed"]
        assert phone["category"]=="phone_repair"
        assert tailor["category"]=="tailor" and tailor["budget_max"]==900

def test_merchant_reply_decline_and_idempotency():
    with client:
        reply=client.post("/api/merchant-responses/parse",json={"text":"₹750 mein kar denge, 18:30 tak ready, pickup"}).json()["parsed"]
        assert reply["price"]==750 and reply["ready_at"]=="18:30" and reply["can_fulfil"] is True
        parsed=client.post("/api/intents/parse",json={"text":"eggless chocolate cake under ₹800 tomorrow"}).json()["parsed"]
        intent=client.post("/api/intents",json={"raw_text":"cake","parsed":parsed}).json()
        declined=client.post("/api/merchant/M002/respond",json={"intent_id":intent["id"],"can_fulfil":False}).json()
        assert declined["status"]=="declined"
        payload={"intent_id":intent["id"],"can_fulfil":True,"price":750,"ready_at":"18:30"}
        first=client.post("/api/merchant/M001/respond",json=payload).json()
        second=client.post("/api/merchant/M001/respond",json=payload).json()
        assert len(client.get(f"/api/intents/{intent['id']}/offers").json())==1
        client.post(f"/api/offers/{second['id']}/accept",json={})
        pay1=client.post("/api/payments/simulate",json={"offer_id":second["id"]}).json()
        pay2=client.post("/api/payments/simulate",json={"offer_id":second["id"]}).json()
        assert pay1["id"]==pay2["id"]

def test_no_match_is_explicit():
    with client:
        result=client.post("/api/intents",json={"raw_text":"spaceship","parsed":{"category":"spacecraft","request_type":"repair","item_or_service":"rocket","attributes":{},"radius_km":5,"fulfilment_preferences":[],"hard_constraints":[],"soft_preferences":[]}}).json()
        assert result["matches"]==[]

def test_general_commerce_prompts_normalize_to_supported_merchants():
    with client:
        cases={"Need a flower bouquet delivered today":"florist","Send medicines from a nearby chemist":"pharmacy","Need a plumber for leaking tap":"plumber","Print 100 visiting cards today":"printing","Order rice and dal from nearby kirana":"grocery"}
        for text,category in cases.items():
            parsed=client.post("/api/intents/parse",json={"text":text}).json()["parsed"]
            assert parsed["category"]==category
            created=client.post("/api/intents",json={"raw_text":text,"parsed":parsed}).json()
            assert created["matches"] and created["matches"][0]["category"]==category

def test_gps_changes_distance_and_proximity_ranking():
    with client:
        parsed=client.post("/api/intents/parse",json={"text":"Need a flower bouquet","location":{"lat":17.404,"lng":78.487}}).json()["parsed"]
        created=client.post("/api/intents",json={"raw_text":"flowers","parsed":parsed}).json()
        assert created["matches"][0]["id"]=="M016"
        assert created["matches"][0]["distance_km"]==0.0
        persisted=client.get(f"/api/intents/{created['id']}/matches").json()
        assert persisted[0]["distance_km"]==0.0
