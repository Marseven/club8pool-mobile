import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class PreMatchScreen extends StatelessWidget {
  final Map match;
  const PreMatchScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final pa = match['player_a'];
    final pb = match['player_b'];

    return Scaffold(
      backgroundColor: C8P.ink,
      body: SafeArea(
        child: Column(
          children: [
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
                  Column(
                    children: [
                      Text('TABLE 1 · ${match['round']}', style: C8PTypo.mono(size: 9, letterSpacing: 0.22)),
                      const SizedBox(height: 2),
                      Text('Pré-match', style: C8PTypo.sans(size: 13, weight: FontWeight.w700)),
                    ],
                  ),
                  const Icon(Icons.more_vert, color: C8P.mute, size: 22),
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
                    Container(
                      decoration: BoxDecoration(
                        color: C8P.ink2,
                        border: Border.all(color: C8P.line),
                      ),
                      child: Column(
                        children: [
                          _playerRow(pa, true),
                          Container(height: 1, color: C8P.line),
                          _playerRow(pb, false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('QUI CASSE EN PREMIER ?', style: C8PTypo.mono(size: 10, letterSpacing: 0.22)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _breakBtn(pa?['last_name'] ?? '', 'SEED HAUT · STANDARD', true)),
                        const SizedBox(width: 10),
                        Expanded(child: _breakBtn(pb?['last_name'] ?? '', 'SEED BAS', false)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text('RÉGLAGES', style: C8PTypo.mono(size: 10, letterSpacing: 0.22)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: C8P.ink2,
                        border: Border.all(color: C8P.line),
                      ),
                      child: Column(
                        children: [
                          _settingRow('Race to', '7', first: true),
                          _settingRow('Shot clock', '30 sec'),
                          _settingRow('Extension', '×1 / joueur'),
                          _settingRow('Break', 'Alterné'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: C8P.line),
            Container(
              color: C8P.ink2,
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/live', arguments: match),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C8P.felt2,
                    foregroundColor: C8P.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text('▸ DÉMARRER LE MATCH',
                       style: C8PTypo.sans(size: 14, color: C8P.ink, weight: FontWeight.w800).copyWith(letterSpacing: 1.4)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerRow(Map? p, bool breaking) {
    return Container(
      padding: const EdgeInsets.all(18),
      color: breaking ? const Color(0x0D2DA876) : Colors.transparent,
      child: Row(
        children: [
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p?['first_name']} ${p?['last_name']}', style: C8PTypo.sans(size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('SEED #${p?['id']} · ELO ${p?['rating']}',
                     style: C8PTypo.mono(size: 10, letterSpacing: 0.14)),
              ],
            ),
          ),
          if (breaking)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(color: C8P.felt2),
              child: Text('BREAK', style: C8PTypo.mono(size: 9, color: C8P.ink, letterSpacing: 0.1).copyWith(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _breakBtn(String name, String sub, bool active) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? const Color(0x142DA876) : Colors.transparent,
        border: Border.all(color: active ? C8P.felt2 : C8P.lineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(active ? '✓ CHOIX ARBITRE' : 'OU',
               style: C8PTypo.mono(size: 9, color: active ? C8P.felt2 : C8P.mute, letterSpacing: 0.14)),
          const SizedBox(height: 6),
          Text(name, style: C8PTypo.sans(size: 13, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub, style: C8PTypo.mono(size: 9)),
        ],
      ),
    );
  }

  Widget _settingRow(String k, String v, {bool first = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: first ? null : const Border(top: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: C8PTypo.sans(size: 12, color: C8P.chalk2)),
          Text(v, style: C8PTypo.mono(size: 13, color: C8P.chalk).copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
