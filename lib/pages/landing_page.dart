import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_route.dart';
import '../providers/subscription_provider.dart';

/// Quiz Apps subscription landing page.
/// Mirrors the visual layout from the reference image but uses a unique palette
/// (deep teal / amber / soft cream) instead of any well-known brand colors.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Custom palette — intentionally not aligned with any major brand.
  static const Color _ink = Color(0xFF0F2A2D);
  static const Color _teal = Color(0xFF1F6F6B);
  static const Color _amber = Color(0xFFE8A33D);
  static const Color _cream = Color(0xFFFBF3E1);
  static const Color _muted = Color(0xFF6F8484);

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // OTP verify সফল হলে SubscriptionProvider.subscribed state-এ
    // যাবে — সেই মুহূর্তে home page-এ navigate করো।
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sub = context.read<SubscriptionProvider>();
      sub.addListener(_handleSubscriptionChange);
      if (sub.isSubscribed) {
        _handleSubscriptionChange();
      }
    });
  }

  void _handleSubscriptionChange() {
    if (!mounted) return;
    final sub = context.read<SubscriptionProvider>();
    if (sub.isSubscribed && sub.state == SubscriptionState.subscribed) {
      context.go(AppRoute.home);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider listener attach করার নিরাপদ জায়গা।
    context.read<SubscriptionProvider>().addListener(_handleSubscriptionChange);
  }

  void _removeListener() {
    try {
      context.read<SubscriptionProvider>().removeListener(_handleSubscriptionChange);
    } catch (_) {
      // Provider disposed — ignore।
    }
  }

  Future<void> _onSubscribe(SubscriptionProvider provider) async {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) return;

    final formatted = _normalizePhone(raw);
    _phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    try {
      await provider.sendOtp(formatted);
    } catch (e) {
      debugPrint("OTP Send Error: $e");
    }
  }

  Future<void> _onVerify(SubscriptionProvider provider) async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    try {
      await provider.verifyOtp(otp);
    } catch (e) {
      debugPrint("OTP Verify Error: $e");
    }
  }

  // Unsubscribe intentionally lives only on the Profile page. The landing
  // page just surfaces the "already registered" error message (which now
  // points the user to Profile) — no inline unsubscribe action here, to
  // avoid a second, easy-to-miss unsubscribe entry point.

  String _normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 13 && digits.startsWith('8801')) {
      return '0${digits.substring(3)}';
    }
    if (digits.length == 12 && digits.startsWith('88')) {
      return '0${digits.substring(2)}';
    }
    if (digits.length == 10 && !digits.startsWith('0')) {
      return '0$digits';
    }
    return digits;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();
    final priceLabel = '৳ 2.78 / দিন';

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 720;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _brandHeader(),
                  const SizedBox(height: 24),
                  if (isWide)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _pitchCard(priceLabel)),
                          const SizedBox(width: 20),
                          Expanded(child: _actionCard(provider)),
                        ],
                      ),
                    )
                  else ...[
                    _pitchCard(priceLabel),
                    const SizedBox(height: 20),
                    _actionCard(provider),
                  ],
                  const SizedBox(height: 28),
                  _footer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _brandHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_teal, _amber],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.psychology_alt_outlined,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Quiz Apps',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'বাংলা ভাষায় দৈনিক কুইজ চ্যালেঞ্জ',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pitchCard(String priceLabel) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEADFC2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'BDApps পার্টনার',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _teal,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'যেখানেই থাকুন, গল্প, সুরা ও\nঅনুভব শেয়ার হোক এক জায়গায়',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'দৈনিক কুইজ খেলুন, পয়েন্ট জমান এবং লিডারবোর্ডে নিজের\nঅবস্থান দেখুন — সব মাত্র ২.৭৮ টাকায়।',
            style: TextStyle(
              fontSize: 14,
              color: _muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          _feature(Icons.menu_book_outlined, 'বিষয়ভিত্তিক কুইজ'),
          const SizedBox(height: 10),
          _feature(Icons.emoji_events_outlined, 'রিয়েল-টাইম স্কোরবোর্ড'),
          const SizedBox(height: 10),
          _feature(Icons.bolt_outlined, '২৪ ঘণ্টা OTP ভেরিফিকেশন'),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    color: _teal,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'সাবস্ক্রিপশন ফি',
                      style: TextStyle(
                        fontSize: 12,
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      priceLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feature(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _amber.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _ink, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: _ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionCard(SubscriptionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.quiz_outlined,
                  color: _teal,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'কুইজ অ্যাপ\nআপনার জ্ঞানকে প্রসারিত করুন',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'মোবাইল নম্বর',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _phoneController,
                  enabled: !provider.isLoading &&
                      provider.state != SubscriptionState.inputOtp,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(13),
                  ],
                  decoration: InputDecoration(
                    hintText: '01XXXXXXXXX',
                    hintStyle: const TextStyle(color: Color(0xFF8FA4A4)),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.phone_android,
                      color: _teal,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (provider.state == SubscriptionState.inputOtp) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 20,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      hintText: 'OTP কোড',
                      hintStyle: const TextStyle(
                        color: Color(0xFF8FA4A4),
                        letterSpacing: 0,
                        fontWeight: FontWeight.normal,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (provider.errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      provider.errorMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () {
                if (provider.state ==
                    SubscriptionState.inputOtp) {
                  _onVerify(provider);
                } else {
                  _onSubscribe(provider);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                foregroundColor: _ink,
                disabledBackgroundColor: _amber.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: provider.isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: _ink,
                ),
              )
                  : Text(
                provider.state == SubscriptionState.inputOtp
                    ? 'ভেরিফাই করুন'
                    : 'Subscribe করুন',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (provider.state == SubscriptionState.inputOtp)
            TextButton(
              onPressed: provider.isLoading
                  ? null
                  : () {
                _otpController.clear();
                provider.reset();
              },
              child: const Text(
                'নম্বর পরিবর্তন করুন',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const Text(
              'সবুজ করার মাধ্যমে আপনি আমাদের\nশর্তাবলী ও গোপনীয়তা নীতিতে সম্মতি দিচ্ছেন।',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADFC2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF6B57), Color(0xFFE8A33D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(Icons.bolt, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'সহযোগিতায়',
                  style: TextStyle(
                    fontSize: 11,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'BDApps • Bangladesh Telecommunication',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: null,
            child: const Text(
              'SMS সাবস্ক্রাইব করে প্রবেশ করুন',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}