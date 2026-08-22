import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  runApp(const IntentMeshApp());
}

String get apiBase => !kIsWeb && defaultTargetPlatform == TargetPlatform.android
    ? 'http://10.0.2.2:8000'
    : 'http://127.0.0.1:8000';

const navy = Color(0xff002970);
const paytmBlue = Color(0xff00baf2);
const ink = Color(0xff101D33);
const muted = Color(0xff68758D);
const canvas = Color(0xffF5F8FC);
const success = Color(0xff00A86B);

class IntentMeshApp extends StatelessWidget {
  const IntentMeshApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Paytm Intent Mesh',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: canvas,
          colorScheme: ColorScheme.fromSeed(
              seedColor: paytmBlue, primary: navy, surface: Colors.white),
          fontFamily: 'sans-serif',
          appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              foregroundColor: ink),
          cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: Color(0xffE5ECF4)))),
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800))),
          inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xffDFE8F1))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xffDFE8F1))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: paytmBlue, width: 2))),
        ),
        home: const AskScreen(),
      );
}

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});
  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final text = TextEditingController(
      text:
          'Mujhe kal 7 baje tak ₹800 ke andar 1 kg eggless chocolate cake chahiye.');
  Position? position;
  bool busy = false;
  String? error;
  Future<void> locate() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      setState(() {
        error =
            'Linux desktop has no GPS provider; using KMIT demo coordinates. Android uses live GPS.';
      });
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() =>
          error = 'Location permission denied; using KMIT demo coordinates.');
      return;
    }
    final p = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high));
    setState(() => position = p);
  }

  Future<void> search() async {
    setState(() {
      busy = true;
      error = null;
    });
    final loc = {
      'lat': position?.latitude ?? 17.397,
      'lng': position?.longitude ?? 78.490
    };
    try {
      final parsedRes = await http.post(Uri.parse('$apiBase/api/intents/parse'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text.text, 'location': loc}));
      if (parsedRes.statusCode != 200) {
        throw Exception('Intent service returned ${parsedRes.statusCode}');
      }
      final parsed = jsonDecode(parsedRes.body);
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  ConfirmScreen(rawText: text.text, intent: parsed['parsed'])));
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const PaytmLogo(),
            actions: const [
              CircleAvatar(
                  radius: 19,
                  backgroundColor: Color(0xffEAF7FC),
                  child: Text('SS',
                      style: TextStyle(
                          color: navy, fontWeight: FontWeight.w900))),
              SizedBox(width: 18)
            ]),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 28), children: [
          const Text('Good afternoon',
              style: TextStyle(color: muted, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('What do you need today?',
              style: TextStyle(color: ink, fontSize: 31, height: 1.1, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xffE9F9FF), Color(0xffF6FCFF)]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xffCFEFF9))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.auto_awesome_rounded, color: paytmBlue, size: 20),
                SizedBox(width: 8),
                Text('ASK PAYTM', style: TextStyle(color: navy, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12)),
                Spacer(),
                StatusPill(label: 'AI', icon: Icons.bolt_rounded)
              ]),
              const SizedBox(height: 15),
              TextField(
                controller: text,
                maxLines: 4,
                minLines: 4,
                style: const TextStyle(color: ink, fontSize: 16, height: 1.45, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'Describe what you need, your budget and when you need it…',
                  contentPadding: EdgeInsets.all(17))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: locate,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: navy,
                    side: const BorderSide(color: Color(0xffC8EAF6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  icon: Icon(position == null ? Icons.near_me_outlined : Icons.location_on, size: 19),
                  label: Text(position == null ? 'Near KMIT' : 'GPS ready', overflow: TextOverflow.ellipsis))),
                const SizedBox(width: 10),
                Container(width: 48, height: 48,
                  decoration: const BoxDecoration(color: paytmBlue, shape: BoxShape.circle),
                  child: const Icon(Icons.mic_rounded, color: Colors.white))
              ]),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: busy ? null : search,
                icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_forward_rounded),
                label: Text(busy ? 'Understanding your request…' : 'Find it for me'))
            ]),
          ),
          const SizedBox(height: 22),
          const Text('Try asking for', style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _PromptChip('🎂  Custom cake', text),
            _PromptChip('📱  Phone repair', text),
            _PromptChip('🧵  Tailoring', text),
          ]),
          const SizedBox(height: 24),
          const Row(children: [
            Icon(Icons.shield_outlined, color: success, size: 19), SizedBox(width: 8),
            Expanded(child: Text('Only relevant merchants receive your request', style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w600)))
          ]),
          if (error != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ErrorNotice(error!)),
        ])),
      );
}

class ConfirmScreen extends StatefulWidget {
  final String rawText;
  final Map<String, dynamic> intent;
  const ConfirmScreen({super.key, required this.rawText, required this.intent});
  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  bool busy = false;
  String? error;
  Future<void> find() async {
    setState(() => busy = true);
    try {
      final r = await http.post(Uri.parse('$apiBase/api/intents'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'raw_text': widget.rawText, 'parsed': widget.intent}));
      if (r.statusCode != 200) {
        throw Exception('Router returned ${r.statusCode}');
      }
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => MatchesScreen(
                  intent: widget.intent, result: jsonDecode(r.body))));
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.intent;
    final attrs = (p['attributes'] as Map?)
            ?.values
            .where((v) => v != null && v != false)
            .toList() ??
        [];
    return Scaffold(
        appBar: AppBar(title: const PaytmLogo()),
        body: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
          const StepLabel(step: 'STEP 1 OF 3', label: 'INTENT PACKET'),
          const SizedBox(height: 12),
          const Text("Here’s what I understood",
              style: TextStyle(color: ink, fontSize: 29, height: 1.12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          const Text('Check the details before we contact nearby merchants.', style: TextStyle(color: muted, height: 1.4)),
          const SizedBox(height: 20),
          Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xffBDE9F7))),
              child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          CircleAvatar(radius: 20, backgroundColor: Color(0xffE5F8FE), child: Icon(Icons.shopping_bag_outlined, color: navy, size: 21)),
                          Spacer(), StatusPill(label: 'Structured', icon: Icons.check_circle_outline)
                        ]),
                        const SizedBox(height: 16),
                        Text(_title(p['item_or_service'] ?? 'Request'),
                            style: const TextStyle(color: ink, fontSize: 23, height: 1.15, fontWeight: FontWeight.w900)),
                        const Divider(height: 28, color: Color(0xffE6EDF4)),
                        ...attrs.map((x) => CheckFact('$x')),
                        if (p['budget_max'] != null)
                          CheckFact('Under ₹${p['budget_max']}'),
                        if (p['needed_by'] != null)
                          CheckFact('Needed by ${p['needed_by']}'),
                        CheckFact('Within ${p['radius_km']} km')
                      ]))),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xffEBF8FF), borderRadius: BorderRadius.circular(16)),
            child: const Row(children: [Icon(Icons.verified_user_outlined, color: navy, size: 20), SizedBox(width: 10), Expanded(child: Text('No order is placed until you choose and pay.', style: TextStyle(color: navy, fontWeight: FontWeight.w700, fontSize: 13)))])),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: busy ? null : find,
              icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.hub_outlined),
              label: Text(busy ? 'Routing intent…' : 'Find matching merchants')),
          if (error != null)
            Padding(padding: const EdgeInsets.only(top: 12), child: ErrorNotice(error!))
        ]));
  }
}

class MatchesScreen extends StatefulWidget {
  final Map<String, dynamic> intent, result;
  const MatchesScreen({super.key, required this.intent, required this.result});
  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  bool busy = false;
  String? error;
  Future<void> offers() async {
    setState(() => busy = true);
    try {
      final matches = (widget.result['matches'] as List).take(3).toList();
      final prices = [750, 700, 800];
      final times = ['18:30', '19:00', '18:00'];
      for (var i = 0; i < matches.length; i++) {
        final budget = widget.intent['budget_max'];
        final price = widget.intent['category'] == 'bakery'
            ? prices[i]
            : budget != null
                ? (budget * (.82 + i * .06)).round()
                : 500 + i * 100;
        await http.post(
            Uri.parse('$apiBase/api/merchant/${matches[i]['id']}/respond'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'intent_id': widget.result['id'],
              'can_fulfil': true,
              'price': price,
              'ready_at': times[i],
              'delivery': matches[i]['delivery']
            }));
      }
      final r = await http
          .get(Uri.parse('$apiBase/api/intents/${widget.result['id']}/offers'));
      if (r.statusCode != 200) throw Exception('Offers unavailable');
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OffersScreen(
                  offers: jsonDecode(r.body), intent: widget.intent)));
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = widget.result['matches'] as List;
    return Scaffold(
        appBar: AppBar(title: const PaytmLogo()),
        body: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
          const StepLabel(step: 'STEP 2 OF 3', label: 'MERCHANT MESH'),
          const SizedBox(height: 12),
          Text(widget.intent['item_or_service'] ?? 'Your request',
              style: const TextStyle(color: ink, fontSize: 28, height: 1.12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Row(children: [const Icon(Icons.location_on_outlined, color: muted, size: 17), const SizedBox(width: 4), Text('${widget.intent['radius_km']} km search radius', style: const TextStyle(color: muted)), const Spacer(), Text('${matches.length} likely matches', style: const TextStyle(color: success, fontWeight: FontWeight.w800, fontSize: 12))]),
          const SizedBox(height: 20),
          if (matches.isEmpty)
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                        'No exact match yet. Adjust a constraint or expand the radius.'))),
          ...matches.asMap().entries.map((entry) { final m = entry.value; return Card(
              child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                MerchantAvatar(name: '${m['name']}', index: entry.key),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text(m['name'], style: const TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w900))), const Icon(Icons.verified_rounded, color: success, size: 18)]),
                  const SizedBox(height: 5),
                  Text('${m['distance_km']} km  ·  ★ ${m['rating']}', style: const TextStyle(color: muted, fontSize: 13)),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: (m['match_score'] as num).toDouble(), minHeight: 5, color: paytmBlue, backgroundColor: const Color(0xffE8F1F6)))
                ])),
                const SizedBox(width: 10),
                Text('${(m['match_score'] * 100).round()}%', style: const TextStyle(color: navy, fontWeight: FontWeight.w900))
              ])));
          }),
          if (matches.isNotEmpty)
            FilledButton.icon(
                onPressed: busy ? null : offers,
                icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.notifications_active_outlined),
                label: Text(busy ? 'Waiting for merchant replies…' : 'Request live offers')),
          if (error != null)
            Padding(padding: const EdgeInsets.only(top: 12), child: ErrorNotice(error!))
        ]));
  }
}

class OffersScreen extends StatelessWidget {
  final List offers;
  final Map<String, dynamic> intent;
  const OffersScreen({super.key, required this.offers, required this.intent});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const PaytmLogo()),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
        const StepLabel(step: 'STEP 3 OF 3', label: 'LIVE OFFERS'),
        const SizedBox(height: 12),
        Text('${offers.length} businesses can fulfil your request',
            style: const TextStyle(color: ink, fontSize: 28, height: 1.12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        const Text('Ranked by fit, readiness and trust—not only price.', style: TextStyle(color: muted, height: 1.4)),
        const SizedBox(height: 18),
        ...offers.asMap().entries.map((entry) {
          final o = entry.value, m = o['merchant'];
          return Card(
              shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(
                      color: entry.key == 0 ? paytmBlue : const Color(0xffE5ECF4),
                      width: 2)),
              child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.key == 0)
                          const Padding(padding: EdgeInsets.only(bottom: 12), child: StatusPill(label: 'BEST MATCH', icon: Icons.auto_awesome_rounded)),
                        Row(
                            children: [
                              MerchantAvatar(name: '${m['name']}', index: entry.key),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m['name'], style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text('★ ${m['rating']}  ·  ${m['distance_km']} km', style: const TextStyle(color: muted, fontSize: 13))])),
                              Text('₹${o['price']}',
                                  style: const TextStyle(color: navy, fontSize: 25, fontWeight: FontWeight.w900))
                            ]),
                        const Divider(height: 25, color: Color(0xffE6EDF4)),
                        Row(children: [
                          Expanded(child: OfferFact(icon: Icons.schedule_rounded, label: 'READY BY', value: '${o['ready_at']}')),
                          Expanded(child: OfferFact(icon: o['delivery'] == true ? Icons.delivery_dining_outlined : Icons.storefront_outlined, label: 'FULFILMENT', value: o['delivery'] == true ? 'Delivery' : 'Pickup'))
                        ]),
                        const SizedBox(height: 15),
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => PaymentScreen(
                                            offer: o, intent: intent))),
                                style: FilledButton.styleFrom(backgroundColor: entry.key == 0 ? navy : const Color(0xffEAF7FC), foregroundColor: entry.key == 0 ? Colors.white : navy),
                                child: Text(entry.key == 0 ? 'Choose recommended' : 'Choose ${m['name']}')))
                      ])));
        })
      ]));
}

class PaymentScreen extends StatefulWidget {
  final Map offer, intent;
  const PaymentScreen({super.key, required this.offer, required this.intent});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool busy = false;
  String? error;
  Future<void> pay() async {
    setState(() => busy = true);
    try {
      await http.post(
          Uri.parse('$apiBase/api/offers/${widget.offer['id']}/accept'),
          headers: {'Content-Type': 'application/json'},
          body: '{}');
      final r = await http.post(Uri.parse('$apiBase/api/payments/simulate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'offer_id': widget.offer['id'], 'method': 'UPI •••• 4821'}));
      if (r.statusCode != 200) throw Exception('Payment failed');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => SuccessScreen(
                  payment: jsonDecode(r.body), intent: widget.intent)),
          (route) => route.isFirst);
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const PaytmLogo()),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
        const StepLabel(step: 'SECURE CHECKOUT', label: 'PAYTM PAYMENT'),
        const SizedBox(height: 12),
        const Text('Complete your payment',
            style: TextStyle(color: ink, fontSize: 29, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Review the merchant and amount before paying.', style: TextStyle(color: muted)),
        Container(
            margin: const EdgeInsets.symmetric(vertical: 22),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xff064B94), Color(0xff002970), Color(0xff001B4D)]),
                boxShadow: const [BoxShadow(color: Color(0x30002970), blurRadius: 24, offset: Offset(0, 12))],
                borderRadius: BorderRadius.circular(27)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [PaytmLogo(light: true), Spacer(), Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 19)]),
              const SizedBox(height: 28),
              const Text('PAYING TO', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(widget.offer['merchant']['name'],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('₹${widget.offer['price']}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 18),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              const Row(children: [Icon(Icons.account_balance_rounded, color: Colors.white70, size: 18), SizedBox(width: 8), Text('UPI  •••• 4821', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)), Spacer(), Icon(Icons.check_circle, color: Color(0xff5DE5B3), size: 19)])
            ])),
        Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xffE5ECF4))), child: const Row(children: [Icon(Icons.shield_outlined, color: success), SizedBox(width: 10), Expanded(child: Text('Protected by Paytm secure payment simulation', style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w600)))])),
        FilledButton.icon(
            onPressed: busy ? null : pay,
            icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.lock_rounded, size: 19),
            label: Text(busy ? 'Paying securely…' : 'Pay ₹${widget.offer['price']} securely')),
        if (error != null)
          Padding(padding: const EdgeInsets.only(top: 12), child: ErrorNotice(error!))
      ]));
}

class SuccessScreen extends StatelessWidget {
  final Map payment, intent;
  const SuccessScreen({super.key, required this.payment, required this.intent});
  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(
              child: ListView(padding: const EdgeInsets.fromLTRB(24, 26, 24, 28), children: [
        const Align(alignment: Alignment.centerLeft, child: PaytmLogo()),
        const SizedBox(height: 54),
        Center(child: Container(width: 92, height: 92, decoration: BoxDecoration(color: const Color(0xffE7FBF3), shape: BoxShape.circle, border: Border.all(color: const Color(0xffB9F0D9), width: 7)), child: const Icon(Icons.check_rounded, size: 52, color: success))),
        const SizedBox(height: 20),
        const Center(
            child: Text('PAYMENT SUCCESSFUL',
                style: TextStyle(
                    color: success, fontWeight: FontWeight.w900, letterSpacing: 1.1, fontSize: 12))),
        const Center(
            child: Text('Your order is confirmed',
                textAlign: TextAlign.center, style: TextStyle(color: ink, fontSize: 29, fontWeight: FontWeight.w900))),
        const SizedBox(height: 12),
        Center(
            child: Text(
                '${payment['merchant']['name']} received ₹${payment['amount']}.',
                textAlign: TextAlign.center)),
        const SizedBox(height: 25),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [ReceiptRow(label: 'Merchant', value: '${payment['merchant']['name']}'), const Divider(height: 24), ReceiptRow(label: 'Amount paid', value: '₹${payment['amount']}'), const Divider(height: 24), ReceiptRow(label: 'Status', value: 'Confirmed', valueColor: success)]))),
        const SizedBox(height: 8),
        FilledButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text('Done'))
      ])));
}

class PaytmLogo extends StatelessWidget {
  const PaytmLogo({super.key});
  @override
  Widget build(BuildContext context) => const Text.rich(TextSpan(children: [
        TextSpan(
            text: 'pay',
            style: TextStyle(
                color: navy, fontWeight: FontWeight.w900, fontSize: 23)),
        TextSpan(
            text: 'tm',
            style: TextStyle(
                color: paytmBlue, fontWeight: FontWeight.w900, fontSize: 23))
      ]));
}

class CheckFact extends StatelessWidget {
  final String text;
  const CheckFact(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(children: [
        const CircleAvatar(
            radius: 12,
            backgroundColor: Color(0xffe4faf2),
            child: Icon(Icons.check, size: 15, color: Color(0xff08a66c))),
        const SizedBox(width: 10),
        Expanded(child: Text(text))
      ]));
}
