import 'dart:math';
import 'package:flutter/material.dart';
import '../core/quantum_state.dart';

class BlochSphere extends StatelessWidget {
  final QuantumState state;
  const BlochSphere({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(150, 150),
      painter: _BlochPainter(state),
    );
  }
}

class _BlochPainter extends CustomPainter {
  final QuantumState state;
  _BlochPainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    final paintCircle = Paint()
      ..color = Colors.blueGrey.shade700
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;
    canvas.drawCircle(center, radius, paintCircle);

    // Approximate Bloch vector from amplitudes a|0> + b|1>
    if (state.qubitCount != 1) return;
    final a = state.amplitudes[0];
    final b = state.amplitudes[1];
    // Bloch coords: x = 2 Re(a* b), y = 2 Im(a* b), z = |a|^2 - |b|^2
    final aConj = a.conjugate();
    final prod = aConj * b; // a* b
    final x = 2 * prod.real;
    final y = 2 * prod.imaginary; // used for slight skew in projection
    final z = a.abs() * a.abs() - b.abs() * b.abs();

    // Project 3D (x,y,z) onto 2D: ignore y for simple projection
    final px = (x + 0.3 * y) * radius * 0.8; // skew by y
    final pz = z * radius * 0.8;
    final point = Offset(center.dx + px, center.dy - pz);

    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;
    // axes
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      axisPaint,
    );

    final vectorPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2;
    canvas.drawLine(center, point, vectorPaint);
    canvas.drawCircle(point, 4, vectorPaint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _BlochPainter oldDelegate) => true;
}
