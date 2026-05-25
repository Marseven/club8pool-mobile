import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = [
      {'type': 'FRAME', 'label': 'Frame 9 · Mboumba +1', 'time': '17:31:04', 'state': 'pending'},
      {'type': 'FAUTE', 'label': 'Faute · Ndjavé', 'time': '17:29:48', 'state': 'pending'},
      {'type': 'FRAME', 'label': 'Frame 8 · Mboumba +1', 'time': '17:24:12', 'state': 'pending'},
      {'type': 'CHRONO', 'label': 'Extension +30 · Ndjavé', 'time': '17:22:51', 'state': 'pending'},
      {'type': 'FRAME', 'label': 'Frame 7 · Ndjavé +1', 'time': '17:18:30', 'state': 'failed'},
      {'type': 'FRAME', 'label': 'Frame 6 · Mboumba +1', 'time': '17:14:02', 'state': 'pending'},
      {'type': 'FRAME', 'label': 'Frame 5 · Mboumba +1', 'time': '17:08:17', 'state': 'pending'},
    ];

    return Scaffold(
      backgroundColor: C8P.ink,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0x1FE5484D),
                border: Border(bottom: BorderSide(color: Color(0x4DE5484D))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('● HORS-LIGNE DEPUIS 04:18',
                       style: C8PTypo.mono(size: 10, color: C8P.live, letterSpacing: 0.16).copyWith(fontWeight: FontWeight.w700)),
                  Text('RÉSEAU 4G PERDU', style: C8PTypo.mono(size: 10, color: C8P.chalk2, letterSpacing: 0.14)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SYNCHRO EN ATTENTE', style: C8PTypo.disp(size: 32)),
                  const SizedBox(height: 6),
                  Text(
                    'Vos saisies sont enregistrées localement. Elles seront poussées au serveur dès que le réseau revient.',
                    style: C8PTypo.sans(size: 12, color: C8P.chalk2),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: C8P.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
              child: Row(
                children: [
                  Expanded(child: _statCard('EN ATTENTE', '07', C8P.live)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('SYNCHRO. OK', '42', C8P.felt2)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('POIDS', '8kb', C8P.chalk)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("FILE D'ATTENTE", style: C8PTypo.mono(size: 10, letterSpacing: 0.22)),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                itemCount: queue.length,
                separatorBuilder: (_, __) => Container(height: 1, color: const Color(0x0FFFFFFF)),
                itemBuilder: (_, i) {
                  final e = queue[i];
                  final isFailed = e['state'] == 'failed';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFailed ? C8P.live : C8P.chalk2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 60,
                          child: Text(e['type']!, style: C8PTypo.mono(size: 9, letterSpacing: 0.14)),
                        ),
                        Expanded(
                          child: Text(e['label']!,
                               style: C8PTypo.sans(size: 12, color: isFailed ? C8P.live : C8P.chalk)),
                        ),
                        Text(e['time']!, style: C8PTypo.mono(size: 10)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(height: 1, color: C8P.line),
            Container(
              color: C8P.ink2,
              padding: const EdgeInsets.all(22),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: C8P.lineStrong),
                    foregroundColor: C8P.chalk,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('⟳ FORCER UNE NOUVELLE TENTATIVE',
                       style: C8PTypo.sans(size: 12, weight: FontWeight.w700).copyWith(letterSpacing: 1.2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color c) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: C8P.ink2, border: Border.all(color: C8P.line)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: C8PTypo.mono(size: 9, letterSpacing: 0.22)),
        const SizedBox(height: 6),
        Text(value, style: C8PTypo.disp(size: 40, color: c)),
      ],
    ),
  );
}
