import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/ball8.dart';
import '../widgets/gabon_flag.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _pin  = TextEditingController();
  final _nameFocus = FocusNode();
  final _pinFocus  = FocusNode();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    _nameFocus.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Ferme le clavier avant de soumettre
    FocusScope.of(context).unfocus();
    if (_name.text.trim().isEmpty || _pin.text.trim().isEmpty) {
      setState(() => _error = 'Prénom et code PIN requis.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final api = await ApiService.create();
      await api.login(_name.text.trim(), _pin.text.trim());
      if (mounted) Navigator.of(context).pushReplacementNamed('/queue');
    } on Exception catch (e) {
      String msg = 'Prénom ou PIN invalide.';
      final raw = e.toString();
      if (raw.contains('SocketException') ||
          raw.contains('connectTimeout') ||
          raw.contains('ClientException')) {
        msg = 'Serveur injoignable. Vérifiez votre connexion.';
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tape en dehors d'un champ → ferme le clavier
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: C8P.ink,
        // Le Scaffold se rétrécit quand le clavier apparaît
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            // Glisser vers le bas ferme aussi le clavier
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Ball8(size: 42),
                    GabonFlag(width: 24, height: 17),
                  ],
                ),
                const SizedBox(height: 48),

                // ── Titre ────────────────────────────────────────
                Text('CLUB 8 POOL',
                    style: C8PTypo.mono(size: 10, letterSpacing: 0.22)),
                const SizedBox(height: 14),
                Text('ESPACE', style: C8PTypo.disp(size: 52)),
                Text('ARBITRE', style: C8PTypo.disp(size: 52, color: C8P.felt2)),
                const SizedBox(height: 14),
                Text(
                  'Identifiez-vous avec votre prénom et votre code PIN.',
                  style: C8PTypo.sans(size: 13, color: C8P.chalk2),
                ),
                const SizedBox(height: 36),

                // ── Prénom ───────────────────────────────────────
                Text('PRÉNOM',
                    style: C8PTypo.mono(size: 9, letterSpacing: 0.2)),
                const SizedBox(height: 8),
                _input(
                  controller: _name,
                  focusNode: _nameFocus,
                  hint: 'Votre prénom',
                  action: TextInputAction.next,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_pinFocus),
                ),

                const SizedBox(height: 14),

                // ── Code PIN ─────────────────────────────────────
                Text('CODE PIN',
                    style: C8PTypo.mono(size: 9, letterSpacing: 0.2)),
                const SizedBox(height: 8),
                _input(
                  controller: _pin,
                  focusNode: _pinFocus,
                  hint: '•••••',
                  obscure: true,
                  action: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),

                // ── Erreur ───────────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!,
                      style: C8PTypo.mono(size: 10, color: C8P.live)),
                ],

                const SizedBox(height: 28),

                // ── Bouton connexion ─────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C8P.felt2,
                      foregroundColor: C8P.ink,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      _loading ? 'CONNEXION…' : 'SE CONNECTER',
                      style: C8PTypo.sans(
                              size: 13, color: C8P.ink,
                              weight: FontWeight.w800)
                          .copyWith(letterSpacing: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // ── Footer ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('VERSION 1.0.0',
                        style: C8PTypo.mono(size: 10, color: C8P.mute2)),
                    Text('● EN LIGNE',
                        style: C8PTypo.mono(size: 10, color: C8P.felt2)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required FocusNode focusNode,
    String? hint,
    bool obscure = false,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: C8P.ink2,
        border: Border.all(color: C8P.lineStrong),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        textInputAction: action,
        onSubmitted: onSubmitted,
        // Clavier numérique pour le PIN, textuel pour le prénom
        keyboardType: obscure ? TextInputType.number : TextInputType.text,
        textCapitalization: obscure
            ? TextCapitalization.none
            : TextCapitalization.words,
        inputFormatters:
            obscure ? [LengthLimitingTextInputFormatter(8)] : null,
        style: C8PTypo.mono(
            size: obscure ? 22 : 14,
            color: C8P.chalk,
            letterSpacing: obscure ? 0.4 : 0.06),
        textAlign: obscure ? TextAlign.center : TextAlign.start,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: C8PTypo.mono(size: 14, color: C8P.mute2),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
