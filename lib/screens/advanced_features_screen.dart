import 'package:flutter/material.dart';
import '../ui/style.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/quantum_state.dart';
import '../core/quantum_gates.dart';
import '../core/circuit_model.dart';
import '../core/quantum_utils.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Aggregated hub for advanced quantum features (skeleton implementation).
class AdvancedFeaturesScreen extends StatelessWidget {
  const AdvancedFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final entries = <_FeatureEntry>[
      _FeatureEntry(
        t.tabCircuitOptimization,
        Icons.tune,
        _OptimizationPane.new,
      ),
      _FeatureEntry(
        t.tabEntanglement,
        Icons.blur_on_rounded,
        _EntanglementPane.new,
      ),
      _FeatureEntry(
        t.tabErrorCorrection,
        Icons.healing_rounded,
        _ErrorCorrectionPane.new,
      ),
      _FeatureEntry(t.tabShorCode, Icons.grid_3x3_rounded, _ShorPane.new),
      _FeatureEntry(
        t.tabTeleportation,
        Icons.send_rounded,
        _TeleportationPane.new,
      ),
      _FeatureEntry(t.tabQft, Icons.graphic_eq_rounded, _QftPane.new),
      _FeatureEntry(t.tabHybridVqe, Icons.sync_rounded, _HybridPane.new),
      _FeatureEntry(t.tabRng, Icons.casino_rounded, _RngPane.new),
      _FeatureEntry(t.tabQml, Icons.developer_board, _QmlPane.new),
      _FeatureEntry(t.tabQkd, Icons.vpn_key_rounded, _QkdPane.new),
      _FeatureEntry(
        t.tabSynthesis,
        Icons.auto_fix_high_rounded,
        _SynthesisPane.new,
      ),
    ];

    return DefaultTabController(
      length: entries.length,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Hero(
                tag: HeroTags.advanced,
                child: Icon(Icons.science_rounded, size: 22),
              ),
              const SizedBox(width: 8),
              Text(t.cardAdvanced),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (final e in entries)
                Tab(text: e.title, icon: Icon(e.icon, size: 16)),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x335E5CE6), Colors.transparent],
            ),
          ),
          child: SafeArea(
            top: true,
            bottom: false,
            child: TabBarView(
              children: [
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: e.builder(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureEntry {
  final String title;
  final IconData icon;
  final Widget Function() builder;
  _FeatureEntry(this.title, this.icon, this.builder);
}

// Placeholder panes. Future work: implement real logic.

class _OptimizationPane extends StatelessWidget {
  const _OptimizationPane({super.key});
  @override
  Widget build(BuildContext context) => const _OptimizationDetailPane();
}

class _OptimizationDetailPane extends StatefulWidget {
  const _OptimizationDetailPane();
  @override
  State<_OptimizationDetailPane> createState() =>
      _OptimizationDetailPaneState();
}

class _OptimizationDetailPaneState extends State<_OptimizationDetailPane> {
  List<OptimizationPassResult>? passes;
  int original = 0;
  int finalCount = 0;
  int depthBefore = 0;
  int depthAfter = 0;

  void _runSample() {
    // Build a sample circuit with redundancies
    final c = QuantumCircuit(qubits: 2);
    c.add(CircuitGate(type: 'H', target: 0));
    c.add(CircuitGate(type: 'H', target: 0)); // cancels
    c.add(CircuitGate(type: 'RY', target: 1, theta: 0.5));
    c.add(CircuitGate(type: 'RY', target: 1, theta: 0.25));
    c.add(CircuitGate(type: 'RY', target: 1, theta: -0.25)); // merges
    c.add(CircuitGate(type: 'PHASE', target: 0, theta: 0.1));
    c.add(CircuitGate(type: 'PHASE', target: 0, theta: -0.1)); // cancels
    original = c.gates.length;
    depthBefore = c.depth();
    passes = c.optimizeDetailed();
    finalCount = c.gates.length;
    depthAfter = c.depth();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SectionCard(
          title: 'Pass Breakdown',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: _runSample,
                child: const Text('Run Sample Optimization'),
              ),
              if (passes != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Gates: $original → $finalCount  (Δ${original - finalCount})',
                ),
                Text(
                  'Depth: $depthBefore → $depthAfter  (Δ${depthAfter - depthBefore})',
                ),
                const SizedBox(height: 8),
                for (final p in passes!)
                  ListTile(
                    dense: true,
                    title: Text(p.name),
                    subtitle: Text(
                      'Gates ${p.before}->${p.after} (Δ=${p.removed}), Depth ${p.beforeDepth}->${p.afterDepth} (Δ=${p.depthDelta})',
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Current passes: Inverse Cancellation, Phase/RY Merge (mod 2π). Planned: commutation reordering, template fusion, CNOT chain reductions.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorCorrectionPane extends StatefulWidget {
  @override
  State<_ErrorCorrectionPane> createState() => _ErrorCorrectionPaneState();
}

class _ErrorCorrectionPaneState extends State<_ErrorCorrectionPane> {
  QuantumState logical = QuantumState(1);
  QuantumState? encoded;
  (int, int)? syndrome;
  String log = '';
  double errorProb = 0.2;

  void _applyGate(SingleQubitGate g) {
    applySingleQubitGate(logical, g, 0);
    setState(() {});
  }

  void _encode() {
    encoded = encodeBitFlip(logical);
    log = 'Encoded logical qubit into 3-qubit code';
    setState(() {});
  }

  void _inject() {
    if (encoded == null) return;
    injectBitFlipError(encoded!, errorProb, rng: Random());
    log = 'Injected possible X error (p=$errorProb)';
    setState(() {});
  }

  void _measureSyndrome() {
    if (encoded == null) return;
    syndrome = measureBitFlipSyndrome(encoded!);
    log = 'Syndrome = ${syndrome!.toString()}';
    setState(() {});
  }

  void _correct() {
    if (encoded == null || syndrome == null) return;
    correctBitFlip(encoded!, syndrome!);
    log = 'Applied correction for syndrome ${syndrome!.toString()}';
    setState(() {});
  }

  String _distString(QuantumState s) => s
      .probabilityDistribution()
      .entries
      .map((e) => '${e.key}:${e.value.toStringAsFixed(2)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SectionCard(
          title: 'Logical State',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Dist: ${_distString(logical)}'),
              ElevatedButton(
                onPressed: () => _applyGate(SingleQubitGate.hadamard),
                child: const Text('H'),
              ),
              ElevatedButton(
                onPressed: () => _applyGate(SingleQubitGate.pauliX),
                child: const Text('X'),
              ),
              ElevatedButton(
                onPressed: () => _applyGate(SingleQubitGate.pauliZ),
                child: const Text('Z'),
              ),
              ElevatedButton(
                onPressed: () {
                  logical = QuantumState(1);
                  setState(() {});
                },
                child: const Text('Reset'),
              ),
              ElevatedButton(onPressed: _encode, child: const Text('Encode')),
            ],
          ),
        ),
        if (encoded != null)
          SectionCard(
            title: 'Encoded (3-qubit)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dist: ${_distString(encoded!)}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Error p:'),
                    Expanded(
                      child: Slider(
                        value: errorProb,
                        min: 0,
                        max: 0.5,
                        onChanged: (v) {
                          setState(() => errorProb = v);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(errorProb.toStringAsFixed(2)),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _inject,
                      child: const Text('Inject Error'),
                    ),
                    ElevatedButton(
                      onPressed: _measureSyndrome,
                      child: const Text('Syndrome'),
                    ),
                    ElevatedButton(
                      onPressed: _correct,
                      child: const Text('Correct'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (log.isNotEmpty) SectionCard(title: 'Log', child: Text(log)),
      ],
    );
  }
}

class _TeleportationPane extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    children: const [
      SectionCard(
        title: 'Quantum Teleportation',
        child: Text(
          'Placeholder: Show steps: prepare |ψ>, entangle AB, Bell measure (ψ,A), classical bits -> corrections on B, fidelity check.',
        ),
      ),
    ],
  );
}

// ================= Entanglement Visualizer =================

class _EntanglementPane extends StatefulWidget {
  const _EntanglementPane({super.key});
  @override
  State<_EntanglementPane> createState() => _EntanglementPaneState();
}

class _EntanglementPaneState extends State<_EntanglementPane> {
  int qubits = 2; // keep small for clarity
  final gates = <CircuitGate>[];
  QuantumState? state;

  void _recompute() {
    final c = QuantumCircuit(qubits: qubits);
    for (final g in gates) {
      c.add(g);
    }
    state = c.run();
    setState(() {});
  }

  void _addGate(CircuitGate g) {
    gates.add(g);
    _recompute();
  }

  void _reset() {
    gates.clear();
    state = QuantumState(qubits);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _reset();
  }

  Widget _metrics() {
    if (state == null) return const Text('No state');
    final rows = <Widget>[];
    // Single qubit metrics
    for (int q = 0; q < qubits; q++) {
      final ez = expectationZ(state!, q).toStringAsFixed(3);
      final pur = singleQubitPurityApprox(state!, q).toStringAsFixed(3);
      rows.add(Text('q$q: <Z>=$ez  Purity≈$pur'));
    }
    // Pairwise
    if (qubits >= 2) {
      for (int i = 0; i < qubits; i++) {
        for (int j = i + 1; j < qubits; j++) {
          final czz = correlationZZ(state!, i, j).toStringAsFixed(3);
          rows.add(Text('⟨Z$i Z$j⟩ = $czz'));
        }
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SectionCard(
          title: 'Controls',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Qubits:'),
              DropdownButton<int>(
                value: qubits,
                items: [2, 3]
                    .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    qubits = v;
                    _reset();
                  }
                },
              ),
              ElevatedButton(
                onPressed: _reset,
                child: const Text('Reset State'),
              ),
              ElevatedButton(
                onPressed: () => _addGate(CircuitGate(type: 'H', target: 0)),
                child: const Text('H q0'),
              ),
              ElevatedButton(
                onPressed: qubits > 1
                    ? () => _addGate(
                        CircuitGate(type: 'CNOT', control: 0, target: 1),
                      )
                    : null,
                child: const Text('CNOT 0→1'),
              ),
              if (qubits > 2)
                ElevatedButton(
                  onPressed: () => _addGate(
                    CircuitGate(type: 'CNOT', control: 1, target: 2),
                  ),
                  child: const Text('CNOT 1→2'),
                ),
            ],
          ),
        ),
        SectionCard(title: 'Metrics', child: _metrics()),
        if (state != null)
          SectionCard(
            title: 'Distribution',
            child: Text(
              state!
                  .probabilityDistribution()
                  .entries
                  .map((e) => '${e.key}:${e.value.toStringAsFixed(3)}')
                  .join('  '),
            ),
          ),
        SectionCard(
          title: 'Applied Gates',
          child: Wrap(
            spacing: 6,
            children: [
              for (final g in gates)
                Chip(
                  label: Text(
                    g.control != null
                        ? '${g.type}(${g.control}->${g.target})'
                        : '${g.type}(${g.target})',
                  ),
                ),
            ],
          ),
        ),
        const SectionCard(
          title: 'Notes',
          child: Text(
            'Purity approximation uses only <Z>; full purity would need reduced density matrices. High |⟨Z_i Z_j⟩| with near-zero single ⟨Z_i⟩ often indicates entanglement (e.g., Bell states).',
          ),
        ),
      ],
    );
  }
}

// ================= Shor Code Pane =================

class _ShorPane extends StatefulWidget {
  const _ShorPane({super.key});
  @override
  State<_ShorPane> createState() => _ShorPaneState();
}

class _ShorPaneState extends State<_ShorPane> {
  QuantumState logical = QuantumState(1);
  QuantumState? encoded;
  double pX = 0.05;
  double pZ = 0.05;
  Map<String, int>? syndrome;
  String log = '';

  void _apply(SingleQubitGate g) {
    applySingleQubitGate(logical, g, 0);
    setState(() {});
  }

  void _encode() {
    encoded = encodeShor(logical);
    log = 'Encoded into 9-qubit Shor code';
    setState(() {});
  }

  void _inject() {
    if (encoded == null) return;
    injectShorBitPhaseError(encoded!, pX: pX, pZ: pZ, rng: Random());
    log = 'Injected noise pX=$pX pZ=$pZ';
    setState(() {});
  }

  void _syndrome() {
    if (encoded == null) return;
    syndrome = shorSyndrome(encoded!);
    log = 'Syndrome: suspect triple ${syndrome!['suspectTriple']}';
    setState(() {});
  }

  void _correct() {
    if (encoded == null || syndrome == null) return;
    correctShorSimplified(encoded!, syndrome!);
    log = 'Applied (placeholder) correction';
    setState(() {});
  }

  String _dist(QuantumState s, {int maxTerms = 8}) {
    final entries = s.probabilityDistribution().entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(maxTerms)
        .map((e) => '${e.key}:${e.value.toStringAsFixed(3)}')
        .join('  ');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SectionCard(
          title: 'Logical Qubit',
          child: Wrap(
            spacing: 8,
            children: [
              Text('Dist: ${_dist(logical)}'),
              ElevatedButton(
                onPressed: () => _apply(SingleQubitGate.hadamard),
                child: const Text('H'),
              ),
              ElevatedButton(
                onPressed: () => _apply(SingleQubitGate.pauliX),
                child: const Text('X'),
              ),
              ElevatedButton(
                onPressed: () => _apply(SingleQubitGate.pauliZ),
                child: const Text('Z'),
              ),
              ElevatedButton(
                onPressed: () {
                  logical = QuantumState(1);
                  setState(() {});
                },
                child: const Text('Reset'),
              ),
              ElevatedButton(onPressed: _encode, child: const Text('Encode')),
            ],
          ),
        ),
        if (encoded != null)
          SectionCard(
            title: 'Encoded (9-qubit)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top probabilities: ${_dist(encoded!, maxTerms: 10)}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('pX'),
                    Expanded(
                      child: Slider(
                        value: pX,
                        min: 0,
                        max: 0.3,
                        onChanged: (v) => setState(() => pX = v),
                      ),
                    ),
                    SizedBox(width: 50, child: Text(pX.toStringAsFixed(2))),
                  ],
                ),
                Row(
                  children: [
                    const Text('pZ'),
                    Expanded(
                      child: Slider(
                        value: pZ,
                        min: 0,
                        max: 0.3,
                        onChanged: (v) => setState(() => pZ = v),
                      ),
                    ),
                    SizedBox(width: 50, child: Text(pZ.toStringAsFixed(2))),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _inject,
                      child: const Text('Inject Noise'),
                    ),
                    ElevatedButton(
                      onPressed: _syndrome,
                      child: const Text('Syndrome'),
                    ),
                    ElevatedButton(
                      onPressed: _correct,
                      child: const Text('Correct'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (log.isNotEmpty) SectionCard(title: 'Log', child: Text(log)),
        const SectionCard(
          title: 'Notes',
          child: Text(
            'This simplified Shor code demo approximates syndrome extraction. Full phase error correction not implemented.',
          ),
        ),
      ],
    );
  }
}

// ================= QKD (BB84) Pane =================

class _QkdPane extends StatefulWidget {
  const _QkdPane({super.key});
  @override
  State<_QkdPane> createState() => _QkdPaneState();
}

class _QkdPaneState extends State<_QkdPane> {
  int n = 64;
  double loss = 0.0;
  double eaves = 0.0;
  Bb84Result? result;

  void _run() {
    result = runBb84(n, lossProb: loss, eavesdropProb: eaves, rng: Random());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SectionCard(
          title: 'Parameters',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Bits'),
                  Expanded(
                    child: Slider(
                      value: n.toDouble(),
                      min: 16,
                      max: 256,
                      divisions: 15,
                      label: n.toString(),
                      onChanged: (v) => setState(() => n = v.round()),
                    ),
                  ),
                  SizedBox(width: 50, child: Text('$n')),
                ],
              ),
              Row(
                children: [
                  const Text('Loss'),
                  Expanded(
                    child: Slider(
                      value: loss,
                      min: 0,
                      max: 0.5,
                      onChanged: (v) => setState(() => loss = v),
                    ),
                  ),
                  SizedBox(width: 50, child: Text(loss.toStringAsFixed(2))),
                ],
              ),
              Row(
                children: [
                  const Text('Eaves'),
                  Expanded(
                    child: Slider(
                      value: eaves,
                      min: 0,
                      max: 0.5,
                      onChanged: (v) => setState(() => eaves = v),
                    ),
                  ),
                  SizedBox(width: 50, child: Text(eaves.toStringAsFixed(2))),
                ],
              ),
              ElevatedButton(onPressed: _run, child: const Text('Run BB84')),
            ],
          ),
        ),
        if (result != null)
          SectionCard(
            title: 'Results',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sifted key length: ${result!.siftedKey.length}'),
                Text(
                  'QBER: ${(result!.quantumBitErrorRate * 100).toStringAsFixed(2)}%',
                ),
                Text('Sample key: ${result!.siftedKey.take(32).join()}'),
                const SizedBox(height: 8),
                Text(
                  'Alice bases: ${result!.aliceBases.take(32).join()}\nBob bases:   ${result!.bobBases.take(32).join()}\nAlice bits:  ${result!.aliceBits.take(32).join()}\nBob results: ${result!.bobResults.take(32).map((e) => e ?? '-').join()}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        const SectionCard(
          title: 'Notes',
          child: Text(
            'Higher eavesdropping probability increases QBER because of basis mismatch disturbance. Real BB84 includes basis reconciliation, error correction, and privacy amplification.',
          ),
        ),
      ],
    );
  }
}

// ================= Circuit Synthesis Pane =================

class _SynthesisPane extends StatefulWidget {
  const _SynthesisPane({super.key});
  @override
  State<_SynthesisPane> createState() => _SynthesisPaneState();
}

class _SynthesisPaneState extends State<_SynthesisPane> {
  int qubits = 3;
  final solutionsController = TextEditingController(text: '101,011');
  List<CircuitGateSpec> specs = [];

  void _synthesize() {
    final solsRaw = solutionsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final ints = <int>[];
    for (final s in solsRaw) {
      if (s.length != qubits || !RegExp(r'^[01]+$').hasMatch(s)) continue;
      ints.add(int.parse(s, radix: 2));
    }
    specs = synthesizePhaseOracle(qubits, ints);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SectionCard(
          title: 'Oracle Specification',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Qubits'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: qubits,
                    items: [2, 3, 4]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => qubits = v);
                    },
                  ),
                ],
              ),
              TextField(
                controller: solutionsController,
                decoration: const InputDecoration(
                  labelText: 'Solution bitstrings (comma-separated)',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _synthesize,
                child: const Text('Generate Phase Oracle'),
              ),
            ],
          ),
        ),
        if (specs.isNotEmpty)
          SectionCard(
            title: 'Gate Sequence',
            child: Wrap(
              spacing: 6,
              children: [
                for (final s in specs)
                  Chip(
                    label: Text(
                      s.control != null
                          ? '${s.type}(${s.control}->${s.target})'
                          : '${s.type}(${s.target})',
                    ),
                  ),
              ],
            ),
          ),
        const SectionCard(
          title: 'Notes',
          child: Text(
            'This naive oracle synthesis flips phase on listed solutions using single Z with surrounding X flips. Multi-controlled Z is approximated.',
          ),
        ),
      ],
    );
  }
}

class _QftPane extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    children: const [
      SectionCard(
        title: 'Quantum Fourier Transform',
        child: Text(
          'Implemented in simulator builder: Standard QFT with controlled phase rotations and final swaps. Use the Circuit Simulator > Circuit Builders > QFT.',
        ),
      ),
    ],
  );
}

class _HybridPane extends StatelessWidget {
  const _HybridPane({super.key});
  @override
  Widget build(BuildContext context) => const _VqePane();
}

class _VqePane extends StatefulWidget {
  const _VqePane();
  @override
  State<_VqePane> createState() => _VqePaneState();
}

class _VqePaneState extends State<_VqePane> {
  double theta1 = 0.3;
  double theta2 = 1.0;
  double? energy;
  double? g1;
  double? g2;
  bool optimizing = false;
  bool useParamShift = true;

  void _evaluate() {
    final grad = vqeGradient(theta1, theta2, parameterShift: useParamShift);
    setState(() {
      energy = grad.value;
      g1 = grad.d1;
      g2 = grad.d2;
    });
  }

  Future<void> _optimize() async {
    if (optimizing) return;
    optimizing = true;
    setState(() {});
    double lr = 0.2;
    for (int step = 0; step < 25; step++) {
      final grad = vqeGradient(theta1, theta2, parameterShift: useParamShift);
      theta1 -= lr * grad.d1;
      theta2 -= lr * grad.d2;
      // wrap angles into [-pi,pi]
      theta1 = ((theta1 + pi) % (2 * pi)) - pi;
      theta2 = ((theta2 + pi) % (2 * pi)) - pi;
      energy = grad.value;
      g1 = grad.d1;
      g2 = grad.d2;
      if (!mounted) break;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 60));
    }
    optimizing = false;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _evaluate();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SectionCard(
          title: 'Variational Ansatz (2-qubit)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'State: |ψ(θ1,θ2)> with RY(θ1) on q0, CNOT(0→1), RY(θ2) on q1',
              ),
              const SizedBox(height: 12),
              _sliderRow('θ1', () => theta1, (v) {
                setState(() => theta1 = v);
                _evaluate();
              }),
              _sliderRow('θ2', () => theta2, (v) {
                setState(() => theta2 = v);
                _evaluate();
              }),
              Row(
                children: [
                  const Text('Param-Shift'),
                  Switch(
                    value: useParamShift,
                    onChanged: (v) {
                      setState(() => useParamShift = v);
                      _evaluate();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (energy != null)
                Wrap(
                  spacing: 16,
                  children: [
                    Text('E[ZZ]=${energy!.toStringAsFixed(4)}'),
                    if (g1 != null) Text('∂E/∂θ1=${g1!.toStringAsFixed(4)}'),
                    if (g2 != null) Text('∂E/∂θ2=${g2!.toStringAsFixed(4)}'),
                    Text(
                      useParamShift
                          ? 'Method: Param-Shift'
                          : 'Method: Finite Diff',
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _evaluate,
                    child: const Text('Evaluate'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: optimizing ? null : _optimize,
                    child: Text(optimizing ? 'Optimizing...' : 'Optimize (GD)'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (optimizing)
          const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Widget _sliderRow(
    String label,
    double Function() getValue,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 32, child: Text(label)),
        Expanded(
          child: Slider(
            value: getValue(),
            min: -pi,
            max: pi,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 60, child: Text(getValue().toStringAsFixed(2))),
      ],
    );
  }
}

class _RngPane extends StatefulWidget {
  @override
  State<_RngPane> createState() => _RngPaneState();
}

class _RngPaneState extends State<_RngPane> {
  final List<int> _bits = [];
  int batch = 32;
  Map<int, int> freq = {0: 0, 1: 0};

  void _generate() {
    final newBits = quantumRandomBits(batch);
    _bits.addAll(newBits);
    freq[0] = _bits.where((b) => b == 0).length;
    freq[1] = _bits.length - freq[0]!;
    setState(() {});
  }

  double get entropy {
    if (_bits.isEmpty) return 0;
    double h = 0;
    for (final v in [0, 1]) {
      final p = (freq[v] ?? 0) / _bits.length;
      if (p > 0) h -= p * (log(p) / log(2));
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final p0 = _bits.isEmpty ? 0 : (freq[0]! / _bits.length);
    final p1 = _bits.isEmpty ? 0 : (freq[1]! / _bits.length);
    return ListView(
      children: [
        SectionCard(
          title: 'Random Bit Generator',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Batch size:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: batch,
                    items: [8, 16, 32, 64, 128]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => batch = v);
                    },
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _generate,
                child: const Text('Generate'),
              ),
              const SizedBox(height: 12),
              Text('Total bits: ${_bits.length}'),
              Text(
                'p(0)=${p0.toStringAsFixed(3)}  p(1)=${p1.toStringAsFixed(3)}',
              ),
              Text('Entropy: ${entropy.toStringAsFixed(3)} bits'),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: Row(
                  children: [
                    _bar(freq[0] ?? 0, Colors.blue),
                    const SizedBox(width: 12),
                    _bar(freq[1] ?? 0, Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bar(int count, Color color) {
    final maxCount = (freq.values.isEmpty ? 1 : freq.values.reduce(max)).clamp(
      1,
      1 << 31,
    );
    final h = _bits.isEmpty ? 0 : 80 * (count / maxCount);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: h.toDouble(),
            width: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 6),
          Text(count.toString()),
        ],
      ),
    );
  }
}

class _QmlPane extends StatelessWidget {
  const _QmlPane({super.key});
  @override
  Widget build(BuildContext context) => const _QmlInteractivePane();
}

class _QmlInteractivePane extends StatefulWidget {
  const _QmlInteractivePane();
  @override
  State<_QmlInteractivePane> createState() => _QmlInteractivePaneState();
}

class _QmlInteractivePaneState extends State<_QmlInteractivePane> {
  // Tiny synthetic 2D dataset (XOR-like)
  final data = <List<double>>[
    [0, 0],
    [0, 1],
    [1, 0],
    [1, 1],
  ];
  final labels = <double>[0, 1, 1, 0]; // target in {0,1}
  double alpha = 1.0; // feature map scale
  double theta1 = 0.2; // variational params for two-qubit layer
  double theta2 = -0.4;
  double? loss;
  bool training = false;
  int batchSize = 4; // full batch default
  bool parallelShift = false;
  double? accuracy;

  QuantumCircuit _buildFeatureMap(List<double> x) {
    final c = QuantumCircuit(qubits: 2);
    // Feature map: RY(alpha * x_i) on each qubit then CNOT(0->1)
    c.add(CircuitGate(type: 'RY', target: 0, theta: alpha * x[0]));
    c.add(CircuitGate(type: 'RY', target: 1, theta: alpha * x[1]));
    c.add(CircuitGate(type: 'CNOT', control: 0, target: 1));
    return c;
  }

  QuantumCircuit _addVariationalLayer(QuantumCircuit base) {
    base.add(CircuitGate(type: 'RY', target: 0, theta: theta1));
    base.add(CircuitGate(type: 'RY', target: 1, theta: theta2));
    base.add(CircuitGate(type: 'CNOT', control: 0, target: 1));
    return base;
  }

  double _predict(List<double> x) {
    final c = _addVariationalLayer(_buildFeatureMap(x));
    final st = c.run();
    // Simple readout: probability of |11>
    final dist = st.probabilityDistribution();
    return dist['11'] ?? 0.0;
  }

  void _evaluateLoss() {
    double l = 0;
    for (int i = 0; i < data.length; i++) {
      final p = _predict(data[i]);
      final y = labels[i];
      l += (p - y) * (p - y); // MSE
    }
    loss = l / data.length;
    accuracy = _accuracy();
    setState(() {});
  }

  double _accuracy() {
    int correct = 0;
    for (int i = 0; i < data.length; i++) {
      final p = _predict(data[i]);
      final y = labels[i];
      final pred = p > 0.5 ? 1.0 : 0.0;
      if (pred == y) correct++;
    }
    return correct / data.length;
  }

  ({double g1, double g2}) _gradParamShift({List<int>? idxs}) {
    const s = pi / 2;
    final indices = idxs ?? List.generate(data.length, (i) => i);
    double eval(double a1, double a2) {
      double l = 0;
      for (final i in indices) {
        final p = _predictWith(a1, a2, data[i]);
        final y = labels[i];
        l += (p - y) * (p - y);
      }
      return l / indices.length;
    }

    Future<double> evalAsync(double a1, double a2) async =>
        eval(a1, a2); // placeholder for isolates
    if (parallelShift) {
      // Run parameter-shift evaluations concurrently
      return Future.wait([
            evalAsync(theta1 + s, theta2),
            evalAsync(theta1 - s, theta2),
            evalAsync(theta1, theta2 + s),
            evalAsync(theta1, theta2 - s),
          ]).then((vals) {
            final p1 = vals[0], m1 = vals[1], p2 = vals[2], m2 = vals[3];
            return (g1: 0.5 * (p1 - m1), g2: 0.5 * (p2 - m2));
          })
          as ({double g1, double g2});
    } else {
      final p1 = eval(theta1 + s, theta2);
      final m1 = eval(theta1 - s, theta2);
      final p2 = eval(theta1, theta2 + s);
      final m2 = eval(theta1, theta2 - s);
      return (g1: 0.5 * (p1 - m1), g2: 0.5 * (p2 - m2));
    }
  }

  double _predictWith(double a1, double a2, List<double> x) {
    final c = _buildFeatureMap(x);
    c.add(CircuitGate(type: 'RY', target: 0, theta: a1));
    c.add(CircuitGate(type: 'RY', target: 1, theta: a2));
    c.add(CircuitGate(type: 'CNOT', control: 0, target: 1));
    final st = c.run();
    final dist = st.probabilityDistribution();
    return dist['11'] ?? 0.0;
  }

  Future<void> _train() async {
    if (training) return;
    training = true;
    setState(() => {});
    double lr = 0.3;
    for (int step = 0; step < 40; step++) {
      // build batch indices
      final indices = List<int>.from(List.generate(data.length, (i) => i));
      indices.shuffle(Random());
      final used = indices.take(batchSize.clamp(1, data.length)).toList();
      final g = _gradParamShift(idxs: used);
      theta1 -= lr * g.g1;
      theta2 -= lr * g.g2;
      theta1 = ((theta1 + pi) % (2 * pi)) - pi;
      theta2 = ((theta2 + pi) % (2 * pi)) - pi;
      _evaluateLoss();
      if (!mounted) break;
      setState(() => {});
      await Future.delayed(const Duration(milliseconds: 50));
    }
    training = false;
    if (mounted) setState(() => {});
  }

  @override
  void initState() {
    super.initState();
    _loadParams().then((_) {
      _evaluateLoss();
    });
  }

  Future<void> _saveParams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('qml_params', [alpha, theta1, theta2].join(','));
  }

  Future<void> _loadParams() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('qml_params');
    if (s != null) {
      final parts = s.split(',');
      if (parts.length == 3) {
        alpha = double.tryParse(parts[0]) ?? alpha;
        theta1 = double.tryParse(parts[1]) ?? theta1;
        theta2 = double.tryParse(parts[2]) ?? theta2;
      }
    }
    setState(() => {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SectionCard(
          title: 'QML Mini Demo (Feature Map + Variational Layer)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Feature map: RY(α x0)⊗RY(α x1) + CNOT(0→1); Layer: RY(θ1), RY(θ2), CNOT.',
              ),
              Row(
                children: [
                  const Text('α'),
                  Expanded(
                    child: Slider(
                      value: alpha,
                      min: 0,
                      max: 2,
                      onChanged: (v) {
                        setState(() => alpha = v);
                        _evaluateLoss();
                        _saveParams();
                      },
                    ),
                  ),
                  SizedBox(width: 50, child: Text(alpha.toStringAsFixed(2))),
                ],
              ),
              Row(
                children: [
                  const Text('θ1'),
                  Expanded(
                    child: Slider(
                      value: theta1,
                      min: -pi,
                      max: pi,
                      onChanged: (v) {
                        setState(() => theta1 = v);
                        _evaluateLoss();
                        _saveParams();
                      },
                    ),
                  ),
                  SizedBox(width: 60, child: Text(theta1.toStringAsFixed(2))),
                ],
              ),
              Row(
                children: [
                  const Text('θ2'),
                  Expanded(
                    child: Slider(
                      value: theta2,
                      min: -pi,
                      max: pi,
                      onChanged: (v) {
                        setState(() => theta2 = v);
                        _evaluateLoss();
                        _saveParams();
                      },
                    ),
                  ),
                  SizedBox(width: 60, child: Text(theta2.toStringAsFixed(2))),
                ],
              ),
              const SizedBox(height: 8),
              if (loss != null)
                Text(
                  'Loss (MSE) = ${loss!.toStringAsFixed(4)}  |  Acc = ${(accuracy ?? 0).toStringAsFixed(2)}',
                ),
              Row(
                children: [
                  const Text('Batch'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: batchSize,
                    items: [1, 2, 4]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => batchSize = v);
                    },
                  ),
                  const SizedBox(width: 16),
                  const Text('Parallel shift'),
                  Switch(
                    value: parallelShift,
                    onChanged: (v) {
                      setState(() => parallelShift = v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: _evaluateLoss,
                    child: const Text('Evaluate'),
                  ),
                  ElevatedButton(
                    onPressed: _saveParams,
                    child: const Text('Save Params'),
                  ),
                  ElevatedButton(
                    onPressed: training
                        ? null
                        : () {
                            setState(() {
                              alpha = 1.0;
                              theta1 = 0.2;
                              theta2 = -0.4;
                            });
                            _evaluateLoss();
                            _saveParams();
                          },
                    child: const Text('Reset Params'),
                  ),
                  ElevatedButton(
                    onPressed: training ? null : _train,
                    child: Text(
                      training ? 'Training...' : 'Train (GD Param-Shift)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Predictions:'),
              Wrap(
                spacing: 8,
                children: [
                  for (int i = 0; i < data.length; i++)
                    Chip(
                      label: Text(
                        '${data[i]} → ${_predict(data[i]).toStringAsFixed(3)} (y=${labels[i]})',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
