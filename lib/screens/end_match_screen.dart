import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class EndMatchScreen extends StatefulWidget {
  final Map match;
  const EndMatchScreen({super.key, required this.match});

  @override
  State<EndMatchScreen> createState() => _EndMatchScreenState();
}

class _EndMatchScreenState extends State<EndMatchScreen> {
  final Set<int> _signed = {};

  Future<void> _sign(int playerId) async {
    try {
      final api = await ApiService.create();
      await api.sign(widget.match['id'], playerId);
      setState(() => _signed.add(playerId));
    } catch (_) {}
  }

  Future<void> _validate() async {
    try {
      final api = await ApiService.create();
      await api.end(widget.match['id'], null);
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/queue', (_) => false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pa = widget.match['player_a'];
    final pb = widget.match['player_b'];
    final scoreA = widget.match['score_a'] ?? 0;
    final scoreB = widget.match['score_b'] ?? 0;
    final allSigned = _signed.contains(pa?['id']) && _signed.contains(pb?['id']);

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
                      Text('✓ MATCH TERMINÉ', style: C8PTypo.mono(size: 9, color: C8P.felt2, letterSpacing: 0.22)),
                      const SizedBox(height: 2),
                      Text('Validation', style: C8PTypo.sans(size: 13, weight: FontWeight.w700)),
                    ],
                  ),
                  const Icon(Icons.more_vert, color: C8P.mute, size: 22),
                ],
              ),
            ),
            Container(height: 1, color: C8P.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${widget.match['round']} · TABLE 1',
                       style: C8PTypo.mono(size: 9, letterSpacing: 0.22)),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pa?['last_name'] ?? '', style: C8PTypo.sans(size: 13, weight: FontWeight.w700)),
                            Text(scoreA.toString(),
                                 style: C8PTypo.disp(size: 72, color: scoreA > scoreB ? C8P.felt2 : C8P.chalk2)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Text('—', style: C8PTypo.disp(size: 36, color: C8P.mute2)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(pb?['last_name'] ?? '',
                                 style: C8PTypo.sans(size: 13, color: C8P.chalk2, weight: FontWeight.w700)),
                            Text(scoreB.toString(),
                                 style: C8PTypo.disp(size: 72, color: scoreB > scoreA ? C8P.felt2 : C8P.chalk2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('DURÉE 01:08:42', style: C8PTypo.mono(size: 10, letterSpacing: 0.14)),
                      Text('${scoreA + scoreB} FRAMES', style: C8PTypo.mono(size: 10, letterSpacing: 0.14)),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 1, color: C8P.line),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SIGNATURES DES JOUEURS',
                         style: C8PTypo.mono(size: 10, letterSpacing: 0.22)),
                    const SizedBox(height: 10),
                    for (final p in [pa, pb]) _signatureCard(p),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: C8P.line),
            Container(
              color: C8P.ink2,
              padding: const EdgeInsets.all(22),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: allSigned ? _validate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C8P.felt2,
                    foregroundColor: C8P.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    disabledBackgroundColor: const Color(0x44FFFFFF),
                  ),
                  child: Text(
                    allSigned ? 'VALIDER & ENVOYER' : '${2 - _signed.length} SIGNATURE(S) MANQUANTE(S)',
                    style: C8PTypo.sans(size: 13, color: allSigned ? C8P.ink : C8P.mute, weight: FontWeight.w800)
                      .copyWith(letterSpacing: 1.2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signatureCard(Map? p) {
    final isSigned = _signed.contains(p?['id']);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSigned ? const Color(0x0A2DA876) : C8P.ink2,
        border: Border.all(color: isSigned ? const Color(0x662DA876) : C8P.lineStrong),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${p?['first_name']} ${p?['last_name']}',
                   style: C8PTypo.sans(size: 12, weight: FontWeight.w700)),
              Text(isSigned ? '✓ SIGNÉ' : '⚠ EN ATTENTE',
                   style: C8PTypo.mono(size: 9, color: isSigned ? C8P.felt2 : C8P.live, letterSpacing: 0.14)),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: isSigned ? null : () => _sign(p?['id']),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: C8P.ink,
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              alignment: Alignment.center,
              child: Text(
                isSigned ? '✓' : 'Toucher pour signer',
                style: TextStyle(
                  fontSize: isSigned ? 32 : 14,
                  color: isSigned ? C8P.felt2 : C8P.mute2,
                  fontFamily: 'cursive',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
