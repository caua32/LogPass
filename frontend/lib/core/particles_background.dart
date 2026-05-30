import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  static const _cyan = Color(0xFF44CABD);

  _ParticlePainter(this.particles, {this.showLines = true});

  @override
  void paint(Canvas canvas, Size size) {
    if (showLines) {
      final linePaint = Paint()..strokeWidth = 0.6;
      for (int i = 0; i < particles.length; i++) {
        for (int j = i + 1; j < particles.length; j++) {
          final a = particles[i];
          final b = particles[j];
          final dx = a.x - b.x;
          final dy = a.y - b.y;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist < 0.18) {
            linePaint.color =
                _cyan.withValues(alpha: (1 - dist / 0.18) * 0.13);
            canvas.drawLine(
              Offset(a.x * size.width, a.y * size.height),
              Offset(b.x * size.width, b.y * size.height),
              linePaint,
            );
          }
        }
      }
    }

    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        Paint()
          ..color = _cyan.withValues(alpha: p.opacity)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            p.isGlow ? p.radius * 2.2 : p.radius * 0.7,
          ),
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
  late Ticker _ticker;
  late List<_Particle> _particles;
  Duration _lastElapsed = Duration.zero;
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
        // speed normalizado para 60fps
        speedX: (_random.nextDouble() - 0.5) * 0.00065,
        speedY: (_random.nextDouble() - 0.5) * 0.00065,
        opacity: isGlow
            ? _random.nextDouble() * 0.06 + 0.04
            : _random.nextDouble() * 0.35 + 0.20,
        isGlow: isGlow,
      );
    });

    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    // delta time normalizado para 60fps (16.67ms)
    final dt =
        (elapsed - _lastElapsed).inMicroseconds / 16667.0;
    _lastElapsed = elapsed;

    for (final p in _particles) {
      p.x += p.speedX * dt;
      p.y += p.speedY * dt;
      if (p.x < -0.05) p.x = 1.05;
      if (p.x > 1.05) p.x = -0.05;
      if (p.y < -0.05) p.y = 1.05;
      if (p.y > 1.05) p.y = -0.05;
    }
    // marca para repaint sem reconstruir widget
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ParticlePainter(_particles, showLines: widget.showLines),
        size: Size.infinite,
      ),
    );
  }
}
