import 'package:flutter/material.dart';
import 'dart:math' as math;

class ScanRatingChart extends StatelessWidget {
  final int malicious;
  final int suspicious;
  final int harmless;
  final int undetected;
  final double size;

  const ScanRatingChart({
    super.key,
    required this.malicious,
    required this.suspicious,
    required this.harmless,
    required this.undetected,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final total = malicious + suspicious + harmless + undetected;
    
    return SizedBox(
      width: size,
      height: size + 80,
      child: Column(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(size, size),
                  painter: RatingChartPainter(
                    malicious: malicious / total,
                    suspicious: suspicious / total,
                    harmless: harmless / total,
                    undetected: undetected / total,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Malicious', malicious, Colors.red),
              _buildStatItem('Suspicious', suspicious, Colors.orange),
              _buildStatItem('Clean', harmless, Colors.green),
              _buildStatItem('Undetected', undetected, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class RatingChartPainter extends CustomPainter {
  final double malicious;
  final double suspicious;
  final double harmless;
  final double undetected;

  RatingChartPainter({
    required this.malicious,
    required this.suspicious,
    required this.harmless,
    required this.undetected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.2;
    
    void drawArc(double startAngle, double sweepAngle, Color color) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    double currentAngle = -math.pi / 2;

    // Draw undetected (grey)
    drawArc(currentAngle, undetected * 2 * math.pi, Colors.grey);
    currentAngle += undetected * 2 * math.pi;

    // Draw harmless (green)
    drawArc(currentAngle, harmless * 2 * math.pi, Colors.green);
    currentAngle += harmless * 2 * math.pi;

    // Draw suspicious (orange)
    drawArc(currentAngle, suspicious * 2 * math.pi, Colors.orange);
    currentAngle += suspicious * 2 * math.pi;

    // Draw malicious (red)
    drawArc(currentAngle, malicious * 2 * math.pi, Colors.red);
  }

  @override
  bool shouldRepaint(RatingChartPainter oldDelegate) =>
      oldDelegate.malicious != malicious ||
      oldDelegate.suspicious != suspicious ||
      oldDelegate.harmless != harmless ||
      oldDelegate.undetected != undetected;
} 

// kese kese log he yar 
// ata azun kay kay add karayla lavnar