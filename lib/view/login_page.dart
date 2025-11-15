import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/fetchuser.dart'; // ✅ perbaiki typo: "fetchuser"
import '../services/fetchdevice.dart';
import '../services/push_service.dart';
// import '../services/fetchnotifikasi.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _uidCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _uidCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uidStr = _uidCtrl.text.trim();
      final alamat = _alamatCtrl.text.trim();

      // 1) Cek user berdasarkan UID
      final userRow = await UserService.fetchUser(uidStr);
      if (userRow == null) {
        throw Exception('UID tidak ditemukan');
      }

      // 2) Simpan alamat
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('alamat', alamat);

      // 3) Ambil device — pastikan nama class benar!
      Fetchdevice.watchDevices(interval: const Duration(seconds: 5));

      // 4) Aktifkan FCM segera setelah login (token + permission + handlers)
      try {
        await PushService.initAndRegister();
        // Pastikan FCM token terdaftar setelah login
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login gagal: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _uidCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'UID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'UID wajib diisi';
                    }
                    if (int.tryParse(v.trim()) == null) {
                      return 'UID harus angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _alamatCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    return (v == null || v.trim().isEmpty)
                        ? 'Alamat wajib diisi'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Masuk'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
