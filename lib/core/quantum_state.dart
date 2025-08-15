import 'dart:math';
import 'package:complex/complex.dart';

/// Represents the state vector of n qubits. Length = 2^n complex amplitudes.
class QuantumState {
  final int qubitCount;
  late List<Complex> amplitudes;

  QuantumState(this.qubitCount) {
    final size = 1 << qubitCount;
    amplitudes = List.generate(size, (i) => Complex.zero);
    amplitudes[0] = Complex.one; // |00..0>
  }

  QuantumState.from(this.qubitCount, List<Complex> amps)
    : amplitudes = List.of(amps) {
    assert(amps.length == 1 << qubitCount);
  }

  QuantumState copy() => QuantumState.from(qubitCount, amplitudes);

  void normalize() {
    final norm = sqrt(
      amplitudes.map((a) => a.abs() * a.abs()).fold<double>(0, (a, b) => a + b),
    );
    if (norm == 0) return;
    amplitudes = amplitudes.map((a) => a / Complex(norm)).toList();
  }

  /// Measure collapses state: returns bitstring result.
  String measure({Random? rng}) {
    rng ??= Random();
    final probs = amplitudes.map((a) => a.abs() * a.abs()).toList();
    final total = probs.fold<double>(0, (a, b) => a + b);
    final r = rng.nextDouble() * total;
    double cum = 0;
    for (var i = 0; i < probs.length; i++) {
      cum += probs[i];
      if (r <= cum) {
        amplitudes = List.generate(amplitudes.length, (_) => Complex.zero);
        amplitudes[i] = Complex.one;
        final bits = i.toRadixString(2).padLeft(qubitCount, '0');
        return bits;
      }
    }
    return ''.padLeft(qubitCount, '0');
  }

  Map<String, double> probabilityDistribution() {
    final map = <String, double>{};
    for (var i = 0; i < amplitudes.length; i++) {
      final bits = i.toRadixString(2).padLeft(qubitCount, '0');
      map[bits] = amplitudes[i].abs() * amplitudes[i].abs();
    }
    return map;
  }

  /// Measure a single qubit (by index 0..qubitCount-1, with 0 = most significant) collapsing only that qubit.
  /// Returns 0 or 1. State is renormalized.
  int measureSingle(int qubit, {Random? rng}) {
    rng ??= Random();
    final shift = qubitCount - qubit - 1; // bit position in index
    double p1 = 0;
    for (int i = 0; i < amplitudes.length; i++) {
      if (((i >> shift) & 1) == 1) {
        final a = amplitudes[i];
        p1 += a.abs() * a.abs();
      }
    }
    final r = rng.nextDouble();
    final outcome = r < p1 ? 1 : 0;
    for (int i = 0; i < amplitudes.length; i++) {
      if (((i >> shift) & 1) != outcome) {
        amplitudes[i] = Complex.zero;
      }
    }
    normalize();
    return outcome;
  }
}
