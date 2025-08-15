import 'package:complex/complex.dart';
import 'dart:math';
import 'quantum_state.dart';

/// Basic single qubit gate matrix (2x2).
class SingleQubitGate {
  final List<List<Complex>> m; // row-major 2x2
  final String name;
  const SingleQubitGate(this.name, this.m);

  static final hadamard = SingleQubitGate('H', [
    [Complex(1 / sqrt2, 0), Complex(1 / sqrt2, 0)],
    [Complex(1 / sqrt2, 0), Complex(-1 / sqrt2, 0)],
  ]);
  static final pauliX = SingleQubitGate('X', [
    [Complex.zero, Complex.one],
    [Complex.one, Complex.zero],
  ]);
  static final pauliY = SingleQubitGate('Y', [
    [Complex.zero, Complex.i * const Complex(-1, 0)],
    [Complex.i, Complex.zero],
  ]);
  static final pauliZ = SingleQubitGate('Z', [
    [Complex.one, Complex.zero],
    [Complex.zero, const Complex(-1, 0)],
  ]);
  static SingleQubitGate phase(double theta) => SingleQubitGate('P(θ)', [
    [Complex.one, Complex.zero],
    [Complex.zero, Complex(cos(theta), sin(theta))],
  ]);
  static SingleQubitGate ry(double theta) => SingleQubitGate('RY', [
    [Complex(cos(theta / 2), 0), Complex(-sin(theta / 2), 0)],
    [Complex(sin(theta / 2), 0), Complex(cos(theta / 2), 0)],
  ]);
}

const double sqrt2 = 1.4142135623730951;

final builtInGates = <String, SingleQubitGate>{
  'H': SingleQubitGate.hadamard,
  'X': SingleQubitGate.pauliX,
  'Y': SingleQubitGate.pauliY,
  'Z': SingleQubitGate.pauliZ,
};

/// Apply a single qubit gate to target qubit index (0 = least significant).
void applySingleQubitGate(
  QuantumState state,
  SingleQubitGate gate,
  int target,
) {
  final size = state.amplitudes.length;
  final newAmps = List<Complex>.from(state.amplitudes);
  for (var basis = 0; basis < size; basis++) {
    final bit = (basis >> target) & 1;
    final partner = basis ^ (1 << target);
    if (bit == 0) {
      final a0 = state.amplitudes[basis];
      final a1 = state.amplitudes[partner];
      newAmps[basis] = gate.m[0][0] * a0 + gate.m[0][1] * a1;
      newAmps[partner] = gate.m[1][0] * a0 + gate.m[1][1] * a1;
    }
  }
  state.amplitudes = newAmps;
  state.normalize();
}

/// Apply CNOT with control and target (control != target).
void applyCNOT(QuantumState state, int control, int target) {
  final size = state.amplitudes.length;
  final newAmps = List<Complex>.from(state.amplitudes);
  for (var basis = 0; basis < size; basis++) {
    final controlBit = (basis >> control) & 1;
    if (controlBit == 1) {
      final flipped = basis ^ (1 << target);
      newAmps[flipped] = state.amplitudes[basis];
    }
  }
  state.amplitudes = newAmps;
}

/// Apply a custom 2x2 matrix gate to a target qubit.
void applyCustomMatrix(
  QuantumState state,
  List<List<Complex>> matrix,
  int target,
) {
  final gate = SingleQubitGate('Custom', matrix);
  applySingleQubitGate(state, gate, target);
}
