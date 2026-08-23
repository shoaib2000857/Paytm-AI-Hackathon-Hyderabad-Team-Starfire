# Vyapaar Mesh presentation assets

## Live prototype

https://committed-chairs-peripheral-sri.trycloudflare.com

This temporary HTTPS deployment runs the Next.js experience and proxies its API
requests to the local FastAPI service. Keep the host laptop powered on and
connected to the internet while the link is being evaluated.

## Screenshot order

1. `01_ask_paytm.png` — multilingual natural-language demand entry
2. `02_intent_packet.png` — structured intent and hard constraints
3. `03_merchant_mesh.png` — deterministic capability matching
4. `04_merchant_soundbox.png` — merchant acceptance and negotiation
5. `05_live_offers.png` — ranked live offers
6. `06_checkout.png` — UPI, Paytm staging gateway, QR, and Pay Aadha
7. `07_payment_success.png` — closed payment and fulfilment loop
8. `08_opportunity_pulse.png` — measurable unmet local demand

`00_contact_sheet.png` contains the complete product story on one canvas.
`vyapaar-mesh-walkthrough.mp4` is a compact silent fallback walkthrough.

## Recreate screenshots

From `flutter_app/` run:

```bash
flutter test --update-goldens test/screenshot_test.dart
```
