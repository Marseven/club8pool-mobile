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
  late Map _match;
  final Set<int> _signed = {};
  bool _validating = false;

  @override
  void initState() {
    super.initState();
    _match = Map.from(widget.match);
    // Pre-populate signatures already recorded on server
    final sigs = _match['signatures'] as List? ?? [];
    for (final s in sigs) {
      final pid = s['player_id'];
      if (pid != null) _signed.add(pid as int);
    }
  }

  bool get _allSigned {
    final pa = _match['player_a'];
    final pb = _match['player_b'];
    final idA = pa?['id'];
    final idB = pb?['id'];
    if (idA == null || idB == null) return false;
    return _signed.contains(idA) && _signed.contains(idB);
  }

  Future<void> _sign(int playerId) async {
    try {
      final api = await ApiService.create();
      await api.sign(_match['id'] as int, playerId);
      if (mounted) setState(() => _signed.add(playerId));
    } catch (_) {}
  }

  Future<void> _validate() async {
    setState(() => _validating = true);
    try {
      final api = await ApiService.create();
      await api.end(_match['id'] as int, null);
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/queue', (_) => false);
    } catch (e) {
      if (mounted) {
        setState(() => _validating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: C8P.ink2,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Erreur de clôture — réessayez.',
            style: C8PTypo.mono(size: 11, color: C8P.live),
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pa = _match['player_a'];
    final pb = _match['player_b'];
    final scoreA = (_match['score_a'] ?? 0) as int;
    final scoreB = (_match['score_b'] ?? 0) as int;
    final elapsed = _match['_elapsed'] as String?;
    final pool = _match['pool'];
    final table = _match['table'];

    return PopScope(
      // Block hardware back once both players have signed
      canPop: !_allSigned,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: C8P.ink2,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Signatures enregistrées. Appuyez sur VALIDER pour finaliser.',
              style: C8PTypo.mono(size: 11, color: C8P.chalk2),
            ),
            duration: const Duration(seconds: 3),
          ));
        }
      },
      child: Scaffold(
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
                    // Back arrow — only shown before both sign
                    if (!_allSigned)
                      IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back, color: C8P.mute, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    else
                      const SizedBox(width: 40),
                    Column(
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.check_circle_outline, size: 12, color: C8P.felt2),
                          const SizedBox(width: 4),
                          Text('MATCH TERMINÉ',
                              style: C8PTypo.mono(size: 9, color: C8P.felt2, letterSpacing: 0.22)),
                        ]),
                        const SizedBox(height: 2),
                        Text('Validation', style: C8PTypo.sans(size: 13, weight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Container(height: 1, color: C8P.line),

              // ── Score recap ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pool?['name'] ?? _match['round'] ?? '—'} · '
                      '${table?['name']?.toString().toUpperCase() ?? 'TABLE —'}',
                      style: C8PTypo.mono(size: 9, letterSpacing: 0.22),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pa?['last_name'] ?? '—',
                                  style: C8PTypo.sans(size: 13, weight: FontWeight.w700)),
                              Text(scoreA.toString(),
                                  style: C8PTypo.disp(
                                      size: 72,
                                      color: scoreA > scoreB ? C8P.felt2 : C8P.chalk2)),
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
                              Text(pb?['last_name'] ?? '—',
                                  style: C8PTypo.sans(
                                      size: 13, color: C8P.chalk2, weight: FontWeight.w700)),
                              Text(scoreB.toString(),
                                  style: C8PTypo.disp(
                                      size: 72,
                                      color: scoreB > scoreA ? C8P.felt2 : C8P.chalk2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (elapsed != null)
                          Text('DURÉE $elapsed',
                              style: C8PTypo.mono(size: 10, letterSpacing: 0.14)),
                        Text('${scoreA + scoreB} FRAMES',
                            style: C8PTypo.mono(size: 10, letterSpacing: 0.14)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: C8P.line),

              // ── Signatures ──────────────────────────────────────────
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

              // ── Validate button ─────────────────────────────────────
              Container(height: 1, color: C8P.line),
              Container(
                color: C8P.ink2,
                padding: const EdgeInsets.all(22),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_allSigned && !_validating) ? _validate : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C8P.felt2,
                      foregroundColor: C8P.ink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      disabledBackgroundColor: const Color(0x44FFFFFF),
                    ),
                    child: _validating
                        ? const SizedBox(
                            height: 16, width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: C8P.ink))
                        : Text(
                            _allSigned
                                ? 'VALIDER & ENVOYER'
                                : '${2 - _signed.length} SIGNATURE(S) MANQUANTE(S)',
                            style: C8PTypo.sans(
                                    size: 13,
                                    color: _allSigned ? C8P.ink : C8P.mute,
                                    weight: FontWeight.w800)
                                .copyWith(letterSpacing: 1.2),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _signatureCard(Map? p) {
    final id = p?['id'] as int?;
    final isSigned = id != null && _signed.contains(id);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSigned ? const Color(0x0A2DA876) : C8P.ink2,
        border: Border.all(
            color: isSigned ? const Color(0x662DA876) : C8P.lineStrong),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${p?['first_name'] ?? ''} ${p?['last_name'] ?? ''}'.trim(),
                  style: C8PTypo.sans(size: 12, weight: FontWeight.w700)),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (isSigned) ...[
                  const Icon(Icons.check, size: 9, color: C8P.felt2),
                  const SizedBox(width: 3),
                  Text('SIGNÉ',
                      style: C8PTypo.mono(
                          size: 9, color: C8P.felt2, letterSpacing: 0.14)),
                ] else ...[
                  const Icon(Icons.schedule, size: 9, color: C8P.live),
                  const SizedBox(width: 3),
                  Text('EN ATTENTE',
                      style: C8PTypo.mono(
                          size: 9, color: C8P.live, letterSpacing: 0.14)),
                ],
              ]),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: (isSigned || id == null) ? null : () => _sign(id),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: C8P.ink,
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              alignment: Alignment.center,
              child: isSigned
                  ? const Icon(Icons.check, size: 36, color: C8P.felt2)
                  : Text(
                      'Toucher pour signer',
                      style: TextStyle(
                        fontSize: 14,
                        color: C8P.mute2,
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
