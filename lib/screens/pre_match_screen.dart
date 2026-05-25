import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class PreMatchScreen extends StatefulWidget {
  final Map match;
  const PreMatchScreen({super.key, required this.match});

  @override
  State<PreMatchScreen> createState() => _PreMatchScreenState();
}

class _PreMatchScreenState extends State<PreMatchScreen> {
  List _tables = [];
  int? _selectedTableId;
  bool _starting = false;
  bool _tablesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    try {
      final api = await ApiService.create();
      final tables = await api.tables();
      if (!mounted) return;
      setState(() { _tables = tables; _tablesLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _tablesLoading = false);
    }
  }

  Future<void> _startMatch() async {
    setState(() => _starting = true);
    try {
      final api = await ApiService.create();
      if (_selectedTableId != null) {
        await api.assignTable(widget.match['id'], _selectedTableId!);
      }
      final fresh = await api.start(widget.match['id']);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/live', arguments: fresh);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: C8P.ink2,
        content: Text(e.toString(), style: C8PTypo.sans(size: 12, color: C8P.live)),
      ));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final pa = m['player_a'];
    final pb = m['player_b'];
    final pool = m['pool'];
    final competition = m['competition'];
    final raceToPool = competition?['pool_race_to'] ?? competition?['race_to'] ?? 3;
    final raceToKo   = competition?['knockout_race_to'] ?? competition?['race_to'] ?? 7;
    final raceTo = m['phase'] == 'knockout' ? raceToKo : raceToPool;

    return Scaffold(
      backgroundColor: C8P.ink,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
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
                      '${pool?['name'] ?? m['round'] ?? '—'} · PRÉ-MATCH',
                      style: C8PTypo.mono(size: 9, letterSpacing: 0.22),
                    ),
                    const SizedBox(height: 2),
                    Text(competition?['name'] ?? '',
                         style: C8PTypo.sans(size: 13, weight: FontWeight.w700),
                         maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Container(height: 1, color: C8P.line),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ── Players ──────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: C8P.ink2,
                        border: Border.all(color: C8P.line),
                      ),
                      child: Column(children: [
                        _playerRow(pa, true),
                        Container(height: 1, color: C8P.line),
                        _playerRow(pb, false),
                      ]),
                    ),
                    const SizedBox(height: 22),

                    // ── Table selection ───────────────────────────────
                    Text('TABLE', style: C8PTypo.mono(size: 10, letterSpacing: 0.22)),
                    const SizedBox(height: 12),
                    if (_tablesLoading)
                      const Center(child: CircularProgressIndicator(color: C8P.felt2, strokeWidth: 2))
                    else if (_tables.isEmpty)
                      Text('Aucune table disponible',
                           style: C8PTypo.sans(size: 12, color: C8P.mute))
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final t in _tables)
                              GestureDetector(
                                onTap: () => setState(() =>
                                    _selectedTableId = _selectedTableId == t['id'] ? null : t['id']),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedTableId == t['id']
                                        ? const Color(0x142DA876) : C8P.ink2,
                                    border: Border.all(
                                      color: _selectedTableId == t['id']
                                          ? C8P.felt2 : C8P.lineStrong,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Column(children: [
                                    Text(t['name'] ?? '',
                                         style: C8PTypo.sans(size: 13, weight: FontWeight.w700,
                                             color: _selectedTableId == t['id'] ? C8P.felt2 : C8P.chalk)),
                                    const SizedBox(height: 2),
                                    Text(
                                      t['live_match'] != null ? '● EN JEU' : 'LIBRE',
                                      style: C8PTypo.mono(size: 9, letterSpacing: 0.12,
                                          color: t['live_match'] != null ? C8P.live : C8P.mute),
                                    ),
                                  ]),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 22),

                    // ── Settings ──────────────────────────────────────
                    Text('RÉGLAGES', style: C8PTypo.mono(size: 10, letterSpacing: 0.22)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: C8P.ink2,
                        border: Border.all(color: C8P.line),
                      ),
                      child: Column(children: [
                        _settingRow('Race to', '$raceTo frames', first: true),
                        _settingRow('Shot clock', '30 sec'),
                        _settingRow('Extension', '×1 / joueur'),
                        _settingRow('Break', 'Alterné'),
                      ]),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),

            // ── Start button ────────────────────────────────────────
            Container(height: 1, color: C8P.line),
            Container(
              color: C8P.ink2,
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _starting ? null : _startMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C8P.felt2,
                    foregroundColor: C8P.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    disabledBackgroundColor: const Color(0xFF1A3A2A),
                  ),
                  child: _starting
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: C8P.felt2))
                      : Text(
                          _selectedTableId != null
                              ? '▸ DÉMARRER SUR ${_tables.firstWhere((t) => t['id'] == _selectedTableId, orElse: () => {'name': '?'})['name']}'
                              : '▸ DÉMARRER LE MATCH',
                          style: C8PTypo.sans(size: 14, color: C8P.ink, weight: FontWeight.w800)
                              .copyWith(letterSpacing: 1.4),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerRow(Map? p, bool isA) => Container(
    padding: const EdgeInsets.all(18),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: C8P.ink4),
        alignment: Alignment.center,
        child: Text(
          '${p?['first_name']?[0] ?? ''}${p?['last_name']?[0] ?? ''}',
          style: C8PTypo.disp(size: 16),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${p?['first_name']} ${p?['last_name']}',
             style: C8PTypo.sans(size: 14, weight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text('SEED #${p?['id']} · ELO ${p?['rating']}',
             style: C8PTypo.mono(size: 10, letterSpacing: 0.14)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isA ? const Color(0x142DA876) : C8P.ink4,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(isA ? 'A' : 'B',
                    style: C8PTypo.mono(size: 11, color: isA ? C8P.felt2 : C8P.mute,
                        letterSpacing: 0.1).copyWith(fontWeight: FontWeight.w700)),
      ),
    ]),
  );

  Widget _settingRow(String k, String v, {bool first = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      border: first ? null : const Border(top: BorderSide(color: Color(0x0FFFFFFF))),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(k, style: C8PTypo.sans(size: 12, color: C8P.chalk2)),
      Text(v, style: C8PTypo.mono(size: 13, color: C8P.chalk).copyWith(fontWeight: FontWeight.w700)),
    ]),
  );
}
