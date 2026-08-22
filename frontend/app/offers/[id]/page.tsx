"use client";
import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import PaytmShell from "@/components/PaytmShell";
import { API, api } from "@/lib/api";
export default function Offers() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [offers, setOffers] = useState<any[]>([]);
  const [matches, setMatches] = useState<any[]>([]);
  const [matchesLoaded, setMatchesLoaded] = useState(false);
  const [elapsed, setElapsed] = useState(0);
  useEffect(() => {
    api<any[]>(`/api/intents/${id}/matches`)
      .then(setMatches)
      .finally(() => setMatchesLoaded(true));
    api<any[]>(`/api/intents/${id}/offers`).then(setOffers);
    const es = new EventSource(`${API}/api/events/${id}`);
    es.addEventListener("offer_received", (e: any) =>
      setOffers((o) =>
        [
          ...o.filter((x) => x.id !== JSON.parse(e.data).id),
          JSON.parse(e.data),
        ].sort((a, b) => b.score - a.score),
      ),
    );
    const poll = setInterval(
      () =>
        api<any[]>(`/api/intents/${id}/offers`)
          .then(setOffers)
          .catch(() => {}),
      1000,
    );
    const clock = setInterval(() => setElapsed((x) => x + 1), 1000);
    return () => {
      es.close();
      clearInterval(poll);
      clearInterval(clock);
    };
  }, [id]);
  async function choose(o: any) {
    await api(`/api/offers/${o.id}/accept`, {
      method: "POST",
      body: JSON.stringify({ user_id: "U001" }),
    });
    sessionStorage.setItem("chosenOffer", JSON.stringify(o));
    router.push(`/pay/${o.id}`);
  }
  return (
    <PaytmShell nav={false}>
      <section className="panel">
        {offers.length === 0 ? (
          <div className="searching">
            <div className="eyebrow">Merchant Mesh is working</div>
            <div className="orb">⌁</div>
            <h1>
              {matchesLoaded && matches.length === 0
                ? "No exact match yet"
                : "Finding nearby merchants…"}
            </h1>
            <p className="muted">
              {matchesLoaded && matches.length === 0
                ? "We found no merchant that safely meets every hard constraint. Try expanding the radius or adjusting one requirement."
                : "Checking capabilities, distance and reliability—not blasting every Soundbox."}
            </p>
            {matches.length > 0 && (
              <div className="progress">
                <i />
              </div>
            )}
            {matches
              .slice(0, Math.min(matches.length, Math.floor(elapsed / 2)))
              .map((m) => (
                <div className="responded" key={m.id}>
                  ✓ Request delivered to {m.name}
                </div>
              ))}
            {matches.length > 0 ? (
              <button
                className="chip"
                style={{ marginTop: 18 }}
                onClick={() => router.push(`/merchant?intent=${id}`)}
              >
                Open merchant device →
              </button>
            ) : (
              <button
                className="primary"
                style={{ marginTop: 18 }}
                onClick={() => router.push("/ask")}
              >
                Adjust request
              </button>
            )}
          </div>
        ) : (
          <>
            <div className="eyebrow">Live responses</div>
            <h1 className="title">
              {offers.length}{" "}
              {offers.length === 1 ? "business can" : "businesses can"} fulfil
              your request
            </h1>
            <p className="muted">
              Ranked by fit, readiness and trust—not just the lowest price.
            </p>
            {offers.map((o, i) => (
              <article
                className={`offer ${i === 0 ? "recommended" : ""}`}
                key={o.id}
              >
                {i === 0 && <span className="ribbon">RECOMMENDED</span>}
                <div className="offerhead">
                  <div>
                    <div className="merchant">{o.merchant.name}</div>
                    <div className="muted">
                      ⭐ {o.merchant.rating} ·{" "}
                      {o.merchant.delivery ? "Delivery available" : "Pickup"}
                    </div>
                  </div>
                  <div className="price">₹{o.price}</div>
                </div>
                <div className="meta">
                  <span>◷ Ready {o.ready_at}</span>
                  <span>◎ {o.merchant.distance_km ?? "—"} km</span>
                  <span>✓ Reliable fulfilment</span>
                </div>
                <button className="choose" onClick={() => choose(o)}>
                  Choose {o.merchant.name}
                </button>
              </article>
            ))}
          </>
        )}
      </section>
    </PaytmShell>
  );
}
