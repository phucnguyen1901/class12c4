import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Two-tier password (client-side only; not for real secrets).
const String kViewerPassword = '12c4';
const String kAdminPassword = 'admin12c4';

enum UnlockMode { viewer, admin }

class LockOverlay extends StatefulWidget {
  const LockOverlay({super.key, required this.onUnlocked});

  final void Function(UnlockMode mode) onUnlocked;

  @override
  State<LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends State<LockOverlay>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final AnimationController _shakeCtrl;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _tryUnlock() {
    final value = _controller.text.trim();
    if (value == kAdminPassword) {
      HapticFeedback.lightImpact();
      widget.onUnlocked(UnlockMode.admin);
      return;
    }
    if (value == kViewerPassword) {
      HapticFeedback.lightImpact();
      widget.onUnlocked(UnlockMode.viewer);
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _wrong = true);
    _shakeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: shake,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(shake.value, 0),
                  child: child,
                );
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0.06),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.violet.withValues(alpha: 0.35),
                            blurRadius: 40,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Lớp 12C4',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Nhập mật khẩu để xem kỷ niệm',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            obscureText: true,
                            autofocus: true,
                            textInputAction: TextInputAction.go,
                            onChanged: (_) {
                              if (_wrong) setState(() => _wrong = false);
                            },
                            onSubmitted: (_) => _tryUnlock(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 2,
                            ),
                            decoration: InputDecoration(
                              hintText: '••••',
                              prefixIcon: const Icon(
                                Icons.key_rounded,
                                color: Colors.white54,
                              ),
                              errorText: _wrong ? 'Sai mật khẩu' : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _tryUnlock,
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppTheme.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Mở khoá',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
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
            ),
          ),
        ],
      ),
    );
  }
}
