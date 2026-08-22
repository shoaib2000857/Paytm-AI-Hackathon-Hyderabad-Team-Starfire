import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:record/record.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  runApp(const IntentMeshApp());
}

const configuredApiBase = String.fromEnvironment('API_BASE');
String get apiBase => configuredApiBase.isNotEmpty
    ? configuredApiBase
    : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';

const navy = Color(0xff002970);
const paytmBlue = Color(0xff00baf2);
const ink = Color(0xff101D33);
const muted = Color(0xff68758D);
const canvas = Color(0xffF5F8FC);
const success = Color(0xff00A86B);

Future<String> transcribeAudio(String path) async {
  final request = http.MultipartRequest(
      'POST', Uri.parse('$apiBase/api/speech/transcribe'));
  request.files.add(await http.MultipartFile.fromPath('audio', path));
  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);
  if (response.statusCode != 200) {
    throw Exception('Voice service returned ${response.statusCode}');
  }
  final transcript = '${jsonDecode(response.body)['transcript'] ?? ''}'.trim();
  if (transcript.isEmpty) throw Exception('No speech was detected');
  return transcript;
}

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
  final recorder = AudioRecorder();
  Position? position;
  bool recording = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    recorder.dispose();
    text.dispose();
    super.dispose();
  }

  Future<void> toggleVoice() async {
    try {
      if (recording) {
        final path = await recorder.stop();
        if (mounted) setState(() => recording = false);
        if (path == null) throw Exception('Audio recording was not saved');
        if (mounted) setState(() => busy = true);
        final transcript = await transcribeAudio(path);
        text.text = transcript;
        text.selection = TextSelection.collapsed(offset: text.text.length);
      } else {
        if (!await recorder.hasPermission()) {
          throw Exception('Microphone permission was denied');
        }
        final directory = await getTemporaryDirectory();
        await recorder.start(
            const RecordConfig(
                encoder: AudioEncoder.aacLc,
                bitRate: 128000,
                sampleRate: 44100),
            path:
                '${directory.path}/customer_${DateTime.now().millisecondsSinceEpoch}.m4a');
        if (mounted) setState(() => recording = true);
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted && !recording) setState(() => busy = false);
    }
  }

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
        appBar: AppBar(title: const PaytmLogo(), actions: const [
          CircleAvatar(
              radius: 19,
              backgroundColor: Color(0xffEAF7FC),
              child: Text('SS',
                  style: TextStyle(color: navy, fontWeight: FontWeight.w900))),
          SizedBox(width: 18)
        ]),
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
              const Text('Good afternoon',
                  style: TextStyle(
                      color: muted, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('What do you need today?',
                  style: TextStyle(
                      color: ink,
                      fontSize: 31,
                      height: 1.1,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xffE9F9FF), Color(0xffF6FCFF)]),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xffCFEFF9))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: paytmBlue, size: 20),
                        SizedBox(width: 8),
                        Text('ASK PAYTM',
                            style: TextStyle(
                                color: navy,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                fontSize: 12)),
                        Spacer(),
                        StatusPill(label: 'AI', icon: Icons.bolt_rounded)
                      ]),
                      const SizedBox(height: 15),
                      TextField(
                          controller: text,
                          maxLines: 4,
                          minLines: 4,
                          style: const TextStyle(
                              color: ink,
                              fontSize: 16,
                              height: 1.45,
                              fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                              hintText:
                                  'Describe what you need, your budget and when you need it…',
                              contentPadding: EdgeInsets.all(17))),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: OutlinedButton.icon(
                                onPressed: locate,
                                style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    foregroundColor: navy,
                                    side: const BorderSide(
                                        color: Color(0xffC8EAF6)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15))),
                                icon: Icon(
                                    position == null
                                        ? Icons.near_me_outlined
                                        : Icons.location_on,
                                    size: 19),
                                label: Text(
                                    position == null
                                        ? 'Near KMIT'
                                        : 'GPS ready',
                                    overflow: TextOverflow.ellipsis))),
                        const SizedBox(width: 10),
                        Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                                color: recording
                                    ? const Color(0xffE5484D)
                                    : paytmBlue,
                                shape: BoxShape.circle,
                                boxShadow: recording
                                    ? const [
                                        BoxShadow(
                                            color: Color(0x55E5484D),
                                            blurRadius: 14,
                                            spreadRadius: 3)
                                      ]
                                    : null),
                            child: IconButton(
                                onPressed:
                                    busy && !recording ? null : toggleVoice,
                                icon: Icon(
                                    recording
                                        ? Icons.stop_rounded
                                        : Icons.mic_rounded,
                                    color: Colors.white)))
                      ]),
                      if (recording)
                        const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Row(children: [
                              SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xffE5484D))),
                              SizedBox(width: 8),
                              Text('Listening… tap stop when finished',
                                  style: TextStyle(
                                      color: Color(0xffB43D42),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800))
                            ])),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                          onPressed: busy ? null : search,
                          icon: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.arrow_forward_rounded),
                          label: Text(busy
                              ? 'Understanding your request…'
                              : 'Find it for me'))
                    ]),
              ),
              const SizedBox(height: 22),
              const Text('Try asking for',
                  style: TextStyle(
                      color: ink, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _PromptChip('🎂  Custom cake', text),
                _PromptChip('📱  Phone repair', text),
                _PromptChip('🧵  Tailoring', text),
              ]),
              const SizedBox(height: 24),
              const Row(children: [
                Icon(Icons.shield_outlined, color: success, size: 19),
                SizedBox(width: 8),
                Expanded(
                    child: Text('Only relevant merchants receive your request',
                        style: TextStyle(
                            color: muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)))
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
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              const StepLabel(step: 'STEP 1 OF 3', label: 'INTENT PACKET'),
              const SizedBox(height: 12),
              const Text("Here’s what I understood",
                  style: TextStyle(
                      color: ink,
                      fontSize: 29,
                      height: 1.12,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              const Text(
                  'Check the details before we contact nearby merchants.',
                  style: TextStyle(color: muted, height: 1.4)),
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
                              CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Color(0xffE5F8FE),
                                  child: Icon(Icons.shopping_bag_outlined,
                                      color: navy, size: 21)),
                              Spacer(),
                              StatusPill(
                                  label: 'Structured',
                                  icon: Icons.check_circle_outline)
                            ]),
                            const SizedBox(height: 16),
                            Text(_title(p['item_or_service'] ?? 'Request'),
                                style: const TextStyle(
                                    color: ink,
                                    fontSize: 23,
                                    height: 1.15,
                                    fontWeight: FontWeight.w900)),
                            const Divider(height: 28, color: Color(0xffE6EDF4)),
                            ...attrs.map((x) => CheckFact('$x')),
                            if (p['budget_max'] != null)
                              CheckFact('Under ₹${p['budget_max']}'),
                            if (p['needed_by'] != null)
                              CheckFact('Needed by ${p['needed_by']}'),
                            CheckFact('Within ${p['radius_km']} km')
                          ]))),
              const SizedBox(height: 8),
              Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xffEBF8FF),
                      borderRadius: BorderRadius.circular(16)),
                  child: const Row(children: [
                    Icon(Icons.verified_user_outlined, color: navy, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            'No order is placed until you choose and pay.',
                            style: TextStyle(
                                color: navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)))
                  ])),
              const SizedBox(height: 16),
              FilledButton.icon(
                  onPressed: busy ? null : find,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.hub_outlined),
                  label: Text(
                      busy ? 'Routing intent…' : 'Find matching merchants')),
              if (error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ErrorNotice(error!))
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

  Future<void> openMerchant() async {
    final sent = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => MerchantSoundboxScreen(
                intent: widget.intent,
                intentId: '${widget.result['id']}',
                matches: widget.result['matches'] as List)));
    if (sent == true && mounted) await offers();
  }

  Future<void> offers() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await http
          .get(Uri.parse('$apiBase/api/intents/${widget.result['id']}/offers'));
      if (r.statusCode != 200) throw Exception('Offers unavailable');
      final received = jsonDecode(r.body) as List;
      if (received.isEmpty) {
        throw Exception(
            'No offer yet. Open the merchant Soundbox and send a response first.');
      }
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  OffersScreen(offers: received, intent: widget.intent)));
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
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              const StepLabel(step: 'STEP 2 OF 3', label: 'MERCHANT MESH'),
              const SizedBox(height: 12),
              Text(widget.intent['item_or_service'] ?? 'Your request',
                  style: const TextStyle(
                      color: ink,
                      fontSize: 28,
                      height: 1.12,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Row(children: [
                const Icon(Icons.location_on_outlined, color: muted, size: 17),
                const SizedBox(width: 4),
                Text('${widget.intent['radius_km']} km search radius',
                    style: const TextStyle(color: muted)),
                const Spacer(),
                Text('${matches.length} likely matches',
                    style: const TextStyle(
                        color: success,
                        fontWeight: FontWeight.w800,
                        fontSize: 12))
              ]),
              const SizedBox(height: 20),
              if (matches.isEmpty)
                const Card(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                            'No exact match yet. Adjust a constraint or expand the radius.'))),
              ...matches.asMap().entries.map((entry) {
                final m = entry.value;
                return Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          MerchantAvatar(
                              name: '${m['name']}', index: entry.key),
                          const SizedBox(width: 13),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Row(children: [
                                  Expanded(
                                      child: Text(m['name'],
                                          style: const TextStyle(
                                              color: ink,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900))),
                                  const Icon(Icons.verified_rounded,
                                      color: success, size: 18)
                                ]),
                                const SizedBox(height: 5),
                                Text(
                                    '${m['distance_km']} km  ·  ★ ${m['rating']}',
                                    style: const TextStyle(
                                        color: muted, fontSize: 13)),
                                const SizedBox(height: 8),
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                        value: (m['match_score'] as num)
                                            .toDouble(),
                                        minHeight: 5,
                                        color: paytmBlue,
                                        backgroundColor:
                                            const Color(0xffE8F1F6)))
                              ])),
                          const SizedBox(width: 10),
                          Text('${(m['match_score'] * 100).round()}%',
                              style: const TextStyle(
                                  color: navy, fontWeight: FontWeight.w900))
                        ])));
              }),
              if (matches.isNotEmpty)
                OutlinedButton.icon(
                    onPressed: busy ? null : openMerchant,
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        foregroundColor: navy,
                        side: const BorderSide(color: paytmBlue, width: 1.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17))),
                    icon: const Icon(Icons.speaker_phone_outlined),
                    label: const Text('Open merchant Soundbox',
                        style: TextStyle(fontWeight: FontWeight.w900))),
              if (matches.isNotEmpty) const SizedBox(height: 10),
              if (matches.isNotEmpty)
                FilledButton.icon(
                    onPressed: busy ? null : offers,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.notifications_active_outlined),
                    label: Text(busy
                        ? 'Waiting for merchant replies…'
                        : 'View received offers')),
              if (error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ErrorNotice(error!))
            ]));
  }
}

class MerchantSoundboxScreen extends StatefulWidget {
  final Map<String, dynamic> intent;
  final String intentId;
  final List matches;
  const MerchantSoundboxScreen(
      {super.key,
      required this.intent,
      required this.intentId,
      required this.matches});
  @override
  State<MerchantSoundboxScreen> createState() => _MerchantSoundboxScreenState();
}

class _MerchantSoundboxScreenState extends State<MerchantSoundboxScreen> {
  late Map merchant;
  late final TextEditingController price;
  late final TextEditingController ready;
  final recorder = AudioRecorder();
  bool delivery = false;
  bool busy = false;
  bool listening = false;
  bool negotiating = false;
  bool sent = false;
  bool declined = false;
  String transcript = '';
  String? error;

  @override
  void initState() {
    super.initState();
    merchant = widget.matches.first as Map;
    final budget = widget.intent['budget_max'];
    price = TextEditingController(
        text: widget.intent['category'] == 'bakery'
            ? '750'
            : '${budget == null ? 500 : ((budget as num) * .9).round()}');
    ready = TextEditingController(text: '18:30');
    delivery = merchant['delivery'] == true;
  }

  @override
  void dispose() {
    recorder.dispose();
    price.dispose();
    ready.dispose();
    super.dispose();
  }

  Future<void> toggleMerchantVoice() async {
    try {
      if (listening) {
        final path = await recorder.stop();
        if (mounted) {
          setState(() {
            listening = false;
            busy = true;
          });
        }
        if (path == null) throw Exception('Audio recording was not saved');
        final spoken = await transcribeAudio(path);
        final response = await http.post(
            Uri.parse('$apiBase/api/merchant-responses/parse'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': spoken}));
        if (response.statusCode != 200) {
          throw Exception('Offer extraction returned ${response.statusCode}');
        }
        final parsed = jsonDecode(response.body)['parsed'] as Map;
        if (mounted) {
          setState(() {
            transcript = spoken;
            negotiating = true;
            if (parsed['price'] != null) price.text = '${parsed['price']}';
            if (parsed['ready_at'] != null) {
              ready.text = '${parsed['ready_at']}';
            }
            delivery = parsed['delivery'] == true;
          });
        }
      } else {
        if (!await recorder.hasPermission()) {
          throw Exception('Microphone permission was denied');
        }
        final directory = await getTemporaryDirectory();
        await recorder.start(
            const RecordConfig(
                encoder: AudioEncoder.aacLc,
                bitRate: 128000,
                sampleRate: 44100),
            path:
                '${directory.path}/merchant_${DateTime.now().millisecondsSinceEpoch}.m4a');
        if (mounted) setState(() => listening = true);
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted && !listening) setState(() => busy = false);
    }
  }

  Future<void> respond(bool canFulfil) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await http.post(
          Uri.parse('$apiBase/api/merchant/${merchant['id']}/respond'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'intent_id': widget.intentId,
            'can_fulfil': canFulfil,
            'price': int.tryParse(price.text),
            'ready_at': ready.text,
            'delivery': delivery,
            'notes': negotiating ? 'Merchant negotiated this offer' : null
          }));
      if (response.statusCode != 200) {
        throw Exception('Merchant response failed (${response.statusCode})');
      }
      if (mounted) {
        setState(() {
          sent = true;
          declined = !canFulfil;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void changeMerchant(String? id) {
    final selected = widget.matches.firstWhere((m) => m['id'] == id) as Map;
    setState(() {
      merchant = selected;
      delivery = merchant['delivery'] == true;
      sent = false;
      declined = false;
      negotiating = false;
      transcript = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.intent;
    final attrs = (p['attributes'] as Map?)?.entries.where((entry) =>
            entry.value != null && entry.value != false && entry.value != '') ??
        const [];
    return Scaffold(
        backgroundColor: const Color(0xff111820),
        body: SafeArea(
            child: Center(
                child: Container(
                    margin: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: const Color(0xff202B36),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                            color: const Color(0xff384858), width: 2),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black54,
                              blurRadius: 30,
                              offset: Offset(0, 16))
                        ]),
                    child: Column(children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 12, 13),
                          child: Row(children: [
                            const PaytmLogo(light: true),
                            const SizedBox(width: 7),
                            const Text('SOUNDBOX',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w900)),
                            const Spacer(),
                            IconButton(
                                onPressed: () => Navigator.pop(context, sent),
                                icon: const Icon(Icons.close,
                                    color: Colors.white70))
                          ])),
                      Expanded(
                          child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                  color: canvas,
                                  borderRadius: BorderRadius.vertical(
                                      bottom: Radius.circular(29))),
                              child: sent
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                          CircleAvatar(
                                              radius: 40,
                                              backgroundColor: declined
                                                  ? const Color(0xffFFF1F1)
                                                  : const Color(0xffE7FBF3),
                                              child: Icon(
                                                  declined
                                                      ? Icons.close_rounded
                                                      : Icons.check_rounded,
                                                  color: declined
                                                      ? const Color(0xffC63D3D)
                                                      : success,
                                                  size: 46)),
                                          const SizedBox(height: 18),
                                          Text(
                                              declined
                                                  ? 'Request declined'
                                                  : 'Offer sent live',
                                              style: const TextStyle(
                                                  color: ink,
                                                  fontSize: 27,
                                                  fontWeight: FontWeight.w900)),
                                          const SizedBox(height: 8),
                                          Text(
                                              declined
                                                  ? 'Intent Mesh will continue with other capable merchants.'
                                                  : 'The customer can now see ${merchant['name']} at ₹${price.text}.',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: muted, height: 1.4)),
                                          const SizedBox(height: 22),
                                          FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
                                                  'Return to customer'))
                                        ])
                                  : ListView(children: [
                                      Row(children: [
                                        const Expanded(
                                            child: StepLabel(
                                                step: 'HIGH INTENT',
                                                label: 'NEW REQUEST')),
                                        const SizedBox(width: 8),
                                        Container(
                                            width: 9,
                                            height: 9,
                                            decoration: const BoxDecoration(
                                                color: success,
                                                shape: BoxShape.circle))
                                      ]),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                          initialValue: '${merchant['id']}',
                                          decoration: const InputDecoration(
                                              labelText: 'Responding as',
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 10)),
                                          items: widget.matches
                                              .map((m) => DropdownMenuItem(
                                                  value: '${m['id']}',
                                                  child: Text('${m['name']}')))
                                              .toList(),
                                          onChanged: changeMerchant),
                                      const SizedBox(height: 14),
                                      Card(
                                          child: Padding(
                                              padding: const EdgeInsets.all(17),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        _title(
                                                            '${p['item_or_service'] ?? 'Customer request'}'),
                                                        style: const TextStyle(
                                                            color: ink,
                                                            fontSize: 21,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w900)),
                                                    const SizedBox(height: 10),
                                                    ...attrs.map((entry) =>
                                                        CheckFact(
                                                            '${_title('${entry.key}')} · ${entry.value}')),
                                                    if (p['budget_max'] != null)
                                                      CheckFact(
                                                          'Customer budget up to ₹${p['budget_max']}'),
                                                    if (p['needed_by'] != null)
                                                      CheckFact(
                                                          'Needed ${p['needed_by']}')
                                                  ]))),
                                      const SizedBox(height: 4),
                                      OutlinedButton.icon(
                                          onPressed: busy && !listening
                                              ? null
                                              : toggleMerchantVoice,
                                          style: OutlinedButton.styleFrom(
                                              minimumSize:
                                                  const Size.fromHeight(52),
                                              foregroundColor: navy,
                                              side: const BorderSide(
                                                  color: Color(0xffBDDCE9)),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16))),
                                          icon: Icon(listening
                                              ? Icons.stop_rounded
                                              : Icons
                                                  .record_voice_over_outlined),
                                          label: Text(listening
                                              ? 'Listening… tap to stop'
                                              : 'Speak your offer')),
                                      if (transcript.isNotEmpty)
                                        Container(
                                            margin:
                                                const EdgeInsets.only(top: 10),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                                color: const Color(0xffE9F9FF),
                                                borderRadius:
                                                    BorderRadius.circular(14)),
                                            child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(
                                                      Icons.graphic_eq_rounded,
                                                      color: paytmBlue,
                                                      size: 20),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                      child: Text(transcript,
                                                          style:
                                                              const TextStyle(
                                                                  color: ink,
                                                                  height: 1.35,
                                                                  fontSize:
                                                                      12)))
                                                ])),
                                      TextButton(
                                          onPressed: () => setState(
                                              () => negotiating = !negotiating),
                                          child: Text(negotiating
                                              ? 'Hide manual controls'
                                              : 'Or edit offer manually')),
                                      if (negotiating) ...[
                                        const SizedBox(height: 12),
                                        Row(children: [
                                          Expanded(
                                              child: TextField(
                                                  controller: price,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration:
                                                      const InputDecoration(
                                                          labelText: 'Price ₹',
                                                          prefixText: '₹ '))),
                                          const SizedBox(width: 10),
                                          Expanded(
                                              child: TextField(
                                                  controller: ready,
                                                  decoration: const InputDecoration(
                                                      labelText: 'Ready by',
                                                      prefixIcon: Icon(Icons
                                                          .schedule_outlined))))
                                        ]),
                                        SwitchListTile.adaptive(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text(
                                                'Delivery available',
                                                style: TextStyle(
                                                    color: ink,
                                                    fontWeight:
                                                        FontWeight.w800)),
                                            subtitle: const Text(
                                                'Otherwise customer will pick up',
                                                style: TextStyle(
                                                    color: muted,
                                                    fontSize: 12)),
                                            activeTrackColor: paytmBlue,
                                            value: delivery,
                                            onChanged: (value) => setState(
                                                () => delivery = value))
                                      ],
                                      const SizedBox(height: 12),
                                      FilledButton.icon(
                                          onPressed:
                                              busy ? null : () => respond(true),
                                          icon: busy
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white))
                                              : const Icon(Icons.send_rounded),
                                          label: Text(negotiating
                                              ? 'Send ₹${price.text} offer'
                                              : 'Accept and send offer')),
                                      const SizedBox(height: 8),
                                      TextButton(
                                          onPressed: busy
                                              ? null
                                              : () => respond(false),
                                          child: const Text("Can't fulfil")),
                                      if (error != null) ErrorNotice(error!)
                                    ])))
                    ])))));
  }
}

class OffersScreen extends StatelessWidget {
  final List offers;
  final Map<String, dynamic> intent;
  const OffersScreen({super.key, required this.offers, required this.intent});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const PaytmLogo()),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const StepLabel(step: 'STEP 3 OF 3', label: 'LIVE OFFERS'),
            const SizedBox(height: 12),
            Text('${offers.length} businesses can fulfil your request',
                style: const TextStyle(
                    color: ink,
                    fontSize: 28,
                    height: 1.12,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            const Text('Ranked by fit, readiness and trust—not only price.',
                style: TextStyle(color: muted, height: 1.4)),
            const SizedBox(height: 18),
            ...offers.asMap().entries.map((entry) {
              final o = entry.value, m = o['merchant'];
              return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(
                          color: entry.key == 0
                              ? paytmBlue
                              : const Color(0xffE5ECF4),
                          width: 2)),
                  child: Padding(
                      padding: const EdgeInsets.all(17),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (entry.key == 0)
                              const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: StatusPill(
                                      label: 'BEST MATCH',
                                      icon: Icons.auto_awesome_rounded)),
                            Row(children: [
                              MerchantAvatar(
                                  name: '${m['name']}', index: entry.key),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(m['name'],
                                        style: const TextStyle(
                                            color: ink,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 3),
                                    Text(
                                        '★ ${m['rating']}  ·  ${m['distance_km']} km',
                                        style: const TextStyle(
                                            color: muted, fontSize: 13))
                                  ])),
                              Text('₹${o['price']}',
                                  style: const TextStyle(
                                      color: navy,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900))
                            ]),
                            const Divider(height: 25, color: Color(0xffE6EDF4)),
                            Row(children: [
                              Expanded(
                                  child: OfferFact(
                                      icon: Icons.schedule_rounded,
                                      label: 'READY BY',
                                      value: '${o['ready_at']}')),
                              Expanded(
                                  child: OfferFact(
                                      icon: o['delivery'] == true
                                          ? Icons.delivery_dining_outlined
                                          : Icons.storefront_outlined,
                                      label: 'FULFILMENT',
                                      value: o['delivery'] == true
                                          ? 'Delivery'
                                          : 'Pickup'))
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
                                    style: FilledButton.styleFrom(
                                        backgroundColor: entry.key == 0
                                            ? navy
                                            : const Color(0xffEAF7FC),
                                        foregroundColor: entry.key == 0
                                            ? Colors.white
                                            : navy),
                                    child: Text(entry.key == 0
                                        ? 'Choose recommended'
                                        : 'Choose ${m['name']}')))
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
  String paymentMode = 'full';

  int get total => (widget.offer['price'] as num).round();
  int get payNow => paymentMode == 'split' ? (total / 2).ceil() : total;
  int get remaining => total - payNow;

  Future<void> pay() async {
    setState(() => busy = true);
    try {
      await http.post(
          Uri.parse('$apiBase/api/offers/${widget.offer['id']}/accept'),
          headers: {'Content-Type': 'application/json'},
          body: '{}');
      final r = await http.post(Uri.parse('$apiBase/api/payments/simulate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'offer_id': widget.offer['id'],
            'method': paymentMode == 'qr'
                ? 'Paytm QR'
                : paymentMode == 'split'
                    ? 'Pay Aadha · UPI •••• 4821'
                    : 'UPI •••• 4821',
            'payment_plan': paymentMode == 'split' ? 'split' : 'full',
            'amount': payNow
          }));
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
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const StepLabel(step: 'SECURE CHECKOUT', label: 'PAYTM PAYMENT'),
            const SizedBox(height: 12),
            const Text('Complete your payment',
                style: TextStyle(
                    color: ink, fontSize: 29, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Review the merchant and amount before paying.',
                style: TextStyle(color: muted)),
            const SizedBox(height: 18),
            const Text('Choose how to pay',
                style: TextStyle(
                    color: ink, fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            PaymentOption(
                selected: paymentMode == 'full',
                icon: Icons.account_balance_rounded,
                title: 'Pay full with UPI',
                subtitle: 'Pay ₹$total now · UPI •••• 4821',
                onTap: () => setState(() => paymentMode = 'full')),
            PaymentOption(
                selected: paymentMode == 'qr',
                icon: Icons.qr_code_2_rounded,
                title: 'Scan Paytm QR',
                subtitle: 'Scan from another UPI app or device',
                onTap: () => setState(() => paymentMode = 'qr')),
            PaymentOption(
                selected: paymentMode == 'split',
                icon: Icons.handshake_outlined,
                badge: 'NEW',
                title: 'Pay Aadha',
                subtitle: '₹$payNow now · ₹$remaining after fulfilment',
                onTap: () => setState(() => paymentMode = 'split')),
            if (paymentMode == 'qr')
              Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xffDDE8F0))),
                  child: Column(children: [
                    QrImageView(
                        data:
                            'upi://pay?pa=paytm.intentmesh@paytm&pn=${Uri.encodeComponent('${widget.offer['merchant']['name']}')}&am=$total&cu=INR&tn=${widget.offer['id']}',
                        version: QrVersions.auto,
                        size: 178,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square, color: navy),
                        dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: ink)),
                    const SizedBox(height: 9),
                    const Text('Scan using any UPI app',
                        style:
                            TextStyle(color: ink, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text('Intent order · ${widget.offer['id']}',
                        style: const TextStyle(color: muted, fontSize: 11))
                  ])),
            if (paymentMode == 'split')
              Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xffFFF8E8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xffF3DDA4))),
                  child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Color(0xff9B6900), size: 20),
                        SizedBox(width: 9),
                        Expanded(
                            child: Text(
                                'The remaining half becomes due only after pickup or delivery is confirmed. Prototype milestone payment—no real escrow.',
                                style: TextStyle(
                                    color: Color(0xff77540A),
                                    height: 1.4,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)))
                      ])),
            Container(
                margin: const EdgeInsets.symmetric(vertical: 22),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xff064B94),
                          Color(0xff002970),
                          Color(0xff001B4D)
                        ]),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x30002970),
                          blurRadius: 24,
                          offset: Offset(0, 12))
                    ],
                    borderRadius: BorderRadius.circular(27)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        PaytmLogo(light: true),
                        Spacer(),
                        Icon(Icons.lock_outline_rounded,
                            color: Colors.white70, size: 19)
                      ]),
                      const SizedBox(height: 28),
                      const Text('PAYING TO',
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(widget.offer['merchant']['name'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text('₹$payNow',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 18),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(
                            paymentMode == 'qr'
                                ? Icons.qr_code_2_rounded
                                : paymentMode == 'split'
                                    ? Icons.handshake_outlined
                                    : Icons.account_balance_rounded,
                            color: Colors.white70,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(
                            paymentMode == 'qr'
                                ? 'PAYTM QR'
                                : paymentMode == 'split'
                                    ? 'PAY AADHA · 50% NOW'
                                    : 'UPI  •••• 4821',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(Icons.check_circle,
                            color: Color(0xff5DE5B3), size: 19)
                      ])
                    ])),
            Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffE5ECF4))),
                child: const Row(children: [
                  Icon(Icons.shield_outlined, color: success),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          'Protected by Paytm secure payment simulation',
                          style: TextStyle(
                              color: muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)))
                ])),
            FilledButton.icon(
                onPressed: busy ? null : pay,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_rounded, size: 19),
                label: Text(busy
                    ? 'Paying securely…'
                    : paymentMode == 'qr'
                        ? 'I have paid ₹$total'
                        : 'Pay ₹$payNow securely')),
            if (error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ErrorNotice(error!))
          ]));
}

class SuccessScreen extends StatelessWidget {
  final Map payment, intent;
  const SuccessScreen({super.key, required this.payment, required this.intent});
  @override
  Widget build(BuildContext context) {
    final split = payment['payment_plan'] == 'split';
    return Scaffold(
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                children: [
          const Align(alignment: Alignment.centerLeft, child: PaytmLogo()),
          const SizedBox(height: 54),
          Center(
              child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                      color: const Color(0xffE7FBF3),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xffB9F0D9), width: 7)),
                  child: const Icon(Icons.check_rounded,
                      size: 52, color: success))),
          const SizedBox(height: 20),
          Center(
              child: Text(split ? 'ADVANCE PAID' : 'PAYMENT SUCCESSFUL',
                  style: const TextStyle(
                      color: success,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      fontSize: 12))),
          Center(
              child: Text(
                  split ? 'Your order is reserved' : 'Your order is confirmed',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: ink, fontSize: 29, fontWeight: FontWeight.w900))),
          const SizedBox(height: 12),
          Center(
              child: Text(
                  '${payment['merchant']['name']} received ₹${payment['amount']}.',
                  textAlign: TextAlign.center)),
          const SizedBox(height: 25),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    ReceiptRow(
                        label: 'Merchant',
                        value: '${payment['merchant']['name']}'),
                    const Divider(height: 24),
                    ReceiptRow(
                        label: 'Amount paid', value: '₹${payment['amount']}'),
                    if (split) ...[
                      const Divider(height: 24),
                      ReceiptRow(
                          label: 'Due after fulfilment',
                          value: '₹${payment['remaining']}')
                    ],
                    const Divider(height: 24),
                    ReceiptRow(
                        label: 'Status',
                        value: split ? 'Advance confirmed' : 'Confirmed',
                        valueColor: success)
                  ]))),
          Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xffE9F9FF), Color(0xffF8FCFF)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xffCDECF7))),
              child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.hub_outlined, color: navy, size: 20),
                      SizedBox(width: 8),
                      Text('THE MESH JUST LEARNED',
                          style: TextStyle(
                              color: navy,
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w900))
                    ]),
                    SizedBox(height: 8),
                    Text(
                        'This fulfilment strengthens the merchant’s capability and reliability signals for future requests.',
                        style:
                            TextStyle(color: muted, height: 1.4, fontSize: 13))
                  ])),
          OutlinedButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => OpportunityPulseScreen(
                          merchantId:
                              '${payment['merchant']['id'] ?? 'M001'}'))),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: navy,
                  side: const BorderSide(color: Color(0xffBDDCE9)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17))),
              icon: const Icon(Icons.insights_outlined),
              label: const Text('View Opportunity Pulse',
                  style: TextStyle(fontWeight: FontWeight.w800))),
          const SizedBox(height: 8),
          FilledButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('Done'))
        ])));
  }
}

class OpportunityPulseScreen extends StatefulWidget {
  final String merchantId;
  const OpportunityPulseScreen({super.key, required this.merchantId});
  @override
  State<OpportunityPulseScreen> createState() => _OpportunityPulseScreenState();
}

class _OpportunityPulseScreenState extends State<OpportunityPulseScreen> {
  Map<String, dynamic>? data;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await http.get(Uri.parse(
          '$apiBase/api/merchant/${widget.merchantId}/opportunities'));
      if (response.statusCode != 200) {
        throw Exception('Opportunity service returned ${response.statusCode}');
      }
      if (mounted) setState(() => data = jsonDecode(response.body));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = data;
    final trends = (d?['trends'] as List?) ?? [];
    return Scaffold(
        appBar: AppBar(title: const PaytmLogo()),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              const StepLabel(
                  step: 'MERCHANT INTELLIGENCE', label: 'OPPORTUNITY PULSE'),
              const SizedBox(height: 12),
              const Text('Demand around you',
                  style: TextStyle(
                      color: ink,
                      fontSize: 29,
                      height: 1.1,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              const Text(
                  'Real requests customers made—not demand inferred from transactions.',
                  style: TextStyle(color: muted, height: 1.4)),
              const SizedBox(height: 20),
              if (d == null && error == null)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(50),
                        child: CircularProgressIndicator(color: paytmBlue))),
              if (error != null) ErrorNotice(error!),
              if (d != null) ...[
                Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xff064B94), navy]),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x26002970),
                              blurRadius: 24,
                              offset: Offset(0, 12))
                        ]),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const StatusPill(
                                label: 'THIS WEEK',
                                icon: Icons.calendar_today_outlined),
                            const Spacer(),
                            Icon(Icons.waves_rounded,
                                color: Colors.white.withValues(alpha: .75))
                          ]),
                          const SizedBox(height: 24),
                          Text('${d['requests']}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  height: 1,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 5),
                          const Text('nearby requests detected',
                              style: TextStyle(color: Colors.white70)),
                          const Divider(height: 30, color: Colors.white24),
                          Text('₹${d['potential_demand']}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900)),
                          const Text('potential unmet demand',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 12))
                        ])),
                const SizedBox(height: 20),
                const Text('What customers are asking for',
                    style: TextStyle(
                        color: ink, fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                ...trends.asMap().entries.map((entry) {
                  final trend = entry.value as Map<String, dynamic>;
                  return Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Container(
                                width: 45,
                                height: 45,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: entry.key == 0
                                        ? const Color(0xffFFF0E5)
                                        : const Color(0xffE9F8FE),
                                    borderRadius: BorderRadius.circular(14)),
                                child: Text(entry.key == 0 ? '🔥' : '↗',
                                    style: const TextStyle(fontSize: 19))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('${trend['label']}',
                                      style: const TextStyle(
                                          color: ink,
                                          fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${trend['count']} requests · ${trend['unfulfilled']} unfulfilled',
                                      style: const TextStyle(
                                          color: muted, fontSize: 12))
                                ])),
                            Text('↑ ${trend['change']}%',
                                style: const TextStyle(
                                    color: success,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900))
                          ])));
                }),
                const SizedBox(height: 4),
                FilledButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Capability added to your Merchant Mesh profile'))),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add high-demand capability')),
                const SizedBox(height: 12),
                const Center(
                    child: Text('Intent → Fulfilment → Learning → Opportunity',
                        style: TextStyle(
                            color: muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)))
              ]
            ]));
  }
}

class PaytmLogo extends StatelessWidget {
  final bool light;
  const PaytmLogo({super.key, this.light = false});
  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(children: [
        TextSpan(
            text: 'pay',
            style: TextStyle(
                color: light ? Colors.white : navy,
                fontWeight: FontWeight.w900,
                fontSize: 23)),
        const TextSpan(
            text: 'tm',
            style: TextStyle(
                color: paytmBlue, fontWeight: FontWeight.w900, fontSize: 23))
      ]));
}

String _title(String value) => value
    .split('_')
    .map((word) =>
        word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

class _PromptChip extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _PromptChip(this.label, this.controller);
  @override
  Widget build(BuildContext context) => ActionChip(
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xffE0E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      label: Text(label,
          style: const TextStyle(
              color: ink, fontSize: 12, fontWeight: FontWeight.w700)),
      onPressed: () {
        if (label.contains('Phone')) {
          controller.text =
              'iPhone 15 screen aaj replace karwana hai, ₹4000 ke andar.';
        } else if (label.contains('Tailoring')) {
          controller.text =
              'Blouse Saturday tak stitch chahiye, budget ₹900, ek alteration included.';
        } else {
          controller.text =
              'Mujhe kal 7 baje tak ₹800 ke andar 1 kg eggless chocolate cake chahiye.';
        }
      });
}

class StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  const StatusPill({super.key, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xffE6F8FE),
          borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: navy),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: navy, fontSize: 10, fontWeight: FontWeight.w900))
      ]));
}

class StepLabel extends StatelessWidget {
  final String step, label;
  const StepLabel({super.key, required this.step, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xff138AB5),
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w900)),
        const Spacer(),
        Text(step,
            style: const TextStyle(
                color: muted, fontSize: 10, fontWeight: FontWeight.w800))
      ]);
}

class MerchantAvatar extends StatelessWidget {
  final String name;
  final int index;
  const MerchantAvatar({super.key, required this.name, required this.index});
  @override
  Widget build(BuildContext context) {
    const colors = [Color(0xffE5F8FE), Color(0xffFFF3DB), Color(0xffF1EAFE)];
    return Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: colors[index % colors.length],
            borderRadius: BorderRadius.circular(15)),
        child: Text(name.isEmpty ? 'M' : name[0].toUpperCase(),
            style: const TextStyle(
                color: navy, fontSize: 18, fontWeight: FontWeight.w900)));
  }
}

class OfferFact extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const OfferFact(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: navy, size: 20),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: muted, fontSize: 9, fontWeight: FontWeight.w800)),
          Text(value,
              style: const TextStyle(
                  color: ink, fontSize: 13, fontWeight: FontWeight.w800))
        ])
      ]);
}

class ReceiptRow extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const ReceiptRow(
      {super.key,
      required this.label,
      required this.value,
      this.valueColor = ink});
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(label, style: const TextStyle(color: muted)),
        const Spacer(),
        Text(value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.w900))
      ]);
}

class PaymentOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title, subtitle;
  final String? badge;
  final VoidCallback onTap;
  const PaymentOption(
      {super.key,
      required this.selected,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.badge});
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
              color: selected ? paytmBlue : const Color(0xffE1E9F0),
              width: selected ? 1.8 : 1)),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xffE5F8FE)
                            : const Color(0xffF2F5F8),
                        borderRadius: BorderRadius.circular(13)),
                    child: Icon(icon, color: selected ? navy : muted)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Flexible(
                            child: Text(title,
                                style: const TextStyle(
                                    color: ink,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900))),
                        if (badge != null) ...[
                          const SizedBox(width: 7),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                  color: const Color(0xffE7FBF3),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(badge!,
                                  style: const TextStyle(
                                      color: success,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900)))
                        ]
                      ]),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: const TextStyle(color: muted, fontSize: 12))
                    ])),
                Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? paytmBlue : const Color(0xffB9C4CE))
              ]))));
}

class ErrorNotice extends StatelessWidget {
  final String message;
  const ErrorNotice(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: const Color(0xffFFF1F1),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Color(0xffC63D3D), size: 19),
        const SizedBox(width: 9),
        Expanded(
            child: Text(message,
                style: const TextStyle(color: Color(0xff9D3030), fontSize: 12)))
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
            child: Icon(Icons.check, size: 15, color: success)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style:
                    const TextStyle(color: ink, fontWeight: FontWeight.w600)))
      ]));
}
