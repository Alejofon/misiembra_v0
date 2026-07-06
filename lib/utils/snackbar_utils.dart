import 'dart:async';
import 'package:flutter/material.dart';

/// Notificación tipo "toast" que aparece en la parte SUPERIOR de la pantalla.
///
/// Antes esto usaba un SnackBar con behavior.floating, pero Flutter ancla los
/// SnackBar SIEMPRE al borde inferior (el margin.top no los sube), y quedaba
/// justo encima de los botones "Continuar"/"Consultar recomendaciones",
/// tapándolos. Este helper usa un Overlay propio posicionado arriba, con
/// animación de entrada/salida y auto-cierre. La firma se mantiene igual para
/// no tocar los lugares que ya lo llaman.
OverlayEntry? _currentTopToast;

void showTopSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);

  // Quitar cualquier toast anterior antes de mostrar el nuevo (equivalente al
  // hideCurrentSnackBar que hacía la versión con SnackBar).
  _currentTopToast?.remove();
  _currentTopToast = null;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _TopToast(
      message: message,
      backgroundColor: backgroundColor ?? Colors.green.shade700,
      duration: duration,
      onDismissed: () {
        if (_currentTopToast == entry) {
          _currentTopToast = null;
        }
        entry.remove();
      },
    ),
  );

  _currentTopToast = entry;
  overlay.insert(entry);
}

class _TopToast extends StatefulWidget {
  const _TopToast({
    required this.message,
    required this.backgroundColor,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _autoCloseTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _autoCloseTimer = Timer(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_dismissed) return;
    _dismissed = true;
    _autoCloseTimer?.cancel();
    if (mounted) {
      await _controller.reverse();
    }
    widget.onDismissed();
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topInset + 12,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _close,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
