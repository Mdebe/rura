import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _phoneMode = false;
  bool _otpSent = false;
  String? _verificationId;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().loginWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (err != null) _error = err;
    });
  }

  Future<void> _loginGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (err != null) _error = err;
    });
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.isEmpty) {
      setState(() => _error = 'Enter phone number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().signInWithPhone(
      phone: _phoneCtrl.text,
      onCodeSent: (verId) {
        if (mounted) {
          setState(() {
            _verificationId = verId;
            _otpSent = true;
            _loading = false;
          });
        }
      },
    );
    if (err != null && mounted) {
      setState(() {
        _loading = false;
        _error = err;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.isEmpty || _verificationId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().verifyPhoneOtp(
      verificationId: _verificationId!,
      smsCode: _otpCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (err != null) _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.map, size: 80, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to GeoRura',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                if (!_phoneMode) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty ? 'Email required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    obscureText: _obscure,
                    validator: (v) => v!.isEmpty ? 'Password required' : null,
                  ),
                ] else ...[
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                      hintText: '+27123456789',
                    ),
                    keyboardType: TextInputType.phone,
                    enabled: !_otpSent,
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _otpCtrl,
                      decoration: const InputDecoration(
                        labelText: 'OTP Code',
                        prefixIcon: Icon(Icons.sms_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ],

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),

                if (!_phoneMode)
                  FilledButton(
                    onPressed: _loading ? null : _loginEmail,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Login'),
                  )
                else if (!_otpSent)
                  FilledButton(
                    onPressed: _loading ? null : _sendOtp,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send OTP'),
                  )
                else
                  FilledButton(
                    onPressed: _loading ? null : _verifyOtp,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Verify OTP'),
                  ),

                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _loginGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Continue with Google'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() {
                    _phoneMode = !_phoneMode;
                    _otpSent = false;
                    _error = null;
                  }),
                  child: Text(
                    _phoneMode ? 'Use Email Instead' : 'Use Phone Instead',
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
