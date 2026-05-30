import 'dart:math';
import 'package:flutter/material.dart';

class _Particle {
  double x, y, radius, speedX, speedY, opacity;
  bool isGlow;
  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedX,
    required this.speedY,
    required this.opacity,
    required this.isGlow,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final bool showLines;
  static const _cyan = Color(0xFF4CE0D2);

  _ParticlePainter(this.particles, {this.showLines = true});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connection lines between nearby particles
    if (showLines) {
      for (int i = 0; i < particles.length; i++) {
        for (int j = i + 1; j < particles.length; j++) {
          final a = particles[i];
          final b = particles[j];
          final dx = a.x - b.x;
          final dy = a.y - b.y;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist < 0.18) {
            final lineOpacity = (1 - dist / 0.18) * 0.12;
            final linePaint = Paint()
              ..color = _cyan.withValues(alpha: lineOpacity)
              ..strokeWidth = 0.5;
            canvas.drawLine(
              Offset(a.x * size.width, a.y * size.height),
              Offset(b.x * size.width, b.y * size.height),
              linePaint,
            );
          }
        }
      }
    }

    // Draw particles
    for (final p in particles) {
      final paint = Paint()
        ..color = _cyan.withValues(alpha: p.opacity)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          p.isGlow ? p.radius * 2.5 : p.radius * 0.8,
        );
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

class ParticlesBackground extends StatefulWidget {
  final int count;
  final bool showLines;

  const ParticlesBackground({super.key, this.count = 45, this.showLines = true});

  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.count, (i) {
      final isGlow = i < widget.count ~/ 3;
      return _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: isGlow
            ? _random.nextDouble() * 12 + 8
            : _random.nextDouble() * 2 + 1.5,
        speedX: (_random.nextDouble() - 0.5) * 0.0010,
        speedY: (_random.nextDouble() - 0.5) * 0.0010,
        opacity: isGlow
            ? _random.nextDouble() * 0.06 + 0.04
            : _random.nextDouble() * 0.35 + 0.20,
        isGlow: isGlow,
      );
    });
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    )
      ..addListener(_update)
      ..repeat();
  }

  void _update() {
    for (final p in _particles) {
      p.x += p.speedX;
      p.y += p.speedY;
      if (p.x < -0.05) p.x = 1.05;
      if (p.x > 1.05) p.x = -0.05;
      if (p.y < -0.05) p.y = 1.05;
      if (p.y > 1.05) p.y = -0.05;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _ParticlePainter(_particles, showLines: widget.showLines),
        size: Size.infinite,
      ),
    );
  }
}
