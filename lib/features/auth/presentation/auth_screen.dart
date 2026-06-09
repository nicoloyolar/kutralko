import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
      'rolPerfil': 'cliente',
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
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                KutralKoColors.carbon,
                KutralKoColors.obsidian,
                KutralKoColors.ink,
              ],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: KutralKoColors.gold.withValues(alpha: 0.32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: KutralKoColors.gold.withValues(alpha: 0.16),
                            blurRadius: 42,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/brand/kutral_ko_login_circle.png',
                        width: 156,
                        height: 156,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Kutral Ko',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: KutralKoColors.ivory,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Aplicación de gestión de reservas para restaurantes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: KutralKoColors.smoke.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
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
                              const _ClientRegistrationNotice(),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Correo electronico',
                                hintText: 'Ingrese su correo',
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
                                labelText: 'Contrasena',
                                hintText: 'Ingrese su contrasena',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  tooltip: _showPassword
                                      ? 'Ocultar'
                                      : 'Mostrar',
                                  onPressed: () {
                                    setState(
                                      () => _showPassword = !_showPassword,
                                    );
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
                                  color: KutralKoColors.orange,
                                  fontWeight: FontWeight.w800,
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
                              label: Text(
                                _isRegistering ? 'Crear cuenta' : 'Entrar',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientRegistrationNotice extends StatelessWidget {
  const _ClientRegistrationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KutralKoColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KutralKoColors.gold.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: KutralKoColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Las cuentas nuevas parten como cliente. Un administrador puede habilitar permisos despues.',
              style: TextStyle(
                color: KutralKoColors.smoke.withValues(alpha: 0.92),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
