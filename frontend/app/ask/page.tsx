"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  Mic,
  Send,
  ScanLine,
  ReceiptIndianRupee,
  Smartphone,
  Lightbulb,
  MapPin,
} from "lucide-react";
import PaytmShell from "@/components/PaytmShell";
import { API, api } from "@/lib/api";
const cake =
  "Mujhe kal 7 baje tak ₹800 ke andar 1 kg eggless chocolate cake chahiye.";
export default function Ask() {
  const [text, setText] = useState(cake);
  const [busy, setBusy] = useState(false);
  const [listening, setListening] = useState(false);
  const [locating, setLocating] = useState(false);
  const [location, setLocation] = useState({
    lat: 17.397,
    lng: 78.49,
    source: "Demo location · KMIT",
  });
  const [err, setErr] = useState("");
  const router = useRouter();
  async function parse() {
    setBusy(true);
    setErr("");
    try {
      const result = await api<any>("/api/intents/parse", {
        method: "POST",
        body: JSON.stringify({
          text,
          location: { lat: location.lat, lng: location.lng },
        }),
      });
      result.location_source = location.source;
      sessionStorage.setItem("intentDraft", JSON.stringify(result));
      router.push("/request/new");
    } catch (e: any) {
      setErr(e.message);
    } finally {
      setBusy(false);
    }
  }
  function locate() {
    if (!navigator.geolocation) {
      setErr("GPS is not available in this browser");
      return;
    }
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      (p) => {
        setLocation({
          lat: p.coords.latitude,
          lng: p.coords.longitude,
          source: `Live GPS · ±${Math.round(p.coords.accuracy)} m`,
        });
        setLocating(false);
        setErr("");
      },
      (e) => {
        setLocating(false);
        setErr(
          e.code === 1
            ? "Location permission was denied; using the KMIT demo location"
            : "Could not get GPS; using the KMIT demo location",
        );
      },
      { enableHighAccuracy: true, timeout: 8000, maximumAge: 30000 },
    );
  }
  async function voice() {
    if (!navigator.mediaDevices) {
      setText(cake);
      return;
    }
    try {
      setListening(true);
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const rec = new MediaRecorder(stream);
      const chunks: Blob[] = [];
      rec.ondataavailable = (e) => chunks.push(e.data);
      rec.onstop = async () => {
        stream.getTracks().forEach((t) => t.stop());
        const form = new FormData();
        form.append(
          "audio",
          new Blob(chunks, { type: "audio/webm" }),
          "request.webm",
        );
        try {
          const r = await fetch(`${API}/api/speech/transcribe`, {
            method: "POST",
            body: form,
          });
          const d = await r.json();
          setText(d.transcript || cake);
        } finally {
          setListening(false);
        }
      };
      rec.start();
      setTimeout(() => rec.stop(), 4500);
    } catch {
      setListening(false);
      setText(cake);
    }
  }
  return (
    <PaytmShell>
      <section className="hero">
        <div className="eyebrow">Introducing Paytm Mesh</div>
        <h1>
          Good morning,
          <br />
          what do you need?
        </h1>
        <p className="muted">
          Tell Paytm the outcome. We&apos;ll find who can make it happen.
        </p>
      </section>
      <div className="askbox">
        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          aria-label="Describe what you need"
        />
        <button className="chip" style={{ marginBottom: 12 }} onClick={locate}>
          <MapPin size={15} /> {locating ? "Finding you…" : location.source}
        </button>
        <div className="microw">
          <button
            className={`mic ${listening ? "live" : ""}`}
            onClick={voice}
            aria-label="Speak request"
          >
            <Mic />
          </button>
          <button
            className="primary"
            disabled={busy || text.length < 3}
            onClick={parse}
          >
            {busy ? (
              "Understanding…"
            ) : (
              <>
                Ask Paytm <Send size={16} />
              </>
            )}
          </button>
        </div>
      </div>
      {err && <div className="error">{err}</div>}
      <div className="quick">
        <h3>Try another need</h3>
        <div className="chips">
          <button className="chip" onClick={() => setText(cake)}>
            🎂 Eggless cake
          </button>
          <button
            className="chip"
            onClick={() =>
              setText(
                "iPhone 15 screen aaj replace karwana hai, ₹4000 ke andar",
              )
            }
          >
            📱 Phone repair
          </button>
          <button
            className="chip"
            onClick={() =>
              setText(
                "Blouse Saturday tak stitch chahiye, budget ₹900, ek alteration included",
              )
            }
          >
            🧵 Tailor
          </button>
        </div>
      </div>
      <div className="paygrid">
        <div>
          <div className="payicon">
            <ScanLine />
          </div>
          Scan & Pay
        </div>
        <div>
          <div className="payicon">
            <Smartphone />
          </div>
          Recharge
        </div>
        <div>
          <div className="payicon">
            <ReceiptIndianRupee />
          </div>
          Pay Bills
        </div>
        <div>
          <div className="payicon">
            <Lightbulb />
          </div>
          Deals
        </div>
      </div>
    </PaytmShell>
  );
}
