import 'package:flutter/material.dart';
import '../core/quantum_state.dart';
import '../core/quantum_gates.dart';
import '../widgets/bloch_sphere.dart';
import '../widgets/illustrations.dart';
import '../ui/style.dart';
import 'dart:math';

class BasicsScreen extends StatefulWidget {
  const BasicsScreen({super.key});

  @override
  State<BasicsScreen> createState() => _BasicsScreenState();
}

class _BasicsScreenState extends State<BasicsScreen>
    with SingleTickerProviderStateMixin {
  QuantumState state = QuantumState(1);
  late AnimationController _controller;
  late Animation<double> _rotation;

  void _applyGate(SingleQubitGate gate) {
    setState(() {
      applySingleQubitGate(state, gate, 0);
    });
    _controller.forward(from: 0);
  }

  String _distributionString() {
    final dist = state.probabilityDistribution();
    return dist.entries
        .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}')
        .join('  ');
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Hero(
              tag: HeroTags.basics,
              child: Icon(Icons.bubble_chart_rounded, size: 22),
            ),
            SizedBox(width: 8),
            Text('Quantum Basics'),
          ],
        ),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x33FFB340), Colors.transparent],
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SectionCard(
                  title: 'Superposition',
                  illustration: const GateIllustration(
                    gates: ['|0⟩', 'H', '→', '(|0⟩+|1⟩)/√2'],
                  ),
                  child: const Text(
                    'Apply the Hadamard (H) gate to the |0⟩ state to create an equal superposition of |0⟩ and |1⟩.',
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _applyGate(SingleQubitGate.hadamard),
                      child: const Text('H'),
                    ),
                    ElevatedButton(
                      onPressed: () => _applyGate(SingleQubitGate.pauliX),
                      child: const Text('X'),
                    ),
                    ElevatedButton(
                      onPressed: () => _applyGate(SingleQubitGate.pauliY),
                      child: const Text('Y'),
                    ),
                    ElevatedButton(
                      onPressed: () => _applyGate(SingleQubitGate.pauliZ),
                      child: const Text('Z'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          state = QuantumState(1);
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Bloch Sphere',
                  illustration: const GateIllustration(
                    gates: ['State', '→', 'Bloch'],
                  ),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _rotation,
                        builder: (_, __) {
                          return Transform.rotate(
                            angle: _rotation.value * pi * 2,
                            child: BlochSphere(state: state),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Visual representation of a single qubit on the Bloch sphere. Rotations correspond to unitary gates.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('Probabilities: ${_distributionString()}'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final result = state.measure();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Measurement: $result')),
                    );
                  },
                  child: const Text('Measure'),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Entanglement',
                  illustration: const EntanglementIllustration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create a Bell state by applying H to the first qubit then a CNOT. The measurement outcomes become correlated.',
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          final ent = QuantumState(2);
                          applySingleQubitGate(
                            ent,
                            SingleQubitGate.hadamard,
                            0,
                          );
                          applyCNOT(ent, 0, 1);
                          final dist = ent.probabilityDistribution();
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Bell State'),
                              content: Text(
                                dist.entries
                                    .map(
                                      (e) =>
                                          '${e.key}: ${e.value.toStringAsFixed(2)}',
                                    )
                                    .join('\n'),
                              ),
                            ),
                          );
                        },
                        child: const Text('Generate Bell State'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
