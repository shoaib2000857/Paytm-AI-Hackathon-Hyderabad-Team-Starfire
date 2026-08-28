# Paytm Intent Mesh — Hackathon Demo Guide

## Demo Objective

Show the complete commerce loop:

```text
Need
 ↓
Intent
 ↓
Match
 ↓
Merchant
 ↓
Offer
 ↓
Payment
 ↓
Confirmation
 ↓
Demand Intelligence
```

## Setup

Start the backend:

```bash
source .venv/bin/activate
uvicorn backend.main:app --reload --port 8000
```

Start the frontend:

```bash
cd frontend
npm run dev
```

Open:

```text
http://localhost:3000/ask
```

Keep another browser window ready for:

```text
http://localhost:3000/merchant
```

## Step 1 — Customer Request

Use:

> “Mujhe kal 7 baje tak ₹800 ke andar 1 kg eggless chocolate cake chahiye.”

The request can be entered by text or browser microphone.

## Step 2 — Intent Packet

Show the extracted intent.

Highlight:

- 1 kg quantity;
- ₹800 budget;
- eggless requirement;
- chocolate cake;
- deadline of tomorrow at 7 PM.

Explain that the customer can review what the system understood before merchant discovery.

## Step 3 — Find a Merchant

Select:

**Find for me**

The system applies deterministic merchant matching.

Explain:

> AI understands the request, but deterministic software enforces the hard constraints.

## Step 4 — Merchant Device

Open:

**Open merchant device**

Use the Soundbox emulator.

For the primary demo, confirm:

```text
Merchant: Sweet Crumbs
Price: ₹750
Ready by: 6:30 PM
```

## Step 5 — Live Offer

Return to the customer view.

The offer should arrive through the live event path.

The merchant selector can also be used to demonstrate additional synthetic merchants such as HomeBakes and Cake House.

## Step 6 — Accept and Pay

Choose Sweet Crumbs.

Pay:

```text
₹750
```

Complete the simulated Paytm payment.

Show the closed-loop confirmation.

## Step 7 — Merchant Confirmation

Return to the merchant interface and show the live:

```text
₹ received
```

confirmation.

## Step 8 — Opportunity Pulse

Open:

```text
/merchant/opportunities
```

Explain that explicit unfulfilled demand can become merchant growth intelligence.

## Suggested Closing Line

> “Today Paytm tells you where your money went. Intent Mesh lets Paytm understand what you needed, find who can fulfil it, and close the loop.”

## Demo Reliability

Before presenting:

- verify the backend is running;
- verify the frontend production build;
- test the primary cake request;
- keep the merchant window ready;
- do not depend on external API access if the network is unstable;
- use the deterministic fallback when necessary.

## Claims to Avoid

Do not describe the prototype as having:

- real-money payment movement;
- production Paytm APIs;
- production merchant inventory;
- physical Soundbox firmware integration;
- production KYC or identity infrastructure.
