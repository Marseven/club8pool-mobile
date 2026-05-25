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

  // ── Chrono (iOS/Android native style) ─────────────────────────────
  Duration _chronoBase = Duration.zero;
  DateTime? _chronoStart; // null = stopped/paused

  bool get _chronoRunning => _chronoStart != null;
  bool get _chronoHasTime => _elapsed > Duration.zero;

  Duration get _elapsed => _chronoStart != null
      ? _chronoBase + DateTime.now().difference(_chronoStart!)
      : _chronoBase;

  /// Single toggle: Start if stopped, Stop (pause) if running
  void _chronoToggle() => setState(() {
    if (_chronoRunning) {
      _chronoBase = _elapsed;
      _chronoStart = null;
    } else {
      _chronoStart = DateTime.now();
    }
  });

  /// Reset — only when stopped and has elapsed time (like iOS)
  void _chronoReset() {
    if (_chronoRunning || !_chronoHasTime) return;
    setState(() {
      _chronoBase = Duration.zero;
      _chronoStart = null;
    });
  }

  String _fmtChrono() {
    final d = _elapsed;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  // ───────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _match = Map.from(widget.match);

    // Shot clock ticks every second
    _shotTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _shotClock = _shotClock <= 0 ? 30 : _shotClock - 1);
    });
    // UI refresh for running chrono
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

  // ── Scoring ──────────────────────────────────────────────────────

  Future<void> _winFrame(String winner) async {
    setState(() {
      if (winner == 'A') {
        _match['score_a'] = (_match['score_a'] ?? 0) + 1;
      } else {
        _match['score_b'] = (_match['score_b'] ?? 0) + 1;
      }
      _shotClock = 30; // reset shot clock on every frame
    });
    try {
      final api = await ApiService.create();
      final r = await api.frame(_match['id'], winner);
      if (mounted) setState(() => _match = Map.from(r['match']));
    } catch (_) {}
  }

  Future<void> _undoFrame(String player) async {
    final key = player == 'A' ? 'score_a' : 'score_b';
    if ((_match[key] ?? 0) <= 0) return;
    setState(() => _match[key] = (_match[key] ?? 0) - 1);
    try {
      final api = await ApiService.create();
      final r = await api.undoFrame(_match['id'], player);
      if (mounted) setState(() => _match = Map.from(r['match']));
    } catch (_) {}
  }

  Future<void> _recordWarning(String player) async {
    Navigator.of(context).pop(); // close bottom sheet
    try {
      final api = await ApiService.create();
      final r = await api.warning(_match['id'], player);
      if (mounted) {
        setState(() => _match = Map.from(r['match']));
        final name = player == 'A'
            ? (_match['player_a']?['last_name'] ?? 'A')
            : (_match['player_b']?['last_name'] ?? 'B');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: C8P.ink2,
          behavior: SnackBarBehavior.floating,
          content: Row(children: [
            const Icon(Icons.warning_amber_rounded, size: 14, color: C8P.live),
            const SizedBox(width: 8),
            Text('Faute enregistrée · $name',
                style: C8PTypo.mono(size: 11, color: C8P.live, letterSpacing: 0.1)),
          ]),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (_) {}
  }

  // ── Bottom sheets ────────────────────────────────────────────────

  void _showFouteSheet() {
    _showPlayerSheet(
      icon: Icons.warning_amber_rounded,
      title: 'FAUTE',
      subtitle: 'Quel joueur commet la faute ?',
      onA: () => _recordWarning('A'),
      onB: () => _recordWarning('B'),
    );
  }

  void _showBlackFoulSheet() {
    _showPlayerSheet(
      icon: Icons.close,
      title: 'BLACK FOUL',
      subtitle: 'Qui commet le black foul ?\n(l\'adversaire gagne la frame)',
      onA: () { Navigator.of(context).pop(); _winFrame('B'); },
      onB: () { Navigator.of(context).pop(); _winFrame('A'); },
    );
  }

  void _showEmpoche8Sheet() {
    _showPlayerSheet(
      icon: Icons.sports_score,
      title: 'EMPOCHE LA 8',
      subtitle: 'Qui empoche la 8 balle ?',
      onA: () { Navigator.of(context).pop(); _winFrame('A'); },
      onB: () { Navigator.of(context).pop(); _winFrame('B'); },
    );
  }

  void _showPlayerSheet({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onA,
    required VoidCallback onB,
  }) {
    final pa = _match['player_a'];
    final pb = _match['player_b'];
    showModalBottomSheet(
      context: context,
      backgroundColor: C8P.ink2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 14, color: C8P.mute),
                const SizedBox(width: 6),
                Text(title,
                    style: C8PTypo.mono(size: 10, letterSpacing: 0.22, color: C8P.mute)),
              ]),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: C8PTypo.sans(size: 15, weight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onA,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: C8P.lineStrong),
                      foregroundColor: C8P.chalk,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Column(children: [
                      Text(pa?['last_name'] ?? 'A',
                           style: C8PTypo.sans(size: 14, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(pa?['first_name'] ?? '',
                           style: C8PTypo.mono(size: 9, letterSpacing: 0.1, color: C8P.mute)),
                    ]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onB,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: C8P.lineStrong),
                      foregroundColor: C8P.chalk,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Column(children: [
                      Text(pb?['last_name'] ?? 'B',
                           style: C8PTypo.sans(size: 14, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(pb?['first_name'] ?? '',
                           style: C8PTypo.mono(size: 9, letterSpacing: 0.1, color: C8P.mute)),
                    ]),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

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
    final warningA = _match['warning_a'] == true;
    final warningB = _match['warning_b'] == true;

    return Scaffold(
      backgroundColor: C8P.ink,
      body: SafeArea(
        child: Column(
          children: [

            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
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
                      '${pool?['name'] ?? _match['round'] ?? '—'} · '
                      '${_match['table']?['name']?.toString().toUpperCase() ?? 'TABLE —'}',
                      style: C8PTypo.mono(size: 9, letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _match['competition']?['name'] ?? '',
                      style: C8PTypo.sans(size: 12, weight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0x142DA876),
                      border: Border.all(color: const Color(0x662DA876)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.circle, size: 7, color: C8P.felt2),
                      const SizedBox(width: 4),
                      Text('LIVE',
                          style: C8PTypo.mono(size: 9, color: C8P.felt2, letterSpacing: 0.14)),
                    ]),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: C8P.line),

            // ── Shot clock ───────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: _danger ? const Color(0x0FE5484D) : Colors.transparent,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('SHOT CLOCK',
                      style: C8PTypo.mono(size: 9, letterSpacing: 0.2)),
                  Text(_danger ? 'WARNING' : 'NORMAL',
                      style: C8PTypo.mono(size: 9,
                          color: _danger ? C8P.live : C8P.mute, letterSpacing: 0.18)),
                ]),
                Text(_shotClock.toString().padLeft(2, '0'),
                    style: C8PTypo.disp(
                        size: 86, color: _danger ? C8P.live : C8P.chalk)),
                Container(
                  height: 3, color: C8P.line,
                  child: Row(children: [
                    Expanded(
                        flex: _shotClock,
                        child: Container(color: _danger ? C8P.live : C8P.felt2)),
                    Expanded(flex: 30 - _shotClock, child: Container()),
                  ]),
                ),
                const SizedBox(height: 5),
                Text('FRAME ${scoreA + scoreB + 1} · RACE TO $raceTo',
                    style: C8PTypo.mono(size: 10, letterSpacing: 0.14)),
              ]),
            ),
            Container(height: 1, color: C8P.line),

            // ── Players (score + +/- controls) ──────────────────────
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: _playerCell(pa, scoreA, scoreA > scoreB, warningA, 'A')),
                Container(width: 1, color: C8P.line),
                Expanded(child: _playerCell(pb, scoreB, scoreB > scoreA, warningB, 'B')),
              ]),
            ),
            Container(height: 1, color: C8P.line),

            // ── + Frame buttons ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _winFrame('A'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C8P.felt2,
                        foregroundColor: C8P.ink,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      child: Text('+ FRAME · ${pa?['last_name'] ?? 'A'}',
                          style: C8PTypo.sans(
                              size: 13, color: C8P.ink, weight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _winFrame('B'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: C8P.lineStrong),
                        backgroundColor: const Color(0x0FFFFFFF),
                        foregroundColor: C8P.chalk,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      child: Text('+ FRAME · ${pb?['last_name'] ?? 'B'}',
                          style: C8PTypo.sans(
                              size: 13, color: C8P.chalk, weight: FontWeight.w700)),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                // ── Incident buttons ─────────────────────────────────
                Row(children: [
                  _incidentBtn(Icons.warning_amber_rounded, 'FAUTE', C8P.live, _showFouteSheet),
                  const SizedBox(width: 6),
                  _incidentBtn(Icons.close, 'BLACK FOUL', C8P.live, _showBlackFoulSheet),
                  const SizedBox(width: 6),
                  _incidentBtn(Icons.sports_score, 'EMPOCHE 8', C8P.chalk2, _showEmpoche8Sheet),
                ]),
              ]),
            ),

            // ── Chrono (iOS / Android style) ─────────────────────────
            Container(height: 1, color: C8P.line),
            Container(
              color: C8P.ink2,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Time display
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CHRONO',
                            style: C8PTypo.mono(
                                size: 8, letterSpacing: 0.22, color: C8P.mute)),
                        const SizedBox(height: 2),
                        Text(
                          _fmtChrono(),
                          style: C8PTypo.disp(
                            size: 46,
                            color: _chronoRunning
                                ? C8P.chalk
                                : (_chronoHasTime ? C8P.chalk2 : C8P.mute),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Reset button — disabled when running or at 00:00
                  _chronoCircleBtn(
                    icon: Icons.refresh_rounded,
                    label: 'RÉINIT',
                    color: (!_chronoRunning && _chronoHasTime) ? C8P.chalk : C8P.mute,
                    bgColor: const Color(0x14FFFFFF),
                    onTap: (!_chronoRunning && _chronoHasTime) ? _chronoReset : null,
                  ),
                  const SizedBox(width: 14),
                  // Start / Stop button
                  _chronoCircleBtn(
                    icon: _chronoRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    label: _chronoRunning
                        ? 'ARRÊTER'
                        : (_chronoHasTime ? 'REPRENDRE' : 'DÉMARRER'),
                    color: _chronoRunning ? C8P.live : C8P.felt2,
                    bgColor: _chronoRunning
                        ? const Color(0x1AE5484D)
                        : const Color(0x1A2DA876),
                    borderColor: _chronoRunning
                        ? const Color(0x66E5484D)
                        : const Color(0x662DA876),
                    onTap: _chronoToggle,
                  ),
                ],
              ),
            ),

            // ── FIN DE MATCH ─────────────────────────────────────────
            Container(
              color: C8P.ink2,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context)
                      .pushReplacementNamed('/end', arguments: _match),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: C8P.felt2),
                    foregroundColor: C8P.felt2,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text('FIN DE MATCH',
                      style: C8PTypo.sans(
                              size: 12, color: C8P.felt2, weight: FontWeight.w700)
                          .copyWith(letterSpacing: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────

  Widget _playerCell(
      Map? p, int score, bool winning, bool hasWarning, String player) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seed + warning badge
            Row(children: [
              Text('SEED #${p?['id']}', style: C8PTypo.mono(size: 9)),
              if (hasWarning) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  color: const Color(0x26E5484D),
                  child: const Icon(Icons.warning_amber_rounded, size: 12, color: C8P.live),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            Text(
              '${p?['first_name']}\n${p?['last_name']}',
              style: C8PTypo.sans(size: 11, weight: FontWeight.w700)
                  .copyWith(height: 1.1),
            ),
            const SizedBox(height: 4),
            // Score + undo (−) button
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(score.toString(),
                    style: C8PTypo.disp(
                        size: 60, color: winning ? C8P.felt2 : C8P.chalk)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: GestureDetector(
                    onTap: () => _undoFrame(player),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: score > 0
                              ? const Color(0x33FFFFFF)
                              : const Color(0x11FFFFFF),
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.remove, size: 20,
                          color: score > 0 ? C8P.mute : const Color(0x22FFFFFF)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _incidentBtn(IconData icon, String label, Color color, VoidCallback onTap) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              border: Border.all(color: color.withValues(alpha: 0.22)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(height: 3),
              Text(label, style: C8PTypo.mono(size: 9, color: color, letterSpacing: 0.08)
                  .copyWith(fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );

  Widget _chronoCircleBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    Color? borderColor,
    required VoidCallback? onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 62, height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: borderColor != null ? Border.all(color: borderColor, width: 1.5) : null,
      ),
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: onTap != null ? color : C8P.mute),
        const SizedBox(height: 2),
        Text(label,
          style: C8PTypo.mono(size: 8, color: onTap != null ? color : C8P.mute, letterSpacing: 0.06)
              .copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center),
      ]),
    ),
  );
}
