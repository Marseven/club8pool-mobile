import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class LiveMatchScreen extends StatefulWidget {
  final Map match;
  const LiveMatchScreen({super.key, required this.match});

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  late Map _match;
  int _shotClock = 30;
  Timer? _shotTimer;
  Timer? _uiTimer;

  // ── Controllable chrono ────────────────────────────────────────
  Duration _chronoBase  = Duration.zero;
  DateTime? _chronoStart;

  bool get _chronoRunning => _chronoStart != null;

  Duration get _elapsed {
    if (_chronoStart != null) {
      return _chronoBase + DateTime.now().difference(_chronoStart!);
    }
    return _chronoBase;
  }

  void _chronoPlay() {
    if (_chronoRunning) return;
    setState(() => _chronoStart = DateTime.now());
  }

  void _chronoPause() {
    if (!_chronoRunning) return;
    setState(() {
      _chronoBase  = _elapsed;
      _chronoStart = null;
    });
  }

  void _chronoReset() => setState(() {
    _chronoBase  = Duration.zero;
    _chronoStart = null;
  });

  String _fmtChrono() {
    final d = _elapsed;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  // ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _match = Map.from(widget.match);

    _shotTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _shotClock = _shotClock <= 0 ? 30 : _shotClock - 1);
    });
    _uiTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_chronoRunning && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _shotTimer?.cancel();
    _uiTimer?.cancel();
    super.dispose();
  }

  bool get _danger => _shotClock <= 10;

  Future<void> _winFrame(String winner) async {
    setState(() {
      if (winner == 'A') {
        _match['score_a'] = (_match['score_a'] ?? 0) + 1;
      } else {
        _match['score_b'] = (_match['score_b'] ?? 0) + 1;
      }
    });
    // Reset shot clock on each frame
    setState(() => _shotClock = 30);
    try {
      final api = await ApiService.create();
      await api.frame(_match['id'], winner);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pa = _match['player_a'];
    final pb = _match['player_b'];
    final scoreA = _match['score_a'] ?? 0;
    final scoreB = _match['score_b'] ?? 0;
    final pool = _match['pool'];
    final raceTo = _match['phase'] == 'knockout'
        ? (_match['competition']?['knockout_race_to'] ?? _match['competition']?['race_to'] ?? 7)
        : (_match['competition']?['pool_race_to'] ?? _match['competition']?['race_to'] ?? 3);

    return Scaffold(
      backgroundColor: C8P.ink,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back, color: C8P.mute, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Column(children: [
                    Text(
                      '${pool?['name'] ?? _match['round'] ?? '—'} · ${_match['table']?['name']?.toString().toUpperCase() ?? 'TABLE —'}',
                      style: C8PTypo.mono(size: 9, letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _match['competition']?['name'] ?? '',
                      style: C8PTypo.sans(size: 13, weight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0x142DA876),
                      border: Border.all(color: const Color(0x662DA876)),
                    ),
                    child: Text('● LIVE', style: C8PTypo.mono(size: 9, color: C8P.felt2, letterSpacing: 0.14)),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: C8P.line),

            // ── Shot clock ─────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: _danger ? const Color(0x0FE5484D) : Colors.transparent,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('SHOT CLOCK', style: C8PTypo.mono(size: 9, letterSpacing: 0.2)),
                  Text(_danger ? 'WARNING' : 'NORMAL',
                       style: C8PTypo.mono(size: 9, color: _danger ? C8P.live : C8P.mute, letterSpacing: 0.18)),
                ]),
                Text(_shotClock.toString().padLeft(2, '0'),
                     style: C8PTypo.disp(size: 110, color: _danger ? C8P.live : C8P.chalk)),
                Container(
                  height: 4, color: C8P.line,
                  child: Row(children: [
                    Expanded(flex: _shotClock,
                        child: Container(color: _danger ? C8P.live : C8P.felt2)),
                    Expanded(flex: 30 - _shotClock, child: Container()),
                  ]),
                ),
                const SizedBox(height: 6),
                Text(
                  'FRAME ${scoreA + scoreB + 1} · RACE TO $raceTo',
                  style: C8PTypo.mono(size: 10, letterSpacing: 0.14),
                ),
              ]),
            ),
            Container(height: 1, color: C8P.line),

            // ── Players ────────────────────────────────────────────
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: _playerCell(pa, scoreA, scoreA > scoreB)),
                Container(width: 1, color: C8P.line),
                Expanded(child: _playerCell(pb, scoreB, scoreB > scoreA)),
              ]),
            ),
            Container(height: 1, color: C8P.line),

            // ── Frame scoring ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _winFrame('A'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C8P.felt2, foregroundColor: C8P.ink,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: Text('+ FRAME · ${pa?['last_name']}',
                           style: C8PTypo.sans(size: 12, color: C8P.ink, weight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _winFrame('B'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: C8P.lineStrong),
                        backgroundColor: const Color(0x0FFFFFFF),
                        foregroundColor: C8P.chalk,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: Text('+ FRAME · ${pb?['last_name']}',
                           style: C8PTypo.sans(size: 12, color: C8P.chalk, weight: FontWeight.w700)),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _smallBtn('Faute'),
                  const SizedBox(width: 8),
                  _smallBtn('Black foul'),
                  const SizedBox(width: 8),
                  _smallBtn('Empoche 8'),
                ]),
              ]),
            ),

            // ── Chrono controls ────────────────────────────────────
            Container(height: 1, color: C8P.line),
            Container(
              color: C8P.ink2,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(children: [
                Row(children: [
                  Text('CHRONOMÈTRE', style: C8PTypo.mono(size: 9, letterSpacing: 0.2)),
                  const Spacer(),
                  // Reset
                  GestureDetector(
                    onTap: _chronoReset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: C8P.lineStrong),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text('↺ RÉINIT', style: C8PTypo.mono(size: 9, color: C8P.mute, letterSpacing: 0.1)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Play / Pause
                  GestureDetector(
                    onTap: _chronoRunning ? _chronoPause : _chronoPlay,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _chronoRunning ? const Color(0x14E5484D) : const Color(0x142DA876),
                        border: Border.all(
                          color: _chronoRunning ? const Color(0x66E5484D) : const Color(0x662DA876),
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        _chronoRunning ? '‖ PAUSE' : (_elapsed > Duration.zero ? '▶ REPRENDRE' : '▶ LANCER'),
                        style: C8PTypo.mono(size: 9, letterSpacing: 0.1,
                            color: _chronoRunning ? C8P.live : C8P.felt2)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ]),
                // Big timer display
                Text(
                  _fmtChrono(),
                  style: C8PTypo.disp(size: 52, color: _chronoRunning ? C8P.chalk : C8P.mute),
                ),
              ]),
            ),

            // ── FIN DE MATCH ───────────────────────────────────────
            Container(
              color: C8P.ink2,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/end', arguments: _match),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: C8P.felt2),
                    foregroundColor: C8P.felt2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text('FIN DE MATCH',
                       style: C8PTypo.sans(size: 12, color: C8P.felt2, weight: FontWeight.w700)
                           .copyWith(letterSpacing: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerCell(Map? p, int score, bool winning) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SEED #${p?['id']}', style: C8PTypo.mono(size: 9)),
      const SizedBox(height: 6),
      Text(
        '${p?['first_name']}\n${p?['last_name']}',
        style: C8PTypo.sans(size: 12, weight: FontWeight.w700).copyWith(height: 1.1),
      ),
      const SizedBox(height: 4),
      Text(score.toString(),
           style: C8PTypo.disp(size: 72, color: winning ? C8P.felt2 : C8P.chalk)),
    ]),
  );

  Widget _smallBtn(String l) => Expanded(
    child: OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0x1FFFFFFF)),
        foregroundColor: C8P.mute,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(l, style: C8PTypo.sans(size: 11, color: C8P.mute, weight: FontWeight.w600)),
    ),
  );
}
