import 'dart:math' as math;
import 'package:flutter/material.dart';

class TemperatureDial extends StatelessWidget {
  const TemperatureDial({
    super.key,
    required this.temperature,
    required this.mode,
    this.minTemp = 0,
    this.maxTemp = 100,
    this.size = 240,
  });

  final double temperature;
  final String mode;
  final double minTemp;
  final double maxTemp;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clamped = temperature.clamp(minTemp, maxTemp);
    final t = ((clamped - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft outer shadow halo to mimic the concentric shadow in the mock
          Container(
            width: size * 0.92,
            height: size * 0.92,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),

          // Ring (background + gradient arc + knob)
          CustomPaint(
            size: Size.square(size),
            painter: _DialPainter(progress: t),
          ),

          // Inner white plate
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
              border: Border.all(color: const Color(0x11000000)),
            ),
          ),

          // Temperature and mode text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TempText(value: temperature, color: Colors.black),
              const SizedBox(height: 4),
              Text(mode, style: TextStyle(color: Colors.black, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TempText extends StatelessWidget {
  const _TempText({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final major = value.floor();
    final minor = ((value - major) * 10).round();
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: major.toString(),
            style: TextStyle(
              color: color,
              fontSize: 44,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
          TextSpan(
            text: '.${minor.toString()} °C',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.progress});
  final double progress; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = size.shortestSide * 0.11; // ring thickness
    final radius = size.shortestSide / 2 - stroke / 2 - 4;

    // Background ring
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0x11000000);
    canvas.drawCircle(center, radius, bg);

    // Gradient ring (full sweep), desired order clockwise from the top:
    // RED (hottest) → ORANGE → YELLOW → WHITE → LIGHT BLUE → BLUE → DEEP BLUE (coldest)
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: const [
        Color(0xFF0B4F9C), // deep cold blue (coldest)
        Color(0xFF1E88E5), // blue
        Color(0xFF64B5F6), // light blue
        Color(0xFFFFFFFF), // white
        Color(0xFFFFD54F), // yellow (amber 300)
        Color(0xFFFFA726), // orange
        Color(0xFFE53935), // red
        Color(0xFFB71C1C), // deep hot red
      ],
      stops: const [0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 0.99, 1.0],
      transform: const GradientRotation(0.0),
    );

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..shader = gradient.createShader(rect);

    // Draw full ring
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, ring);

    // Knob position according to progress
    final angle = -math.pi / 2 + progress * 2 * math.pi;
    final knobCenter = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );

    // Knob outer subtle shadow
    final knobShadow = Paint()
      ..color = const Color(0x22000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(knobCenter, stroke * 0.38, knobShadow);

    // Knob
    final knob = Paint()..color = Colors.white;
    canvas.drawCircle(knobCenter, stroke * 0.32, knob);
    final knobEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x22000000);
    canvas.drawCircle(knobCenter, stroke * 0.32, knobEdge);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
