import 'package:flutter/material.dart';
import 'dart:math';
import '../ui/style.dart';
import 'package:complex/complex.dart';
import '../core/quantum_state.dart';
import '../core/quantum_gates.dart';

class AlgorithmsScreen extends StatelessWidget {
  const AlgorithmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Hero(
                tag: HeroTags.algorithms,
                child: Icon(Icons.auto_graph_rounded, size: 22),
              ),
              SizedBox(width: 8),
              Text('Quantum Algorithms'),
            ],
          ),
          backgroundColor: Colors.transparent,
          flexibleSpace: const _GlassHeader(),
          bottom: const TabBar(
            labelStyle: TextStyle(fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Deutsch-Jozsa'),
              Tab(text: 'Grover'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33A5B4FF), Colors.transparent],
            ),
          ),
          child: const SafeArea(
            top: true,
            bottom: false,
            child: _AlgorithmsBody(),
          ),
        ),
      ),
    );
  }
}

class _AlgorithmsBody extends StatelessWidget {
  const _AlgorithmsBody();
  @override
  Widget build(BuildContext context) {
    // TabBar height ~ 48; AppBar is already behind because extendBodyBehindAppBar true.
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: const TabBarView(children: [DeutschJozsaWidget(), GroverWidget()]),
    );
  }
}

class _GlassHeader extends StatelessWidget {
  const _GlassHeader();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.15),
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class DeutschJozsaWidget extends StatefulWidget {
  const DeutschJozsaWidget({super.key});

  @override
  State<DeutschJozsaWidget> createState() => _DeutschJozsaWidgetState();
}

class _DeutschJozsaWidgetState extends State<DeutschJozsaWidget> {
  int n = 3; // number of input qubits
  String oracleType = 'constant-0';
  String result = '';
  Map<String, double>? distribution;

  void runAlgorithm() {
    // Implementation: n input qubits + 1 ancilla initialized to |1>, apply H to all, oracle, H on inputs, measure inputs.
    final totalQubits = n + 1;
    var state = QuantumState(totalQubits);
    // Set ancilla to |1>
    applySingleQubitGate(state, SingleQubitGate.pauliX, 0);
    // Hadamard on all qubits
    for (var q = 0; q < totalQubits; q++) {
      applySingleQubitGate(state, SingleQubitGate.hadamard, q);
    }
    // Oracle: flips phase of states depending on oracleType.
    // We'll encode bits with ancilla as least significant qubit index 0.
    for (var i = 0; i < state.amplitudes.length; i++) {
      final bits = i.toRadixString(2).padLeft(totalQubits, '0');
      final input = bits.substring(
        0,
        n,
      ); // excluding ancilla last? orientation simplified
      bool flip = false;
      switch (oracleType) {
        case 'constant-0':
          flip = false;
          break;
        case 'constant-1':
          flip = true;
          break;
        case 'balanced':
          // Balanced: flip half (parity function)
          final ones = input.split('').where((c) => c == '1').length;
          flip = ones % 2 == 1;
          break;
      }
      if (flip) {
        state.amplitudes[i] = state.amplitudes[i] * const Complex(-1, 0);
      }
    }
    // Hadamard on input qubits only (exclude ancilla index 0 or last depending orientation). We'll simplify: apply to first n.
    for (var q = 0; q < n; q++) {
      applySingleQubitGate(state, SingleQubitGate.hadamard, q);
    }
    distribution = state.probabilityDistribution();
    final zeroKey = List.filled(n, '0').join();
    // Determine probability of all zeros on first n bits (approx by summing states where those bits zero)
    double pAllZero = 0;
    distribution!.forEach((bits, p) {
      if (bits.substring(0, n) == zeroKey) pAllZero += p;
    });
    if (pAllZero > 0.5) {
      result = 'Constant function (P(all 0)=${pAllZero.toStringAsFixed(2)})';
    } else {
      result = 'Balanced function (P(all 0)=${pAllZero.toStringAsFixed(2)})';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deutsch-Jozsa Algorithm (simplified)'),
          DropdownButton<String>(
            value: oracleType,
            items: const [
              DropdownMenuItem(value: 'constant-0', child: Text('Constant 0')),
              DropdownMenuItem(value: 'constant-1', child: Text('Constant 1')),
              DropdownMenuItem(value: 'balanced', child: Text('Balanced')),
            ],
            onChanged: (v) => setState(() => oracleType = v!),
          ),
          ElevatedButton(onPressed: runAlgorithm, child: const Text('Run')),
          const SizedBox(height: 12),
          Text(result),
          if (distribution != null)
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  children: distribution!.entries
                      .map(
                        (e) => Chip(
                          label: Text(
                            '${e.key}: ${e.value.toStringAsFixed(2)}',
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GroverWidget extends StatefulWidget {
  const GroverWidget({super.key});

  @override
  State<GroverWidget> createState() => _GroverWidgetState();
}

class _GroverWidgetState extends State<GroverWidget> {
  int n = 3; // number of qubits => search space size 2^n
  int markedIndex = 5;
  String output = '';
  Map<String, double>? dist;

  void runGrover() {
    final size = 1 << n;
    if (markedIndex >= size) markedIndex = size - 1;
    var state = QuantumState(n);
    // Put into equal superposition
    for (var q = 0; q < n; q++) {
      applySingleQubitGate(state, SingleQubitGate.hadamard, q);
    }
    // Number of iterations ~ floor(pi/4 * sqrt(N))
    final iterations = (pi / 4 * sqrt(size)).floor();
    for (var iter = 0; iter < iterations; iter++) {
      // Oracle: phase flip marked state
      state.amplitudes[markedIndex] =
          state.amplitudes[markedIndex] * const Complex(-1, 0);
      // Diffusion: H^n -> phase flip |0> -> H^n
      for (var q = 0; q < n; q++) {
        applySingleQubitGate(state, SingleQubitGate.hadamard, q);
      }
      // Phase flip |0>
      state.amplitudes[0] = state.amplitudes[0] * const Complex(-1, 0);
      for (var q = 0; q < n; q++) {
        applySingleQubitGate(state, SingleQubitGate.hadamard, q);
      }
    }
    dist = state.probabilityDistribution();
    final sorted = dist!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted
        .take(3)
        .map((e) => '${e.key}:${e.value.toStringAsFixed(2)}')
        .join(', ');
    output = 'Iterations: $iterations  Top states: $top';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Grover Search (simplified simulation)'),
          Row(
            children: [
              const Text('Qubits:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: n,
                items: [3, 4, 5]
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e, child: Text(e.toString())),
                    )
                    .toList(),
                onChanged: (v) => setState(() => n = v!),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Marked index:'),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  decoration: const InputDecoration(hintText: '5'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => markedIndex = int.tryParse(v) ?? 0,
                ),
              ),
            ],
          ),
          ElevatedButton(onPressed: runGrover, child: const Text('Run')),
          const SizedBox(height: 12),
          Text(output),
          if (dist != null)
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  children: dist!.entries
                      .map(
                        (e) => Chip(
                          label: Text('${e.key}:${e.value.toStringAsFixed(2)}'),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
