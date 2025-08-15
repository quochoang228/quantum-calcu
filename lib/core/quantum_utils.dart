import 'dart:math';
import 'package:complex/complex.dart';
import 'quantum_state.dart';
import 'quantum_gates.dart';

/// 3-qubit bit-flip code utilities & VQE/RNG helpers.

QuantumState encodeBitFlip(QuantumState singleQubit) {
  if (singleQubit.qubitCount != 1) {
    throw ArgumentError('Input must be 1-qubit state');
  }
  final encoded = QuantumState(3);
  final a0 = singleQubit.amplitudes[0];
  final a1 = singleQubit.amplitudes[1];
  encoded.amplitudes = List.generate(8, (_) => Complex.zero);
  encoded.amplitudes[0] = a0; // |000>
  encoded.amplitudes[7] = a1; // |111>
  encoded.normalize();
  return encoded;
}

void injectBitFlipError(QuantumState state, double pEach, {Random? rng}) {
  rng ??= Random();
  if (state.qubitCount != 3) return;
  for (var q = 0; q < 3; q++) {
    if (rng.nextDouble() < pEach) {
      applySingleQubitGate(state, SingleQubitGate.pauliX, q);
      break;
    }
  }
}

(int, int) measureBitFlipSyndrome(QuantumState state) {
  int bestIndex = 0;
  double bestProb = -1;
  for (int i = 0; i < state.amplitudes.length; i++) {
    final p = state.amplitudes[i].abs() * state.amplitudes[i].abs();
    if (p > bestProb) {
      bestProb = p;
      bestIndex = i;
    }
  }
  final b = bestIndex.toRadixString(2).padLeft(3, '0');
  final z1 = b[0] == '1' ? -1 : 1;
  final z2 = b[1] == '1' ? -1 : 1;
  final z3 = b[2] == '1' ? -1 : 1;
  final s1 = (z1 * z2) == 1 ? 0 : 1;
  final s2 = (z2 * z3) == 1 ? 0 : 1;
  return (s1, s2);
}

void correctBitFlip(QuantumState state, (int, int) syndrome) {
  final (s1, s2) = syndrome;
  if (state.qubitCount != 3) return;
  if (s1 == 1 && s2 == 0) {
    applySingleQubitGate(state, SingleQubitGate.pauliX, 0);
  } else if (s1 == 1 && s2 == 1) {
    applySingleQubitGate(state, SingleQubitGate.pauliX, 1);
  } else if (s1 == 0 && s2 == 1) {
    applySingleQubitGate(state, SingleQubitGate.pauliX, 2);
  }
}

List<int> quantumRandomBits(int count, {Random? rng}) {
  rng ??= Random();
  final bits = <int>[];
  for (var i = 0; i < count; i++) {
    final q = QuantumState(1);
    applySingleQubitGate(q, SingleQubitGate.hadamard, 0);
    final res = q.measure(rng: rng);
    bits.add(int.parse(res));
  }
  return bits;
}

double expectationZZ(QuantumState state) {
  if (state.qubitCount != 2) throw ArgumentError('Needs 2-qubit state');
  double exp = 0;
  for (int i = 0; i < state.amplitudes.length; i++) {
    final bits = i.toRadixString(2).padLeft(2, '0');
    int z1 = bits[0] == '1' ? -1 : 1;
    int z2 = bits[1] == '1' ? -1 : 1;
    final p = state.amplitudes[i].abs() * state.amplitudes[i].abs();
    exp += z1 * z2 * p;
  }
  return exp;
}

QuantumState vqeAnsatz(double theta1, double theta2) {
  final st = QuantumState(2);
  applySingleQubitGate(st, SingleQubitGate.ry(theta1), 0);
  final size = st.amplitudes.length;
  final newAmps = List<Complex>.from(st.amplitudes);
  for (int i = 0; i < size; i++) {
    final controlBit = (i >> 0) & 1;
    if (controlBit == 1) {
      final flipped = i ^ (1 << 1);
      newAmps[flipped] = st.amplitudes[i];
    }
  }
  st.amplitudes = newAmps;
  applySingleQubitGate(st, SingleQubitGate.ry(theta2), 1);
  return st;
}

({double d1, double d2, double value}) vqeGradient(
  double t1,
  double t2, {
  bool parameterShift = true,
  double eps = 1e-5,
}) {
  final base = expectationZZ(vqeAnsatz(t1, t2));
  if (parameterShift) {
    const double shift = pi / 2; // parameter-shift rule
    final f1p = expectationZZ(vqeAnsatz(t1 + shift, t2));
    final f1m = expectationZZ(vqeAnsatz(t1 - shift, t2));
    final f2p = expectationZZ(vqeAnsatz(t1, t2 + shift));
    final f2m = expectationZZ(vqeAnsatz(t1, t2 - shift));
    final d1 = 0.5 * (f1p - f1m);
    final d2 = 0.5 * (f2p - f2m);
    return (d1: d1, d2: d2, value: base);
  } else {
    final v1p = expectationZZ(vqeAnsatz(t1 + eps, t2));
    final v2p = expectationZZ(vqeAnsatz(t1, t2 + eps));
    return (d1: (v1p - base) / eps, d2: (v2p - base) / eps, value: base);
  }
}

// ================= Entanglement & Correlation Metrics =================

/// <Z_i> expectation for single qubit i.
double expectationZ(QuantumState state, int qubit) {
  if (qubit < 0 || qubit >= state.qubitCount) {
    throw ArgumentError('qubit out of range');
  }
  double exp = 0;
  for (int i = 0; i < state.amplitudes.length; i++) {
    final bit = (i >> (state.qubitCount - 1 - qubit)) & 1; // MSB ordering
    final z = bit == 1 ? -1 : 1;
    final p = state.amplitudes[i].abs() * state.amplitudes[i].abs();
    exp += z * p;
  }
  return exp;
}

/// <Z_i Z_j> correlation.
double correlationZZ(QuantumState state, int qi, int qj) {
  if (qi == qj) return 1.0;
  if (qi < 0 || qj < 0 || qi >= state.qubitCount || qj >= state.qubitCount) {
    throw ArgumentError('qubit out of range');
  }
  double exp = 0;
  for (int i = 0; i < state.amplitudes.length; i++) {
    final bitI = (i >> (state.qubitCount - 1 - qi)) & 1;
    final bitJ = (i >> (state.qubitCount - 1 - qj)) & 1;
    final zI = bitI == 1 ? -1 : 1;
    final zJ = bitJ == 1 ? -1 : 1;
    final p = state.amplitudes[i].abs() * state.amplitudes[i].abs();
    exp += (zI * zJ) * p;
  }
  return exp;
}

/// Very rough single-qubit purity approximation by tracing out others:  (1 + <Z>^2)/2.
double singleQubitPurityApprox(QuantumState state, int qubit) {
  final ez = expectationZ(state, qubit);
  // For states built from H / phase / CNOT networks, X/Y expectations often 0 in computational basis measurement.
  return (1 + ez * ez) / 2.0;
}

// ================= Simplified Shor Code (only bit-flip + phase-flip separated) =================

/// Encode 1 logical qubit into 9 (|0_L> = (|000>+|111>)^{\otimes 3}/2^{3/2}).
QuantumState encodeShor(QuantumState logical) {
  if (logical.qubitCount != 1) {
    throw ArgumentError('Need 1-qubit logical input');
  }
  // Start from |psi> = a|0> + b|1>
  final a = logical.amplitudes[0];
  final b = logical.amplitudes[1];
  final st = QuantumState(9);
  st.amplitudes = List.generate(1 << 9, (_) => Complex.zero);
  // Build |0_L> and |1_L> basis (simplified):
  // |0_L> ~ (|000>+|111>) (|000>+|111>) (|000>+|111>) / (2*sqrt(2)) normalization factor = 1/(2^{3/2}).
  // We'll just enumerate all 8 patterns where each triple is either 000 or 111.
  // Using decimal 7 for binary 111.
  final triples = [0, 7];
  List<int> basis0 = [];
  for (final t1 in triples) {
    for (final t2 in triples) {
      for (final t3 in triples) {
        final idx = (t1 << 6) | (t2 << 3) | t3;
        basis0.add(idx);
      }
    }
  }
  final normFactor = 1 / sqrt(8); // 8 terms.
  for (final idx in basis0) {
    st.amplitudes[idx] = a * Complex(normFactor, 0);
  }
  // |1_L> uses phase flips on each triple: (|000>-|111>)^3.
  for (final t1 in triples) {
    for (final t2 in triples) {
      for (final t3 in triples) {
        final sign =
            ((t1 == 0 ? 1 : -1) * (t2 == 0 ? 1 : -1) * (t3 == 0 ? 1 : -1))
                .toDouble();
        final idx = (t1 << 6) | (t2 << 3) | t3;
        st.amplitudes[idx] += b * Complex(normFactor * sign, 0);
      }
    }
  }
  st.normalize();
  return st;
}

/// Inject either a bit-flip (X) or phase-flip (Z) error at a random physical qubit among 9 with given probabilities.
void injectShorBitPhaseError(
  QuantumState state, {
  double pX = 0.0,
  double pZ = 0.0,
  Random? rng,
}) {
  if (state.qubitCount != 9) return;
  rng ??= Random();
  for (int q = 0; q < 9; q++) {
    final r = rng.nextDouble();
    if (r < pX) {
      applySingleQubitGate(state, SingleQubitGate.pauliX, q);
    } else if (r < pX + pZ) {
      applySingleQubitGate(state, SingleQubitGate.pauliZ, q);
    }
  }
}

/// Very simplified syndrome: we estimate which triple likely has an X error by majority vote of probability mass in patterns.
Map<String, int> shorSyndrome(QuantumState state) {
  if (state.qubitCount != 9) throw ArgumentError('Need 9-qubit Shor state');
  // We'll compute population probabilities for each triple group to guess bit-flip errors.
  final tripleScores = List<double>.filled(3, 0);
  for (int i = 0; i < state.amplitudes.length; i++) {
    final p = state.amplitudes[i].abs() * state.amplitudes[i].abs();
    final bits = i.toRadixString(2).padLeft(9, '0');
    for (int g = 0; g < 3; g++) {
      final seg = bits.substring(g * 3, g * 3 + 3);
      if (seg == '000' || seg == '111') {
        tripleScores[g] += p;
      }
    }
  }
  // Lower score might indicate corruption (since ideal contributes to aligned patterns). We'll mark group with min score.
  int suspect = 0;
  double minScore = tripleScores[0];
  for (int g = 1; g < 3; g++) {
    if (tripleScores[g] < minScore) {
      minScore = tripleScores[g];
      suspect = g;
    }
  }
  return {'suspectTriple': suspect};
}

/// Apply a naive corrective majority vote flip to the suspect triple (attempting to fix a single X error). Phase error correction omitted here.
void correctShorSimplified(QuantumState state, Map<String, int> syndrome) {
  if (state.qubitCount != 9) return;
  final suspect = syndrome['suspectTriple'];
  if (suspect == null) return;
  // We can't perform projection here; we simulate by boosting amplitudes consistent with majority (very heuristic).
  // For simplicity, do nothing (placeholder): in a real code we'd perform stabilizer measurements.
}

// ================= Circuit Synthesis (very small oracle builder stub) =================

class CircuitGateSpec {
  final String type; // e.g. 'X','H','CNOT','PHASE'
  final int target;
  final int? control;
  final double? theta;
  CircuitGateSpec(this.type, this.target, {this.control, this.theta});
}

/// Synthesize a phase oracle marking specified solution indices with Z phase flips.
List<CircuitGateSpec> synthesizePhaseOracle(int qubits, List<int> solutions) {
  // Very naive: for each solution bitstring, apply X to negate bits that are 0, multi-controlled Z, then undo X.
  // We approximate multi-controlled Z as cascade of CNOTs + single Z on last qubit + inverse cascade (not physically accurate in this simplified model).
  final specs = <CircuitGateSpec>[];
  for (final sol in solutions) {
    // Pre X flips
    for (int q = 0; q < qubits; q++) {
      final bit = (sol >> (qubits - 1 - q)) & 1;
      if (bit == 0) specs.add(CircuitGateSpec('X', q));
    }
    // Placeholder for multi-controlled Z: we'll just put a single Z on last qubit if all controls 1 after flips.
    specs.add(CircuitGateSpec('Z', qubits - 1));
    // Undo X flips
    for (int q = 0; q < qubits; q++) {
      final bit = (sol >> (qubits - 1 - q)) & 1;
      if (bit == 0) specs.add(CircuitGateSpec('X', q));
    }
  }
  return specs;
}

// ================== Quantum Key Distribution (BB84) Simulation ==================

class Bb84Result {
  final List<int> aliceBits;
  final List<int> aliceBases; // 0 = Z, 1 = X
  final List<int> bobBases;
  final List<int?> bobResults; // null if lost
  final List<int> siftedKey;
  final double quantumBitErrorRate;
  Bb84Result({
    required this.aliceBits,
    required this.aliceBases,
    required this.bobBases,
    required this.bobResults,
    required this.siftedKey,
    required this.quantumBitErrorRate,
  });
}

Bb84Result runBb84(
  int n, {
  double lossProb = 0.0,
  double eavesdropProb = 0.0,
  Random? rng,
}) {
  rng ??= Random();
  final aliceBits = List<int>.generate(n, (_) => rng!.nextInt(2));
  final aliceBases = List<int>.generate(n, (_) => rng!.nextInt(2));
  final bobBases = List<int>.generate(n, (_) => rng!.nextInt(2));
  final bobResults = List<int?>.filled(n, null);

  for (int i = 0; i < n; i++) {
    if (rng.nextDouble() < lossProb) {
      continue; // photon lost
    }
    int bit = aliceBits[i];
    int basis = aliceBases[i];
    // Eavesdropper intercept-resend with probability eavesdropProb
    if (rng.nextDouble() < eavesdropProb) {
      final eveBasis = rng.nextInt(2);
      // Eve measures; if bases mismatch she randomizes bit effectively
      if (eveBasis != basis) {
        bit = rng.nextInt(2); // collapse random
        basis = eveBasis; // she resends in her basis with her measured bit
      }
    }
    // Bob measures
    if (bobBases[i] == basis) {
      bobResults[i] = bit; // perfect if same basis (ignoring noise)
    } else {
      bobResults[i] = rng.nextInt(2); // random outcome
    }
  }

  final siftedKey = <int>[];
  int errors = 0;
  int compared = 0;
  for (int i = 0; i < n; i++) {
    if (bobResults[i] == null) continue;
    if (aliceBases[i] == bobBases[i]) {
      // Keep for key
      siftedKey.add(bobResults[i]!);
      if (bobResults[i] != aliceBits[i]) errors++;
      compared++;
    }
  }
  final qber = compared == 0 ? 0.0 : errors / compared;
  return Bb84Result(
    aliceBits: aliceBits,
    aliceBases: aliceBases,
    bobBases: bobBases,
    bobResults: bobResults,
    siftedKey: siftedKey,
    quantumBitErrorRate: qber,
  );
}
