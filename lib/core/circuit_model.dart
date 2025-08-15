import 'dart:convert';
import 'dart:math';
import 'package:complex/complex.dart';
import 'quantum_state.dart';
import 'quantum_gates.dart';

class CircuitGate {
  final String
  type; // H, X, Y, Z, CNOT, PHASE, RY, CUSTOM, CPHASE, SWAP, MEASURE
  final int target;
  final int? control; // for CNOT / CPHASE / SWAP second qubit
  final double? theta; // for phase, RY, controlled phase
  final List<List<Complex>>? custom; // 2x2 matrix
  final int? measResult; // for MEASURE pseudo gate display
  CircuitGate({
    required this.type,
    required this.target,
    this.control,
    this.theta,
    this.custom,
    this.measResult,
  });

  CircuitGate copy() => CircuitGate(
    type: type,
    target: target,
    control: control,
    theta: theta,
    custom: custom == null
        ? null
        : [
            for (final r in custom!) [for (final c in r) c],
          ],
    measResult: measResult,
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'target': target,
    if (control != null) 'control': control,
    if (theta != null) 'theta': theta,
    if (measResult != null) 'meas': measResult,
    if (custom != null)
      'custom': custom
          ?.map(
            (row) => row.map((c) => {'re': c.real, 'im': c.imaginary}).toList(),
          )
          .toList(),
  };

  static CircuitGate fromJson(Map<String, dynamic> json) => CircuitGate(
    type: json['type'],
    target: json['target'],
    control: json['control'],
    theta: (json['theta'] as num?)?.toDouble(),
    custom: json['custom'] == null
        ? null
        : (json['custom'] as List)
              .map(
                (row) => (row as List)
                    .map(
                      (c) => Complex(
                        (c['re'] as num).toDouble(),
                        (c['im'] as num).toDouble(),
                      ),
                    )
                    .toList(),
              )
              .toList(),
    measResult: json['meas'],
  );
}

class QuantumCircuit {
  int qubits;
  final List<CircuitGate> gates;
  QuantumCircuit({required this.qubits, List<CircuitGate>? gates})
    : gates = gates ?? [];

  void add(CircuitGate g) => gates.add(g);
  void clear() => gates.clear();

  QuantumState run() {
    final state = QuantumState(qubits);
    for (final g in gates) {
      switch (g.type) {
        case 'H':
        case 'X':
        case 'Y':
        case 'Z':
          final gate = builtInGates[g.type]!;
          applySingleQubitGate(state, gate, g.target);
          break;
        case 'RY':
          applySingleQubitGate(
            state,
            SingleQubitGate.ry(g.theta ?? 0),
            g.target,
          );
          break;
        case 'CNOT':
          applyCNOT(state, g.control!, g.target);
          break;
        case 'PHASE':
          applySingleQubitGate(
            state,
            SingleQubitGate.phase(g.theta!),
            g.target,
          );
          break;
        case 'CPHASE':
          _applyControlledPhase(state, g.control!, g.target, g.theta ?? 0);
          break;
        case 'SWAP':
          _applySwap(state, g.target, g.control!);
          break;
        case 'MEASURE':
          // pseudo gate: does nothing during replay
          break;
        case 'CUSTOM':
          applyCustomMatrix(state, g.custom!, g.target);
          break;
      }
    }
    return state;
  }

  String toJsonString() => jsonEncode({
    'qubits': qubits,
    'gates': gates.map((g) => g.toJson()).toList(),
  });
  static QuantumCircuit fromJsonString(String s) {
    final data = jsonDecode(s);
    return QuantumCircuit(
      qubits: data['qubits'],
      gates: (data['gates'] as List)
          .map((e) => CircuitGate.fromJson(e))
          .toList(),
    );
  }

  /// Returns (originalCount, optimizedCount)
  (int, int) optimize() {
    final before = gates.length;
    _cancelInverses();
    _applyTemplates();
    _commuteReorder();
    _mergePhases();
    return (before, gates.length);
  }

  List<OptimizationPassResult> optimizeDetailed() {
    final passes = <OptimizationPassResult>[];
    int before = gates.length;
    final depth0 = depth();
    _cancelInverses();
    passes.add(
      OptimizationPassResult(
        'Inverse Cancellation',
        before,
        gates.length,
        depth0,
        depth(),
      ),
    );
    before = gates.length;
    final dBeforeTemplates = depth();
    _applyTemplates();
    passes.add(
      OptimizationPassResult(
        'Template Reduction',
        before,
        gates.length,
        dBeforeTemplates,
        depth(),
      ),
    );
    before = gates.length;
    final dBeforeCommute = depth();
    _commuteReorder();
    passes.add(
      OptimizationPassResult(
        'Commutation Reorder',
        before,
        gates.length,
        dBeforeCommute,
        depth(),
      ),
    );
    before = gates.length;
    final dBeforeMerge = depth();
    _mergePhases();
    passes.add(
      OptimizationPassResult(
        'Phase/RY Merge',
        before,
        gates.length,
        dBeforeMerge,
        depth(),
      ),
    );
    return passes;
  }

  void _cancelInverses() {
    // Simple linear scan removing adjacent inverse pairs for self-inverse gates.
    // Self-inverse: H, X, Y, Z, CNOT (same control/target consecutively)
    int i = 0;
    while (i < gates.length - 1) {
      final a = gates[i];
      final b = gates[i + 1];
      bool removable = false;
      if (a.type == b.type && a.target == b.target) {
        if ({'H', 'X', 'Y', 'Z'}.contains(a.type)) removable = true;
        if (a.type == 'CNOT' && a.control == b.control) removable = true;
      }
      if (removable) {
        gates.removeAt(i + 1);
        gates.removeAt(i);
        if (i > 0) i--; // step back to catch cascading
      } else {
        i++;
      }
    }
  }

  void _mergePhases() {
    // Merge consecutive PHASE or RY gates on same target by adding angles.
    int i = 0;
    while (i < gates.length - 1) {
      final a = gates[i];
      final b = gates[i + 1];
      if (a.target == b.target) {
        if (a.type == 'PHASE' && b.type == 'PHASE') {
          double ang = (a.theta ?? 0) + (b.theta ?? 0);
          ang = ang % (2 * pi);
          if (ang.abs() < 1e-9 || (2 * pi - ang).abs() < 1e-9) {
            // Remove both (effectively identity)
            gates.removeAt(i + 1);
            gates.removeAt(i);
            if (i > 0) i--;
            continue;
          }
          final merged = CircuitGate(
            type: 'PHASE',
            target: a.target,
            theta: ang,
          );
          gates[i] = merged;
          gates.removeAt(i + 1);
          continue;
        } else if (a.type == 'RY' && b.type == 'RY') {
          double ang = (a.theta ?? 0) + (b.theta ?? 0);
          ang = ang % (2 * pi);
          if (ang.abs() < 1e-9 || (2 * pi - ang).abs() < 1e-9) {
            gates.removeAt(i + 1);
            gates.removeAt(i);
            if (i > 0) i--;
            continue;
          }
          final merged = CircuitGate(type: 'RY', target: a.target, theta: ang);
          gates[i] = merged;
          gates.removeAt(i + 1);
          continue;
        }
      }
      i++;
    }
  }

  void _applyTemplates() {
    // Patterns: H X H -> Z, H Z H -> X
    int i = 0;
    while (i <= gates.length - 3) {
      final a = gates[i];
      final b = gates[i + 1];
      final c = gates[i + 2];
      if (a.target == b.target && b.target == c.target) {
        if (a.type == 'H' && b.type == 'X' && c.type == 'H') {
          gates.removeRange(i, i + 3);
          gates.insert(i, CircuitGate(type: 'Z', target: a.target));
          if (i > 0)
            i--;
          else
            i++;
          continue;
        }
        if (a.type == 'H' && b.type == 'Z' && c.type == 'H') {
          gates.removeRange(i, i + 3);
          gates.insert(i, CircuitGate(type: 'X', target: a.target));
          if (i > 0)
            i--;
          else
            i++;
          continue;
        }
      }
      i++;
    }
  }

  void _commuteReorder() {
    // Simple heuristic: bubble single-qubit gates forward past commuting gates to cluster by target
    bool moved = true;
    int passes = 0;
    while (moved && passes < 4) {
      // limit iterations
      moved = false;
      passes++;
      for (int i = 0; i < gates.length - 1; i++) {
        final g1 = gates[i];
        final g2 = gates[i + 1];
        if (_isSingle(g1) && _isSingle(g2) && g1.target != g2.target) {
          // commute: swap order to group by target if g2 has same type/target as earlier gate
          // heuristic: if g2 matches earlier gate type/target of g1's predecessor, skip
          // simpler: sort by target index locally
          if (g2.target < g1.target) {
            gates[i] = g2;
            gates[i + 1] = g1;
            moved = true;
          }
        }
      }
    }
  }

  bool _isSingle(CircuitGate g) =>
      {'H', 'X', 'Y', 'Z', 'PHASE', 'RY', 'CUSTOM'}.contains(g.type);

  int depth() {
    // Greedy layering: assign earliest layer with no qubit conflict
    final layers = <List<CircuitGate>>[];
    for (final g in gates) {
      int layerIndex = 0;
      while (true) {
        if (layerIndex == layers.length) layers.add([]);
        final layer = layers[layerIndex];
        if (_fitsInLayer(layer, g)) {
          layer.add(g);
          break;
        }
        layerIndex++;
      }
    }
    return layers.length;
  }

  bool _fitsInLayer(List<CircuitGate> layer, CircuitGate g) {
    for (final h in layer) {
      final qubitsG = _gateQubits(g);
      final qubitsH = _gateQubits(h);
      if (qubitsG.any((q) => qubitsH.contains(q))) return false;
    }
    return true;
  }

  List<int> _gateQubits(CircuitGate g) {
    if (g.type == 'CNOT' || g.type == 'CPHASE' || g.type == 'SWAP') {
      return [g.target, g.control!];
    }
    return [g.target];
  }
}

void _applyControlledPhase(
  QuantumState state,
  int control,
  int target,
  double theta,
) {
  final size = state.amplitudes.length;
  final phase = Complex(cos(theta), sin(theta));
  for (var i = 0; i < size; i++) {
    final cBit = (i >> control) & 1;
    final tBit = (i >> target) & 1;
    if (cBit == 1 && tBit == 1) {
      state.amplitudes[i] = state.amplitudes[i] * phase;
    }
  }
}

void _applySwap(QuantumState state, int a, int b) {
  if (a == b) return;
  // implement via 3 CNOT for simplicity
  applyCNOT(state, a, b);
  applyCNOT(state, b, a);
  applyCNOT(state, a, b);
}

class OptimizationPassResult {
  final String name;
  final int before;
  final int after;
  final int beforeDepth;
  final int afterDepth;
  int get removed => before - after;
  int get depthDelta => afterDepth - beforeDepth;
  OptimizationPassResult(
    this.name,
    this.before,
    this.after,
    this.beforeDepth,
    this.afterDepth,
  );
}
