import 'dart:math';
import 'package:flutter/material.dart';

class _Particle {
  double x, y, radius, speedX, speedY, opacity;
  _Particle({
    required this.x, required this.y, required this.radius,
    required this.speedX, required this.speedY, required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = const Color(0xFF4CE0D2).withValues(alpha: p.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 1.5);
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
  const ParticlesBackground({super.key, this.count = 30});

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
    _particles = List.generate(widget.count, (_) => _Particle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      radius: _random.nextDouble() * 10 + 3,
      speedX: (_random.nextDouble() - 0.5) * 0.00025,
      speedY: (_random.nextDouble() - 0.5) * 0.00025,
      opacity: _random.nextDouble() * 0.10 + 0.03,
    ));
    _ctrl = AnimationController(duration: const Duration(seconds: 1), vsync: this)
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
        painter: _ParticlePainter(_particles),
        size: Size.infinite,
      ),
    );
  }
}
