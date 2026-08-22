"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Mic } from "lucide-react";
import { API, api } from "@/lib/api";

const demoOffers: any = {
  M001: { price: 750, time: "18:30", delivery: false },
  M002: { price: 700, time: "19:00", delivery: false },
  M003: { price: 800, time: "18:00", delivery: true },
};

export default function Merchant() {
  const router = useRouter();
  const [intentId, setIntentId] = useState("");
  const [mid, setMid] = useState("");
  const [intent, setIntent] = useState<any>();
  const [matches, setMatches] = useState<any[]>([]);
  const [form, setForm] = useState<any>({
    price: 750,
    time: "18:30",
    delivery: false,
  });
  const [sent, setSent] = useState(false);
  const [declined, setDeclined] = useState(false);
  const [listening, setListening] = useState(false);
  const [transcript, setTranscript] = useState("");
  const [payment, setPayment] = useState<any>();
  useEffect(
    () =>
      setIntentId(
        new URLSearchParams(window.location.search).get("intent") || "",
      ),
    [],
  );
  useEffect(() => {
    if (!intentId) return;
    Promise.all([
      api<any>(`/api/intents/${intentId}`),
      api<any[]>(`/api/intents/${intentId}/matches`),
    ]).then(([i, m]) => {
      setIntent(i);
      setMatches(m);
      if (m[0]) setMid(m[0].id);
    });
  }, [intentId]);
  useEffect(() => {
    if (!mid) return;
    const merchant = matches.find((m) => m.id === mid);
    const budget = intent?.parsed?.budget_max;
    setForm(
      demoOffers[mid] || {
        price: budget
          ? Math.max(100, Math.round((budget * 0.9) / 10) * 10)
          : 500,
        time: "18:30",
        delivery: !!merchant?.delivery,
      },
    );
    setSent(false);
    setDeclined(false);
  }, [mid, matches, intent]);
  useEffect(() => {
    if (!intentId) return;
    const es = new EventSource(`${API}/api/events/${intentId}`);
    es.addEventListener("payment_received", (e: any) =>
      setPayment(JSON.parse(e.data)),
    );
    return () => es.close();
  }, [intentId]);
  async function voice() {
    try {
      setListening(true);
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const rec = new MediaRecorder(stream);
      const chunks: Blob[] = [];
      rec.ondataavailable = (e) => chunks.push(e.data);
      rec.onstop = async () => {
        stream.getTracks().forEach((t) => t.stop());
        const data = new FormData();
        data.append(
          "audio",
          new Blob(chunks, { type: "audio/webm" }),
          "merchant.webm",
        );
        try {
          const stt = await fetch(`${API}/api/speech/transcribe`, {
            method: "POST",
            body: data,
          }).then((r) => r.json());
          setTranscript(stt.transcript);
          const extracted = await api<any>("/api/merchant-responses/parse", {
            method: "POST",
            body: JSON.stringify({ text: stt.transcript }),
          });
          const p = extracted.parsed;
          setForm((f: any) => ({
            price: p.price || f.price,
            time: p.ready_at || f.time,
            delivery: p.delivery,
          }));
        } finally {
          setListening(false);
        }
      };
      rec.start();
      setTimeout(() => rec.stop(), 4500);
    } catch {
      setListening(false);
      setTranscript("Demo transcription loaded");
    }
  }
  async function respond(can_fulfil = true) {
    if (!intentId || !mid) return;
    await api(`/api/merchant/${mid}/respond`, {
      method: "POST",
      body: JSON.stringify({
        intent_id: intentId,
        can_fulfil,
        price: +form.price,
        ready_at: form.time,
        delivery: form.delivery,
        transcript,
      }),
    });
    setDeclined(!can_fulfil);
    setSent(true);
  }
  const p = intent?.parsed;
  const merchant = matches.find((m) => m.id === mid);
  const deadline = p?.needed_by
    ? String(p.needed_by).includes("T")
      ? new Date(p.needed_by).toLocaleString("en-IN", {
          day: "numeric",
          month: "short",
          hour: "numeric",
          minute: "2-digit",
        })
      : p.needed_by
    : "Flexible";
  if (!intentId)
    return (
      <main className="soundbox">
        <div className="device">
          <div className="devicebrand">
            pay<span>tm</span> SOUND<span>BOX</span>
          </div>
          <div className="screen">
            <h1>No active request</h1>
            <p className="muted">
              Start a customer request first, then open the matched merchant
              device.
            </p>
            <button className="primary" onClick={() => router.push("/ask")}>
              Start request
            </button>
          </div>
        </div>
      </main>
    );
  return (
    <main className="soundbox">
      <div className="device">
        <div className="devicebrand">
          pay<span>tm</span> SOUND<span>BOX</span>
        </div>
        <div className="screen">
          {payment && payment.merchant?.id === mid ? (
            <>
              <div className="successmark">✓</div>
              <h1 style={{ textAlign: "center" }}>
                ₹{payment.amount} received
              </h1>
              <p className="muted" style={{ textAlign: "center" }}>
                New order confirmed · {p?.item_or_service} · Ready by{" "}
                {form.time}
              </p>
              <button
                className="primary"
                onClick={() => router.push("/merchant/opportunities")}
              >
                View demand insights
              </button>
            </>
          ) : sent ? (
            <>
              <div className="successmark">✓</div>
              <h1 style={{ textAlign: "center" }}>
                {declined ? "Request declined" : "Offer sent"}
              </h1>
              <p className="muted" style={{ textAlign: "center" }}>
                {declined
                  ? "We’ll route the request to the next suitable merchant."
                  : `The customer received your ₹${form.price} offer live.`}
              </p>
              <button
                className="primary"
                onClick={() => router.push(`/offers/${intentId}`)}
              >
                View customer screen
              </button>
            </>
          ) : (
            <>
              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                }}
              >
                <span className="eyebrow">🔔 New customer request</span>
                <select
                  value={mid}
                  onChange={(e) => setMid(e.target.value)}
                  style={{
                    border: 0,
                    background: "#e8f8ff",
                    padding: 7,
                    borderRadius: 8,
                  }}
                >
                  {matches.map((m) => (
                    <option value={m.id} key={m.id}>
                      {m.name}
                    </option>
                  ))}
                </select>
              </div>
              <div className="bell">
                {p?.category === "pharmacy"
                  ? "💊"
                  : p?.category === "florist"
                    ? "💐"
                    : p?.category === "plumber"
                      ? "🔧"
                      : p?.category === "printing"
                        ? "🖨️"
                        : p?.category === "grocery"
                          ? "🛍️"
                          : "🎂"}
              </div>
              <h1>{p?.item_or_service || "Loading request…"}</h1>
              <h3>
                {deadline} · {merchant?.name}
              </h3>
              <div className="budget">
                <small>CUSTOMER BUDGET</small>
                <br />
                <b>
                  {p?.budget_max ? `UP TO ₹${p.budget_max}` : "OPEN TO QUOTES"}
                </b>
              </div>
              <div className="fields">
                <label>
                  YOUR PRICE
                  <input
                    type="number"
                    value={form.price}
                    onChange={(e) =>
                      setForm({ ...form, price: e.target.value })
                    }
                  />
                </label>
                <label>
                  READY BY
                  <input
                    type="time"
                    value={form.time}
                    onChange={(e) => setForm({ ...form, time: e.target.value })}
                  />
                </label>
                <label>
                  FULFILMENT
                  <select
                    value={form.delivery ? "delivery" : "pickup"}
                    onChange={(e) =>
                      setForm({
                        ...form,
                        delivery: e.target.value === "delivery",
                      })
                    }
                  >
                    <option value="pickup">Pickup / Visit</option>
                    <option value="delivery">Delivery / Home service</option>
                  </select>
                </label>
              </div>
              {transcript && (
                <p className="muted" style={{ fontSize: 12 }}>
                  “{transcript}”
                </p>
              )}
              <div className="replygrid">
                <button className="danger" onClick={() => respond(false)}>
                  Can&apos;t fulfil
                </button>
                <button className="primary" onClick={() => respond(true)}>
                  Confirm offer
                </button>
                <button className="voice" onClick={voice} disabled={listening}>
                  <Mic size={16} />{" "}
                  {listening ? "Listening…" : "Reply by voice"}
                </button>
              </div>
              <button
                className="chip"
                style={{ width: "100%", marginTop: 13 }}
                onClick={() => router.push("/merchant/opportunities")}
              >
                View Opportunity Pulse
              </button>
            </>
          )}
        </div>
      </div>
    </main>
  );
}
