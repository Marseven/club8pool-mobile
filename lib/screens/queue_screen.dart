import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  List _matches = [];
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
      final m = await api.queue();
      setState(() { _matches = m; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Erreur de chargement'; _loading = false; });
    }
  }

  String _fmtTime(String? iso) {
    if (iso == null) return '';
    final d = DateTime.parse(iso).toUtc();
    return '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
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
                    child: Text('OK', style: C8PTypo.sans(size: 13, weight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Olivier Kombila', style: C8PTypo.sans(size: 13, weight: FontWeight.w700)),
                      Text('ARBITRE NATIONAL', style: C8PTypo.mono(size: 9, letterSpacing: 0.14)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.logout, color: C8P.mute, size: 18),
                    onPressed: () async {
                      final api = await ApiService.create();
                      await api.logout();
                      if (mounted) Navigator.of(context).pushReplacementNamed('/');
                    },
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
                      Text('SAM. 06 JUIN', style: C8PTypo.mono(size: 10)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _stat('${_matches.length.toString().padLeft(2, '0')}', 'MATCHS', C8P.chalk),
                      const SizedBox(width: 20),
                      _stat('${live.toString().padLeft(2, '0')}', 'EN COURS', C8P.live),
                      const SizedBox(width: 20),
                      _stat('${done.toString().padLeft(2, '0')}', 'TERMINÉS', C8P.felt2),
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
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _matches.length,
                          itemBuilder: (_, i) => _matchCard(_matches[i]),
                        ),
            ),
            Container(height: 1, color: C8P.line),
            Container(
              color: C8P.ink2,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem('◰', 'MATCHS', true),
                  _navItem('▢', 'TABLES', false),
                  _navItem('○', 'PROFIL', false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                Text(_fmtTime(m['scheduled_at']), style: C8PTypo.disp(size: 24)),
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
            Text('${m['round']} · TABLE ${m['pool_table_id'] ?? '—'}',
                 style: C8PTypo.mono(size: 10, letterSpacing: 0.18)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${pa?['first_name']?[0]}. ${pa?['last_name']}',
                           style: C8PTypo.sans(size: 14, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${pb?['first_name']?[0]}. ${pb?['last_name']}',
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

  Widget _navItem(String icon, String label, bool active) => Column(
    children: [
      Text(icon, style: TextStyle(fontSize: 16, color: active ? C8P.felt2 : C8P.mute, height: 1)),
      const SizedBox(height: 4),
      Text(label, style: C8PTypo.mono(size: 10, color: active ? C8P.felt2 : C8P.mute, letterSpacing: 0.12)),
    ],
  );
}
