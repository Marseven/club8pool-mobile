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
  List _mine = [];
  List _available = [];
  Map? _user;
  bool _loading = true;
  String _error = '';
  final Map<int, bool> _claiming = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final api = await ApiService.create();
      final results = await Future.wait([api.me(), api.queue(), api.available()]);
      if (!mounted) return;
      setState(() {
        _user      = results[0] as Map;
        _mine      = results[1] as List;
        _available = results[2] as List;
        _loading   = false;
      });
    } catch (e, s) {
      debugPrint('[Queue] load failed: $e');
      debugPrintStack(stackTrace: s);
      if (!mounted) return;
      setState(() {
        _error   = 'Erreur de chargement · ${e.toString().split("\n").first}';
        _loading = false;
      });
    }
  }

  Future<void> _claim(Map m) async {
    final id = m['id'] as int;
    setState(() => _claiming[id] = true);
    try {
      final api = await ApiService.create();
      await api.claim(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: C8P.ink2,
        content: Text(e.toString(), style: C8PTypo.sans(size: 12, color: C8P.live)),
      ));
    } finally {
      if (mounted) setState(() => _claiming.remove(id));
    }
  }

  String _fmtTime(String? iso) {
    if (iso == null) return '—';
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
    const days   = ['LUN.', 'MAR.', 'MER.', 'JEU.', 'VEN.', 'SAM.', 'DIM.'];
    const months = ['JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUN', 'JUL', 'AOÛ', 'SEP', 'OCT', 'NOV', 'DÉC'];
    return '${days[now.weekday - 1]} ${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final live = _mine.where((m) => m['status'] == 'live').length;

    return Scaffold(
      backgroundColor: C8P.ink,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
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
                        Text(_user?['name'] ?? 'Chargement…',
                             style: C8PTypo.sans(size: 13, weight: FontWeight.w700)),
                        Text(
                          ((_user?['title'] ?? 'Arbitre') as String).toUpperCase(),
                          style: C8PTypo.mono(size: 9, letterSpacing: 0.14),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: C8P.line),

            // ── Stats ───────────────────────────────────────────────
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
                  Row(children: [
                    _stat(_mine.length.toString().padLeft(2, '0'), 'MES MATCHS', C8P.chalk),
                    const SizedBox(width: 20),
                    _stat(live.toString().padLeft(2, '0'), 'EN COURS', C8P.live),
                    const SizedBox(width: 20),
                    _stat(_available.length.toString().padLeft(2, '0'), 'DISPONIBLES', C8P.felt2),
                  ]),
                ],
              ),
            ),
            Container(height: 1, color: C8P.line),

            // ── List ────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: C8P.felt2))
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, style: C8PTypo.mono(color: C8P.live)))
                      : (_mine.isEmpty && _available.isEmpty)
                          ? _emptyState()
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: C8P.felt2,
                              backgroundColor: C8P.ink2,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                children: [
                                  if (_mine.isNotEmpty) ...[
                                    _sectionHeader('MES MATCHS', '${_mine.length}'),
                                    for (final m in _mine) _myMatchCard(m),
                                  ],
                                  if (_available.isNotEmpty) ...[
                                    _sectionHeader('DISPONIBLES', '${_available.length}', color: C8P.felt2),
                                    for (final m in _available) _availableCard(m),
                                  ],
                                ],
                              ),
                            ),
            ),
            const RefereeNav(active: 'queue'),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, String count, {Color color = C8P.mute}) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
    child: Row(children: [
      Text(label, style: C8PTypo.mono(size: 9, letterSpacing: 0.22, color: color)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(count, style: C8PTypo.mono(size: 9, color: color)),
      ),
    ]),
  );

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('AUCUN MATCH', style: C8PTypo.disp(size: 22, color: C8P.mute)),
        const SizedBox(height: 12),
        Text(
          'Aucun match ne t\'est assigné et aucun n\'est disponible pour le moment.',
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

  Widget _stat(String v, String l, Color c) => Row(children: [
    Text(v, style: C8PTypo.disp(size: 22, color: c)),
    const SizedBox(width: 6),
    Text(l, style: C8PTypo.mono(size: 10, letterSpacing: 0.16)),
  ]);

  Widget _myMatchCard(Map m) {
    final isLive = m['status'] == 'live';
    final isDone = m['status'] == 'done';
    final pa = m['player_a'];
    final pb = m['player_b'];
    final table = m['table'];

    return Opacity(
      opacity: isDone ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLive ? const Color(0x0AE5484D) : C8P.ink2,
          border: Border.all(color: isLive ? const Color(0x66E5484D) : C8P.line),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_fmtTime(m['scheduled_at']), style: C8PTypo.disp(size: 24)),
            _statusChip(m['status']),
          ]),
          const SizedBox(height: 6),
          Text(
            '${m['pool']?['name'] ?? m['round'] ?? '—'} · ${table?['name'] ?? 'TABLE —'}',
            style: C8PTypo.mono(size: 10, letterSpacing: 0.18),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${pa?['first_name']?[0] ?? '?'}. ${pa?['last_name'] ?? ''}',
                   style: C8PTypo.sans(size: 14, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${pb?['first_name']?[0] ?? '?'}. ${pb?['last_name'] ?? ''}',
                   style: C8PTypo.sans(size: 13, color: C8P.chalk2)),
            ])),
            if (isLive || isDone)
              Text('${m['score_a']} — ${m['score_b']}',
                   style: C8PTypo.disp(size: 26, color: isLive ? C8P.felt2 : C8P.chalk2)),
          ]),
          if (isLive || m['status'] == 'scheduled' || m['status'] == 'pending') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed(
                  isLive ? '/live' : '/pre', arguments: m,
                ).then((_) => _load()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLive ? C8P.felt2 : Colors.transparent,
                  foregroundColor: isLive ? C8P.ink : C8P.chalk,
                  elevation: 0,
                  side: isLive ? null : const BorderSide(color: C8P.lineStrong),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                ),
                child: Text(
                  isLive ? 'REPRENDRE →' : 'PRÉPARER →',
                  style: C8PTypo.sans(size: 12, color: isLive ? C8P.ink : C8P.chalk, weight: FontWeight.w700)
                      .copyWith(letterSpacing: 1),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _availableCard(Map m) {
    final id = m['id'] as int;
    final claiming = _claiming[id] == true;
    final pa = m['player_a'];
    final pb = m['player_b'];
    final pool = m['pool'];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C8P.ink2,
        border: Border.all(color: const Color(0x332DA876)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_fmtTime(m['scheduled_at']), style: C8PTypo.disp(size: 24, color: C8P.chalk2)),
          if (pool != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x0F2DA876),
                border: Border.all(color: const Color(0x332DA876)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                (pool['name'] as String? ?? '').toUpperCase(),
                style: C8PTypo.mono(size: 9, color: C8P.felt2, letterSpacing: 0.14)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${pa?['first_name']?[0] ?? '?'}. ${pa?['last_name'] ?? ''}',
                 style: C8PTypo.sans(size: 14, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${pb?['first_name']?[0] ?? '?'}. ${pb?['last_name'] ?? ''}',
                 style: C8PTypo.sans(size: 13, color: C8P.chalk2)),
          ])),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: claiming ? null : () => _claim(m),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0x142DA876),
              foregroundColor: C8P.felt2,
              elevation: 0,
              side: const BorderSide(color: Color(0x442DA876)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              disabledBackgroundColor: const Color(0x0A2DA876),
            ),
            child: claiming
                ? const SizedBox(height: 14, width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: C8P.felt2))
                : Text('PRENDRE EN CHARGE',
                    style: C8PTypo.sans(size: 12, color: C8P.felt2, weight: FontWeight.w700)
                        .copyWith(letterSpacing: 1)),
          ),
        ),
      ]),
    );
  }

  Widget _statusChip(String status) {
    final (label, color) = switch (status) {
      'live'      => ('● LIVE', C8P.live),
      'done'      => ('✓ TERMINÉ', C8P.felt2),
      'scheduled' => ('PROGRAMMÉ', C8P.chalk2),
      _           => ('EN ATTENTE', C8P.mute),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(label, style: C8PTypo.mono(size: 9, color: color, letterSpacing: 0.14)
          .copyWith(fontWeight: FontWeight.w700)),
    );
  }
}
