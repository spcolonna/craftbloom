import 'dart:math';
import 'package:flutter/material.dart';
import 'package:craftbloom/core/theme/seasonal_theme.dart';

class SeasonalBackground extends StatefulWidget {
  final SeasonalTheme theme;
  final Widget child;

  const SeasonalBackground({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  State<SeasonalBackground> createState() => _SeasonalBackgroundState();
}

class _SeasonalBackgroundState extends State<SeasonalBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  static const _particleCount = 28;

  @override
  void initState() {
    super.initState();
    _particles = _buildParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void didUpdateWidget(SeasonalBackground old) {
    super.didUpdateWidget(old);
    if (old.theme != widget.theme) {
      _particles = _buildParticles();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Particle> _buildParticles() {
    final r = Random();
    return List.generate(_particleCount, (_) => _Particle.random(r));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.theme == SeasonalTheme.normal) return widget.child;

    final palette = getPalette(widget.theme);
    final c1 = palette.particleColor1 ?? palette.primary;
    final c2 = palette.particleColor2 ?? palette.secondary;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, _) {
                for (final p in _particles) {
                  p.step(widget.theme);
                }
                return CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    theme: widget.theme,
                    color1: c1,
                    color2: c2,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Partícula
// ─────────────────────────────────────────────────────────────────────────────

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double drift;
  double rotation;
  double rotationSpeed;
  double opacity;
  bool useColor2;

  _Particle.random(Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        size = 7 + r.nextDouble() * 12,
        speed = 0.0008 + r.nextDouble() * 0.0020,
        drift = (r.nextDouble() - 0.5) * 0.0006,
        rotation = r.nextDouble() * pi * 2,
        rotationSpeed = (r.nextDouble() - 0.5) * 0.04,
        opacity = 0.35 + r.nextDouble() * 0.55,
        useColor2 = r.nextBool();

  void step(SeasonalTheme theme) {
    if (theme == SeasonalTheme.valentines) {
      y -= speed; // corazones flotan hacia arriba
    } else {
      y += speed; // el resto cae
    }
    x += drift;
    rotation += rotationSpeed;

    // wrap
    if (y > 1.08) { y = -0.08; x = Random().nextDouble(); }
    if (y < -0.08) { y = 1.08; x = Random().nextDouble(); }
    if (x > 1.05) x = -0.05;
    if (x < -0.05) x = 1.05;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final SeasonalTheme theme;
  final Color color1;
  final Color color2;

  const _ParticlePainter({
    required this.particles,
    required this.theme,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final color = (p.useColor2 ? color2 : color1).withValues(alpha: p.opacity);
      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.rotation);

      switch (theme) {
        case SeasonalTheme.christmas:
          _snowflake(canvas, p.size, color);
        case SeasonalTheme.halloween:
          _bat(canvas, p.size, color);
        case SeasonalTheme.valentines:
          _heart(canvas, p.size, color);
        case SeasonalTheme.normal:
          break;
      }

      canvas.restore();
    }
  }

  void _snowflake(Canvas canvas, double s, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = s * 0.13
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 3; i++) {
      final a = i * pi / 3;
      canvas.drawLine(
        Offset(cos(a) * s, sin(a) * s),
        Offset(-cos(a) * s, -sin(a) * s),
        paint,
      );
    }
    canvas.drawCircle(Offset.zero, s * 0.16, Paint()..color = color);
  }

  void _bat(Canvas canvas, double s, Color color) {
    final fill = Paint()..color = color..style = PaintingStyle.fill;

    // cuerpo
    canvas.drawCircle(Offset.zero, s * 0.26, fill);

    // alas
    for (final sign in [-1.0, 1.0]) {
      final wing = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(sign * s * 0.75, -s * 0.55, sign * s, 0)
        ..quadraticBezierTo(sign * s * 0.65, s * 0.22, sign * s * 0.28, s * 0.14)
        ..close();
      canvas.drawPath(wing, fill);

      // orejita
      final ear = Path()
        ..moveTo(sign * s * 0.18, -s * 0.18)
        ..lineTo(sign * s * 0.36, -s * 0.52)
        ..lineTo(sign * s * 0.06, -s * 0.24)
        ..close();
      canvas.drawPath(ear, fill);
    }
  }

  void _heart(Canvas canvas, double s, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final r = s * 0.75;

    final path = Path()
      ..moveTo(0, r * 0.45)
      ..cubicTo(-r * 1.15, -r * 0.25, -r * 1.15, -r, 0, -r * 0.5)
      ..cubicTo(r * 1.15, -r, r * 1.15, -r * 0.25, 0, r * 0.45);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ParticlePainter _) => true;
}
