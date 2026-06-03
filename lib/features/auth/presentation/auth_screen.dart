import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';

enum PerfilRegistro { administrador, cliente }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  PerfilRegistro _perfilRegistro = PerfilRegistro.administrador;
  bool _isRegistering = false;
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      UserCredential credential;

      if (_isRegistering) {
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _guardarPerfil(credential.user!, email);
      } else {
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _asegurarPerfil(credential.user!, email);
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _errorMessage = _authMessage(error));
    } on Object catch (error) {
      setState(() => _errorMessage = 'No se pudo ingresar: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _asegurarPerfil(User user, String email) async {
    final doc = FirebaseFirestore.instance.collection('perfiles').doc(user.uid);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      await _guardarPerfil(user, email);
    }
  }

  Future<void> _guardarPerfil(User user, String email) {
    return FirebaseFirestore.instance.collection('perfiles').doc(user.uid).set({
      'idPerfil': user.uid,
      'emailPerfil': email,
      'rolPerfil': _perfilRegistro.name,
      'fechaCreacionPerfil': FieldValue.serverTimestamp(),
      'estaActivoPerfil': true,
    }, SetOptions(merge: true));
  }

  String _authMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' => 'Ese correo ya esta registrado.',
      'invalid-email' => 'El correo no tiene un formato valido.',
      'user-not-found' => 'No existe una cuenta con ese correo.',
      'wrong-password' => 'La contrasena no coincide.',
      'weak-password' => 'Usa una contrasena de al menos 6 caracteres.',
      _ => error.message ?? 'No se pudo autenticar.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
          children: [
            Image.asset(
              'assets/brand/kutral_ko_logo_refined.png',
              height: 92,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              'Kutral Ko',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fuente de verdad para cuentas mensuales',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KutralKoColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.login_rounded),
                            label: Text('Ingresar'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.person_add_rounded),
                            label: Text('Crear'),
                          ),
                        ],
                        selected: {_isRegistering},
                        onSelectionChanged: (values) {
                          setState(() => _isRegistering = values.first);
                        },
                        showSelectedIcon: false,
                      ),
                      const SizedBox(height: 16),
                      if (_isRegistering) ...[
                        SegmentedButton<PerfilRegistro>(
                          segments: const [
                            ButtonSegment(
                              value: PerfilRegistro.administrador,
                              icon: Icon(Icons.admin_panel_settings_rounded),
                              label: Text('Admin'),
                            ),
                            ButtonSegment(
                              value: PerfilRegistro.cliente,
                              icon: Icon(Icons.person_rounded),
                              label: Text('Cliente'),
                            ),
                          ],
                          selected: {_perfilRegistro},
                          onSelectionChanged: (values) {
                            setState(() => _perfilRegistro = values.first);
                          },
                          showSelectedIcon: false,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'emailPerfil',
                          prefixIcon: Icon(Icons.mail_rounded),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa un correo.';
                          }
                          if (!value.contains('@')) {
                            return 'Correo invalido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'contrasenaPerfil',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            tooltip: _showPassword ? 'Ocultar' : 'Mostrar',
                            onPressed: () {
                              setState(() => _showPassword = !_showPassword);
                            },
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                          ),
                        ),
                        obscureText: !_showPassword,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Minimo 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: KutralKoColors.ember,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isRegistering
                                    ? Icons.person_add_rounded
                                    : Icons.login_rounded,
                              ),
                        label: Text(_isRegistering ? 'Crear cuenta' : 'Entrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
