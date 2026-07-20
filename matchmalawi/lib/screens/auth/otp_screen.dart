import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;

  late String _phoneNumber;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _phoneNumber =
        ModalRoute.of(context)!.settings.arguments as String;
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 30;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _resendOTP() {
    final auth = context.read<AuthProvider>();
    auth.sendOTP(
      phoneNumber: _phoneNumber,
      onCompleted: (_) {},
      onError: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      },
      onCodeSent: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP resent')),
          );
          _startTimer();
        }
      },
      onTimeout: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Timeout. Please try again.')),
          );
        }
      },
    );
  }

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  Future<void> _verifyOTP() async {
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full OTP')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOTP(_otpCode);
    if (success && mounted) {
      final route = auth.user != null ? '/main' : '/create-profile';
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.sms_outlined,
                size: 64,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Verification Code',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _phoneNumber,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 48,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey ==
                                LogicalKeyboardKey.backspace &&
                            _controllers[i].text.isEmpty &&
                            i > 0) {
                          _controllers[i - 1].clear();
                          _focusNodes[i - 1].requestFocus();
                        }
                      },
                      child: TextFormField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length == 1 && i < 5) {
                            _focusNodes[i + 1].requestFocus();
                          }
                          if (value.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                          }
                          if (_otpCode.length == 6) {
                            _verifyOTP();
                          }
                        },
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              if (auth.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    auth.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              GradientButton(
                text: 'Verify',
                onPressed: auth.isLoading ? () {} : () => _verifyOTP(),
                isLoading: auth.isLoading,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _canResend
                        ? "Didn't receive the code? "
                        : 'Resend code in ${_secondsRemaining}s',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  if (_canResend)
                    GestureDetector(
                      onTap: _resendOTP,
                      child: Text(
                        'Resend',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
