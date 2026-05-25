import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/ball8.dart';
import '../widgets/referee_nav.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  List _tables = [];
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
      final t = await api.tables();
      if (!mounted) return;
      setState(() { _tables = t; _loading = false; });
    } catch (e, s) {
      debugPrint('[Tables] load failed: $e');
      debugPrintStack(stackTrace: s);
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de chargement · ${e.toString().split("\n").first}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = _tables.where((t) => t['status'] == 'live').length;
    final idle = _tables.where((t) => t['status'] == 'idle').length;
    final maint = _tables.where((t) => t['status'] == 'maint').length;

    return Scaffold(
      backgroundColor: C8P.ink,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ICONE POOL CHAMPIONSHIP',
                       style: C8PTypo.mono(size: 9, letterSpacing: 0.22)),
                  const SizedBox(height: 6),
                  Text('TABLES', style: C8PTypo.disp(size: 28)),
                ])),
                const Ball8(size: 32),
              ]),
            ),
            Container(height: 1, color: C8P.line),

            // Counters
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
              child: Row(children: [
                _stat(live.toString().padLeft(2, '0'), 'EN COURS', C8P.live),
                const SizedBox(width: 20),
                _stat(idle.toString().padLeft(2, '0'), 'LIBRES', C8P.chalk),
                if (maint > 0) ...[
                  const SizedBox(width: 20),
                  _stat(maint.toString().padLeft(2, '0'), 'MAINT.', C8P.mute),
                ],
              ]),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: C8P.felt2))
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, style: C8PTypo.mono(color: C8P.live)))
                      : _tables.isEmpty
                          ? Center(child: Text('Aucune table', style: C8PTypo.disp(size: 18, color: C8P.mute)))
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: C8P.felt2,
                              backgroundColor: C8P.ink2,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: _tables.length,
                                itemBuilder: (_, i) => _tableCard(_tables[i]),
                              ),
                            ),
            ),

            const RefereeNav(active: 'tables'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String v, String l, Color c) => Row(children: [
    Text(v, style: C8PTypo.disp(size: 22, color: c)),
    const SizedBox(width: 6),
    Text(l, style: C8PTypo.mono(size: 10, letterSpacing: 0.16)),
  ]);

  Widget _tableCard(Map t) {
    final isLive = t['status'] == 'live';
    final isMaint = t['status'] == 'maint';
    final live = t['live_match'];

    return Opacity(
      opacity: isMaint ? 0.55 : 1,
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
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((t['name'] ?? '').toString().toUpperCase(), style: C8PTypo.disp(size: 22)),
                const SizedBox(height: 4),
                Text(((t['location'] ?? '') as String).toUpperCase(),
                     style: C8PTypo.mono(size: 10, letterSpacing: 0.18)),
              ])),
              _chip(isLive ? 'EN COURS' : isMaint ? 'MAINT.' : 'LIBRE',
                    isLive ? C8P.live : isMaint ? C8P.mute : C8P.felt2),
            ]),
            if (isLive && live != null) ...[
              const SizedBox(height: 12),
              Text(
                'POULE ${live['pool']?['name'] ?? '—'}'
                  + (live['referee']?['name'] != null ? ' · ARB. ${(live['referee']['name'] as String).toUpperCase()}' : ''),
                style: C8PTypo.mono(size: 10, letterSpacing: 0.18),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${live['player_a']?['first_name'] ?? ''} ${live['player_a']?['last_name'] ?? ''}',
                       style: C8PTypo.sans(size: 14, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${live['player_b']?['first_name'] ?? ''} ${live['player_b']?['last_name'] ?? ''}',
                       style: C8PTypo.sans(size: 13, color: C8P.chalk2)),
                ])),
                Text('${live['score_a']} — ${live['score_b']}',
                     style: C8PTypo.disp(size: 26, color: C8P.felt2)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/live', arguments: live),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C8P.felt2,
                    foregroundColor: C8P.ink,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                  ),
                  child: Text('ALLER AU MATCH →',
                       style: C8PTypo.sans(size: 12, color: C8P.ink, weight: FontWeight.w700).copyWith(letterSpacing: 1)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: color.withOpacity(0.5)),
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Text(text, style: C8PTypo.mono(size: 10, color: color, letterSpacing: 0.14).copyWith(fontWeight: FontWeight.w700)),
  );
}
