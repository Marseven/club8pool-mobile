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
  int _matchSeconds = 0;
  Timer? _shotTimer;
  Timer? _matchTimer;

  @override
  void initState() {
    super.initState();
    _match = Map.from(widget.match);
    _shotTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _shotClock = _shotClock <= 0 ? 30 : _shotClock - 1);
    });
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _matchSeconds++);
    });
  }

  @override
  void dispose() {
    _shotTimer?.cancel();
    _matchTimer?.cancel();
    super.dispose();
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
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

    return Scaffold(
      backgroundColor: C8P.ink,
      body: SafeArea(
        child: Column(
          children: [
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
                  Column(
                    children: [
                      Text('${_match['round']} · TABLE 1', style: C8PTypo.mono(size: 9, letterSpacing: 0.2)),
                      const SizedBox(height: 2),
                      Text('Coupe du Gabon 8-Ball', style: C8PTypo.sans(size: 13, weight: FontWeight.w700)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0x142DA876),
                      border: Border.all(color: const Color(0x66 + 0x002DA876)),
                    ),
                    child: Text('● EN LIGNE', style: C8PTypo.mono(size: 9, color: C8P.felt2, letterSpacing: 0.14)),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: C8P.line),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: _danger ? const Color(0x0FE5484D) : Colors.transparent,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SHOT CLOCK', style: C8PTypo.mono(size: 9, letterSpacing: 0.2)),
                      Text(_danger ? 'WARNING' : 'NORMAL',
                           style: C8PTypo.mono(size: 9, color: _danger ? C8P.live : C8P.mute, letterSpacing: 0.18)),
                    ],
                  ),
                  Text(_shotClock.toString().padLeft(2, '0'),
                       style: C8PTypo.disp(size: 124, color: _danger ? C8P.live : C8P.chalk)),
                  const SizedBox(height: 4),
                  Container(
                    height: 4,
                    color: C8P.line,
                    child: Row(
                      children: [
                        Expanded(
                          flex: _shotClock,
                          child: Container(color: _danger ? C8P.live : C8P.felt2),
                        ),
                        Expanded(flex: 30 - _shotClock, child: Container()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('FRAME ${scoreA + scoreB + 1} · RACE TO 7',
                           style: C8PTypo.mono(size: 10, letterSpacing: 0.14)),
                      Text('MATCH ${_fmt(_matchSeconds)}', style: C8PTypo.mono(size: 10, letterSpacing: 0.14)),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 1, color: C8P.line),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _playerCell(pa, scoreA, scoreA > scoreB)),
                  Container(width: 1, color: C8P.line),
                  Expanded(child: _playerCell(pb, scoreB, scoreB > scoreA)),
                ],
              ),
            ),
            Container(height: 1, color: C8P.line),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _winFrame('A'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: C8P.felt2,
                            foregroundColor: C8P.ink,
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _smallBtn('Faute'),
                      const SizedBox(width: 8),
                      _smallBtn('Black foul'),
                      const SizedBox(width: 8),
                      _smallBtn('Empoche 8'),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              color: C8P.ink2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('⏸ PAUSE', style: C8PTypo.mono(size: 11, letterSpacing: 0.14)),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/end', arguments: _match),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: C8P.felt2),
                      foregroundColor: C8P.felt2,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: Text('FIN DE MATCH',
                         style: C8PTypo.sans(size: 12, color: C8P.felt2, weight: FontWeight.w700).copyWith(letterSpacing: 1)),
                  ),
                  Text('⏏ ARRÊT', style: C8PTypo.mono(size: 11, color: C8P.live, letterSpacing: 0.14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerCell(Map? p, int score, bool winning) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SEED #${p?['id']}', style: C8PTypo.mono(size: 9)),
        const SizedBox(height: 8),
        Text(
          '${p?['first_name']}\n${p?['last_name']}',
          style: C8PTypo.sans(size: 12, weight: FontWeight.w700).copyWith(height: 1.1),
        ),
        const SizedBox(height: 4),
        Text(score.toString(),
             style: C8PTypo.disp(size: 80, color: winning ? C8P.felt2 : C8P.chalk)),
      ],
    ),
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
