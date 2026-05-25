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
  final _card = TextEditingController();
  final _pin = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = await ApiService.create();
      await api.login(_card.text.trim(), _pin.text.trim());
      if (mounted) Navigator.of(context).pushReplacementNamed('/queue');
    } on Exception catch (e) {
      String msg = 'Identifiants invalides';
      final raw = e.toString();
      if (raw.contains('SocketException') || raw.contains('connectTimeout') || raw.contains('ClientException')) {
        msg = 'Serveur injoignable. Vérifiez votre connexion.';
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemo(String card) {
    _card.text = card;
    _pin.text = '12345';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C8P.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Ball8(size: 42),
                  GabonFlag(width: 24, height: 17),
                ],
              ),
              const SizedBox(height: 56),
              Text('CLUB 8 POOL', style: C8PTypo.mono(size: 10, letterSpacing: 0.22)),
              const SizedBox(height: 14),
              Text('ESPACE', style: C8PTypo.disp(size: 56)),
              Text('ARBITRE', style: C8PTypo.disp(size: 56, color: C8P.felt2)),
              const SizedBox(height: 16),
              Text(
                'Connectez-vous pour rejoindre les matchs qui vous sont assignés aujourd\'hui.',
                style: C8PTypo.sans(size: 13, color: C8P.chalk2),
              ),
              const SizedBox(height: 36),
              Text('CARTE FGB', style: C8PTypo.mono(size: 9, letterSpacing: 0.2)),
              const SizedBox(height: 8),
              _input(_card, hint: 'ICN-ARB-XXX'),
              const SizedBox(height: 14),
              Text('CODE PIN', style: C8PTypo.mono(size: 9, letterSpacing: 0.2)),
              const SizedBox(height: 8),
              _input(_pin, hint: '•••••', obscure: true),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: C8PTypo.mono(size: 10, color: C8P.live)),
              ],
              const SizedBox(height: 16),
              Wrap(spacing: 8, children: [
                _demoChip('Eric', 'ICN-ARB-001'),
                _demoChip('T-One', 'ICN-ARB-002'),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C8P.felt2,
                    foregroundColor: C8P.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    _loading ? 'CONNEXION…' : 'SE CONNECTER',
                    style: C8PTypo.sans(size: 13, color: C8P.ink, weight: FontWeight.w800).copyWith(letterSpacing: 1.5),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('VERSION 1.0.0', style: C8PTypo.mono(size: 10, color: C8P.mute2)),
                  Text('● EN LIGNE', style: C8PTypo.mono(size: 10, color: C8P.felt2)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, {String? hint, bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: C8P.ink2,
        border: Border.all(color: C8P.lineStrong),
      ),
      child: TextField(
        controller: c,
        obscureText: obscure,
        style: C8PTypo.mono(size: 14, color: C8P.chalk, letterSpacing: 0.06),
        inputFormatters: obscure ? [LengthLimitingTextInputFormatter(8)] : null,
        keyboardType: obscure ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: C8PTypo.mono(size: 14, color: C8P.mute2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _demoChip(String label, String card) {
    return InkWell(
      onTap: () => _fillDemo(card),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: C8P.lineStrong),
          color: C8P.ink2,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: C8PTypo.sans(size: 11, color: C8P.chalk, weight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(card, style: C8PTypo.mono(size: 9, color: C8P.mute)),
        ]),
      ),
    );
  }
}
