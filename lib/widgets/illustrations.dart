import 'package:flutter/material.dart';

/// Lightweight illustrative widgets for quantum concepts.

class GateIllustration extends StatelessWidget {
  final List<String> gates; // e.g. ['H','CNOT']
  const GateIllustration({super.key, required this.gates});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < gates.length; i++) ...[
          _gateBox(gates[i], theme),
          if (i != gates.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: theme.primary,
              ),
            ),
        ],
      ],
    );
  }

  Widget _gateBox(String label, ColorScheme scheme) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: scheme.primary, width: 2),
    ),
    child: Text(
      label,
      style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary),
    ),
  );
}

class ProbabilityBarIllustration extends StatelessWidget {
  final Map<String, double> sample; // e.g. {'00':0.5,'11':0.5}
  const ProbabilityBarIllustration({super.key, required this.sample});

  @override
  Widget build(BuildContext context) {
    final total = sample.values.fold<double>(0, (s, v) => s + v);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: sample.entries.map((e) {
        final h = (e.value / (total == 0 ? 1 : total)) * 60 + 8;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                width: 18,
                height: h,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(e.key, style: const TextStyle(fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class EntanglementIllustration extends StatelessWidget {
  const EntanglementIllustration({super.key});
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return CustomPaint(painter: _EntPainter(color), size: const Size(160, 60));
  }
}

class _EntPainter extends CustomPainter {
  final Color color;
  _EntPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final centerY = size.height / 2;
    canvas.drawCircle(Offset(size.width * 0.3, centerY), 18, p);
    canvas.drawCircle(Offset(size.width * 0.7, centerY), 18, p);
    final path = Path()
      ..moveTo(size.width * 0.3 + 18, centerY)
      ..cubicTo(
        size.width * 0.45,
        centerY - 30,
        size.width * 0.55,
        centerY + 30,
        size.width * 0.7 - 18,
        centerY,
      );
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
