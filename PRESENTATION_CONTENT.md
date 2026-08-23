# Paytm Vyapaar Mesh — Presentation Content

## Deck setup

- Recommended length: **8 slides**
- Presentation time: **4–5 minutes including demo**
- Format: **16:9 widescreen**
- Visual style: clean Paytm white, navy and cyan; large typography; rounded cards; minimal text
- Product name: **Paytm Vyapaar Mesh**
- Technical platform name: **Powered by Paytm Intent Mesh**
- Hero line: **Human language becomes the merchant API.**
- Subtitle: **The agentic commerce network for offline India**

Do not put paragraphs on the actual slides. The detailed text below each slide is for the speaker.

---

# Slide 1 — The gap in offline commerce

## On-slide copy

### The shop outside your house is payable online.

### It isn't queryable online.

```text
Paytm QR          ✓
Paytm Soundbox    ✓
Merchant account  ✓

Website           ✕
Live catalogue    ✕
Inventory API     ✕
Ordering system   ✕
```

### AI commerce is leaving offline India behind.

## Recommended visual

Split screen:

- Left: a neighbourhood bakery, tailor, kirana or repair shop with a Paytm Soundbox.
- Right: an AI agent blocked by a large “NO API” symbol.

## Speaker notes — approximately 25 seconds

> AI agents can already shop from businesses that expose APIs and structured catalogues. But the home baker, tailor, kirana, chemist or repair shop near us usually has none of those things. They may already accept Paytm payments, but customers still have to search, call, message and manually compare them. India digitised the payment endpoint before digitising the merchant interface.

---

# Slide 2 — The Paytm-native insight

## On-slide copy

### But these merchants already have a Paytm endpoint.

```text
Customer intent
      ↓
Paytm consumer app
      ↓
Merchant Mesh
      ↓
Paytm for Business / Soundbox
```

# Turn the payment network into a demand network.

## Recommended visual

Place a Paytm consumer phone on the left and a Soundbox-style merchant device on the right. Connect them with a glowing cyan network line.

## Speaker notes — approximately 25 seconds

> Paytm already has something strategically powerful: a consumer endpoint, a merchant relationship, a connected storefront device and the ability to close the payment. So we asked a different question—not what chatbot Paytm should add, but how Paytm could make its offline merchant network reachable to AI.

---

# Slide 3 — Introducing Paytm Vyapaar Mesh

## On-slide copy

# Paytm Vyapaar Mesh

### The agentic commerce network for offline India

```text
Speak your need
      ↓
Intent Packet
      ↓
Capability + GPS routing
      ↓
Merchant accepts or negotiates
      ↓
Live ranked offers
      ↓
Paytm payment
```

# Human language becomes the merchant API.

## Recommended visual

A simple horizontal or circular six-step flow. Use icons for microphone, structured document, location/network, Soundbox, offer cards and payment.

## Speaker notes — approximately 30 seconds

> Vyapaar Mesh turns natural-language demand into a structured commerce protocol. The customer tells Paytm the outcome they need. The system creates an Intent Packet, finds nearby merchants likely to fulfil it, asks only those merchants for live availability, receives negotiated offers and closes the selected transaction through Paytm. The merchant does not need to maintain a complete catalogue or build an API. Human language becomes the merchant API.

---

# Slide 4 — Live demo

## On-slide copy

# “Mujhe kal 7 baje tak ₹800 ke andar
# 1 kg eggless chocolate cake chahiye.”

### Speak → Route → Negotiate → Pay

## Recommended visual

Keep this slide almost empty. Use one large quote, a microphone pulse and the four-word flow at the bottom.

## Demo sequence — approximately 90 seconds

### Customer side

1. Open **Ask Paytm**.
2. Submit the cake request.
3. Show the structured Intent Packet.
4. Point out the hard constraints: eggless, budget and deadline.
5. Find nearby matched merchants.

### Merchant side

6. Open the merchant Soundbox.
7. Select Sweet Crumbs.
8. Review the incoming request.
9. Open negotiation controls.
10. Set ₹750, 6:30 PM and pickup/delivery.
11. Send the live offer.

### Customer side again

12. Open the received offer.
13. Choose the merchant.
14. Show full UPI, Paytm QR and **Pay Aadha**.
15. Complete the simulated payment.
16. Open Opportunity Pulse if time permits.

## Demo narration

> Sarvam handles multilingual and code-mixed language. The model structures the request, but it does not choose the merchant or move money. Deterministic software enforces hard constraints and ranks merchants. On the other side, the merchant can accept, decline or negotiate directly through a Soundbox-style interface. The response becomes a live offer, and the customer remains in control through selection and payment.

---

# Slide 5 — AI where needed, deterministic where required

## On-slide copy

### AI handles the unstructured world

- Indian-language and code-mixed speech
- Intent and constraint extraction
- Merchant spoken-response extraction
- Human language → validated schema

### Deterministic software protects commerce

- Hard-constraint filtering
- GPS and capability matching
- Merchant and offer ranking
- Payment state and idempotency

## Footer line

### We use AI where the world is unstructured—and deterministic software where money requires predictability.

## Recommended visual

Two balanced columns separated by a vertical line. Use cyan for AI and navy for deterministic systems.

## Speaker notes — approximately 30 seconds

> We deliberately do not ask an LLM to rank merchants or decide payment logic. Sarvam converts unstructured customer and merchant conversations into validated data. Normal software then applies business rules, geographic filtering, ranking, permissions and payment state. This gives us multilingual intelligence without making financial behaviour unpredictable.

---

# Slide 6 — The working prototype

## On-slide copy

### Two Paytm experiences. One commerce network.

```text
Flutter customer app
        │
        ├──── FastAPI + SQLite
        │          │
        │     Sarvam AI layer
        │          │
        └──── Merchant Soundbox
```

### Working today

- GPS-aware discovery
- 20 merchants across 12 categories
- Accept, decline and negotiate
- Live structured offers
- Full UPI, QR and Pay Aadha
- Opportunity Pulse

### Verified

**8 backend tests passed · Flutter analysis clean · Android APK built**

## Recommended visual

Architecture in the centre with small customer-phone and Soundbox mockups on either side. Put the verification line inside a green pill.

## Speaker notes — approximately 25 seconds

> This is a complete two-sided prototype, not a slideshow concept. The Flutter client and web experience use a FastAPI backend with SQLite persistence. We have 20 synthetic merchants across 12 local-business categories, GPS matching, merchant negotiation, offers, multiple simulated payment modes and demand intelligence. Private Paytm payment rails and physical Soundbox firmware are simulated because production access was not provided.

---

# Slide 7 — Why this creates a Paytm moat

## On-slide copy

### Today Paytm sees the final event

# ₹750 paid

### Vyapaar Mesh sees the complete commerce loop

```text
Intent
  ↓
Merchant response
  ↓
Payment
  ↓
Fulfilment
  ↓
Learning
```

### The flywheel

```text
More intent
→ better capability understanding
→ better routing and trust
→ more fulfilment
→ more Paytm transactions
→ more intent
```

## Paytm gains

- Incremental transactions and GMV
- More valuable Soundbox subscriptions
- Stronger merchant retention
- Explicit local-demand intelligence
- Foundation for agentic commerce

## Speaker notes — approximately 35 seconds

> A search company can find business listings, and an AI company can understand language. Paytm can connect customer intent, a live merchant endpoint, fulfilment history and payment inside one ecosystem. Every transaction improves capability and trust signals. Every unmet request becomes measurable opportunity. More usage makes the network more useful, which creates more commerce and a defensible Paytm data flywheel.

---

# Slide 8 — From payment network to commerce intelligence

## On-slide copy

### The wedge we built

# Intent → Merchant → Offer → Payment

### What the network unlocks next

```text
Opportunity Pulse
      ↓
Economic Weather
      ↓
Business Autopilot
      ↓
Agent-to-agent commerce
```

# Paytm today moves money.
# Vyapaar Mesh moves demand.
# Paytm's future moves commerce.

## Recommended visual

A rising staircase or expanding concentric rings. Keep Intent Mesh highlighted as “working prototype” and label the other layers “future”.

## Speaker notes — approximately 30 seconds

> Intent Mesh is the strategic wedge. Explicit demand and observed fulfilment can later power local Opportunity Pulse, Economic Weather, merchant Autopilot and even agent-to-agent procurement and settlement. We are not claiming those future systems are all built today. We built the data-generating and transaction-generating layer that makes them credible.

## Final closing

> Paytm digitised how India's offline merchants receive money. Vyapaar Mesh makes those same merchants discoverable and actionable to AI. We are not building another marketplace or chatbot. We are building the intent layer between demand and India's offline merchant network.

---

# Optional backup slide 9 — Judge questions

Do not present this unless asked.

| Question | Short answer |
|---|---|
| Isn't this a marketplace? | Marketplaces require maintained listings. Intent Mesh begins with constraints and queries likely merchants for live fulfilment. |
| How do you know inventory? | POS merchants can answer automatically; offline merchants confirm availability live. |
| Won't merchants be spammed? | Hard filters and top-K routing contact only 3–5 likely merchants. |
| Why not ONDC? | ONDC sellers can plug in automatically; Intent Mesh reaches the less-digitised long tail. |
| Why Paytm? | Paytm owns the consumer relationship, merchant endpoint and payment closure. |
| Why does AI matter? | Both demand and merchant capability are expressed in unstructured Indian language. |
| What if a merchant fails? | Acceptance-to-fulfilment outcomes update reliability and future routing. |
| Is Pay Aadha escrow? | No. It is a simulated milestone-payment concept; production would require Paytm policy and payment-rail support. |

---

# Optional backup slide 10 — Responsible network design

## On-slide copy

### Privacy

- Share only the request details required for fulfilment
- Hide customer identity until selection where necessary
- Do not expose financial history to merchants

### Fairness

- Fit and fulfilment quality before paid placement
- Exploration for new merchants
- Sponsored results never override hard constraints

### Reliability

- Rate limits and merchant availability controls
- Response, cancellation and fulfilment tracking
- Automatic expansion when a merchant does not respond

---

# Design system for the deck

## Colours

- Paytm navy: `#002970`
- Paytm cyan: `#00BAF2`
- Dark text: `#101D33`
- Muted text: `#68758D`
- Background: `#F5F8FC`
- Success: `#00A86B`
- White: `#FFFFFF`

## Typography
Hey s
- Use a modern geometric sans-serif such as Inter, Manrope or DM Sans.
- Slide title: 34–44 pt, bold or extra-bold.
- Hero statements: 44–60 pt.
- Supporting text: 18–24 pt.
- Never place body copy smaller than 16 pt.

## Layout rules

- One dominant idea per slide.
- Maximum six short bullets when bullets are unavoidable.
- Use diagrams instead of paragraphs.
- Maintain generous whitespace.
- Use rounded cards and thin blue-grey borders consistent with the prototype.
- Use the Paytm logo only as a small anchor, not repeatedly across every content block.
- Add a small footer: `Paytm Vyapaar Mesh · Powered by Intent Mesh`.

# Final delivery checklist

- [ ] Replace diagrams with clean vector shapes rather than screenshots of text.
- [ ] Add 3–4 high-quality screenshots from the actual Flutter prototype.
- [ ] Use the customer screen, merchant Soundbox, offers and Pay Aadha/Opportunity Pulse.
- [ ] Keep Slide 4 open during the live demonstration.
- [ ] Verify every metric immediately before presenting.
- [ ] Label synthetic data, simulated payment and future functionality honestly.
- [ ] Export both PPTX and PDF.
- [ ] Keep the deck locally available in case internet access fails.
