import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/referee_nav.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  List _matches = [];
  Map? _user;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = await ApiService.create();
      final results = await Future.wait([api.me(), api.queue()]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as Map;
        _matches = results[1] as List;
        _loading = false;
      });
    } catch (e, s) {
      debugPrint('[Queue] load failed: $e');
      debugPrintStack(stackTrace: s);
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de chargement · ${e.toString().split("\n").first}';
        _loading = false;
      });
    }
  }

  String _fmtTime(String? iso) {
    if (iso == null) return '';
    final d = DateTime.parse(iso).toUtc();
    return '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
  }

  String get _initials {
    final name = (_user?['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String get _todayLabel {
    final now = DateTime.now();
    const days = ['LUN.', 'MAR.', 'MER.', 'JEU.', 'VEN.', 'SAM.', 'DIM.'];
    const months = ['JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUN', 'JUL', 'AOÛ', 'SEP', 'OCT', 'NOV', 'DÉC'];
    return '${days[now.weekday - 1]} ${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final live = _matches.where((m) => m['status'] == 'live').length;
    final done = _matches.where((m) => m['status'] == 'done').length;

    return Scaffold(
      backgroundColor: C8P.ink,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: C8P.felt),
                    alignment: Alignment.center,
                    child: Text(_initials, style: C8PTypo.sans(size: 13, weight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_user?['name'] ?? 'Chargement…', style: C8PTypo.sans(size: 13, weight: FontWeight.w700)),
                        Text(
                          ((_user?['title'] ?? 'Arbitre') as String).toUpperCase()
                            + (_user?['fgb_card'] != null ? ' · ${_user!['fgb_card']}' : ''),
                          style: C8PTypo.mono(size: 9, letterSpacing: 0.14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: C8P.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("AUJOURD'HUI", style: C8PTypo.disp(size: 36)),
                      Text(_todayLabel, style: C8PTypo.mono(size: 10)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _stat(_matches.length.toString().padLeft(2, '0'), 'MATCHS', C8P.chalk),
                      const SizedBox(width: 20),
                      _stat(live.toString().padLeft(2, '0'), 'EN COURS', C8P.live),
                      const SizedBox(width: 20),
                      _stat(done.toString().padLeft(2, '0'), 'TERMINÉS', C8P.felt2),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: C8P.felt2))
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, style: C8PTypo.mono(color: C8P.live)))
                      : _matches.isEmpty
                          ? _emptyState()
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: C8P.felt2,
                              backgroundColor: C8P.ink2,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: _matches.length,
                                itemBuilder: (_, i) => _matchCard(_matches[i]),
                              ),
                            ),
            ),
            const RefereeNav(active: 'queue'),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('AUCUN MATCH ASSIGNÉ', style: C8PTypo.disp(size: 22, color: C8P.mute)),
        const SizedBox(height: 12),
        Text(
          "L'organisateur ne t'a pas encore assigné de match. Tu peux suivre les tables en attendant.",
          textAlign: TextAlign.center,
          style: C8PTypo.sans(size: 12, color: C8P.mute),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed('/tables'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: C8P.lineStrong),
            foregroundColor: C8P.chalk,
          ),
          child: Text('Voir les tables →', style: C8PTypo.sans(size: 12, color: C8P.chalk)),
        ),
      ]),
    ),
  );

  Widget _stat(String v, String l, Color c) => Row(
    children: [
      Text(v, style: C8PTypo.disp(size: 22, color: c)),
      const SizedBox(width: 6),
      Text(l, style: C8PTypo.mono(size: 10, letterSpacing: 0.16)),
    ],
  );

  Widget _matchCard(Map m) {
    final isLive = m['status'] == 'live';
    final isDone = m['status'] == 'done';
    final pa = m['player_a'];
    final pb = m['player_b'];
    final table = m['table'];

    return Opacity(
      opacity: isDone ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLive ? const Color(0x0AE5484D) : C8P.ink2,
          border: Border.all(color: isLive ? const Color(0x66E5484D) : C8P.line),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmtTime(m['scheduled_at']) , style: C8PTypo.disp(size: 24)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLive ? const Color(0x26E5484D) : isDone ? const Color(0x1F2DA876) : const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    isLive ? '● LIVE' : isDone ? '✓ TERMINÉ' : 'PROCHAIN',
                    style: C8PTypo.mono(size: 9, color: isLive ? C8P.live : isDone ? C8P.felt2 : C8P.chalk2, letterSpacing: 0.14)
                      .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${m['round']} · ${table?['name'] ?? 'TABLE —'}',
                 style: C8PTypo.mono(size: 10, letterSpacing: 0.18)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${pa?['first_name']?[0] ?? '?'}. ${pa?['last_name'] ?? ''}',
                           style: C8PTypo.sans(size: 14, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${pb?['first_name']?[0] ?? '?'}. ${pb?['last_name'] ?? ''}',
                           style: C8PTypo.sans(size: 13, color: C8P.chalk2)),
                    ],
                  ),
                ),
                if (isLive)
                  Text('${m['score_a']} — ${m['score_b']}',
                       style: C8PTypo.disp(size: 26, color: C8P.felt2)),
                if (isDone)
                  Text('${m['score_a']}-${m['score_b']}',
                       style: C8PTypo.disp(size: 24, color: C8P.chalk2)),
              ],
            ),
            if (isLive || m['status'] == 'scheduled') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    isLive ? '/live' : '/pre',
                    arguments: m,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLive ? C8P.felt2 : Colors.transparent,
                    foregroundColor: isLive ? C8P.ink : C8P.chalk,
                    elevation: 0,
                    side: isLive ? null : const BorderSide(color: C8P.lineStrong),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                  ),
                  child: Text(
                    isLive ? 'REPRENDRE →' : 'DÉMARRER →',
                    style: C8PTypo.sans(size: 12, color: isLive ? C8P.ink : C8P.chalk, weight: FontWeight.w700).copyWith(letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
