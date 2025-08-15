import 'dart:math';
import 'package:complex/complex.dart';
import 'quantum_state.dart';
import 'quantum_gates.dart';

/// A lightweight model of a distributed quantum network consisting of nodes that each
/// hold a local register of qubits. Some pairs of qubits (across or within nodes) can be
/// entangled by sharing Bell pairs. We keep a global state vector across all qubits for
/// exact simulation (suitable only for small demo sizes: total qubits <= ~10).
///
/// Indexing convention: Each node owns a contiguous block of qubits in the global state.
/// Node 0 qubits [0..n0-1], Node1 qubits [n0 .. n0+n1-1], etc.
class QuantumNetwork {
  final List<NetworkNode> nodes = [];
  final List<EntangledPair> entangledPairs = [];
  final List<String> log = [];
  int get totalQubits => nodes.fold(0, (a, n) => a + n.qubits);
  static const int complexityWarnThreshold = 12; // 2^12=4096 amplitudes

  NetworkNoiseConfig noise = NetworkNoiseConfig();

  QuantumState _globalState = QuantumState(0);
  bool _dirty = true;

  QuantumState get globalState {
    if (_dirty) {
      _globalState = QuantumState(totalQubits);
      _dirty = false;
      log.add('[INIT] Rebuilt global state for $totalQubits qubits');
    }
    return _globalState;
  }

  void addNode(NetworkNode node) {
    nodes.add(node);
    _dirty = true;
    log.add('[NODE] Added node ${node.name} with ${node.qubits} qubits');
  }

  void deleteNode(int index) {
    if (index < 0 || index >= nodes.length) return;
    final removed = nodes.removeAt(index);
    // Remove entangled pairs involving this node
    entangledPairs.removeWhere((p) => p.aNode == index || p.bNode == index);
    // Re-index entangled pairs with node indices greater than removed
    for (int i = 0; i < entangledPairs.length; i++) {
      entangledPairs[i] = entangledPairs[i].reindexedAfterDeletion(index);
    }
    _dirty = true;
    log.add('[NODE] Deleted node ${removed.name}');
  }

  String? complexityWarning() {
    if (totalQubits > complexityWarnThreshold) {
      return 'Warning: total qubits = $totalQubits -> state size = 2^$totalQubits amplitudes (exponential growth)';
    }
    return null;
  }

  /// Returns global qubit index for (nodeIndex, localQubit)
  int globalIndex(int nodeIndex, int localQubit) {
    int offset = 0;
    for (int i = 0; i < nodeIndex; i++) {
      offset += nodes[i].qubits;
    }
    return offset + localQubit;
  }

  EntangledPair _makePair(int aNode, int aLocal, int bNode, int bLocal) =>
      EntangledPair(aNode: aNode, aLocal: aLocal, bNode: bNode, bLocal: bLocal);

  bool _pairExists(EntangledPair p) =>
      entangledPairs.contains(p) || entangledPairs.contains(p.flipped());

  /// Create an entangled Bell pair between (aNode,aLocal) and (bNode,bLocal) if not already.
  void createBellPair(int aNode, int aLocal, int bNode, int bLocal) {
    final pair = _makePair(aNode, aLocal, bNode, bLocal);
    if (_pairExists(pair)) {
      log.add('[SKIP] Bell pair already exists between ${pair.label}');
      return;
    }
    final gA = globalIndex(aNode, aLocal);
    final gB = globalIndex(bNode, bLocal);
    final state = globalState; // triggers build if dirty
    applySingleQubitGate(state, builtInGates['H']!, gA);
    applyCNOT(state, gA, gB);
    entangledPairs.add(pair);
    log.add('[ENTANGLE] Created Bell pair ${pair.label}');
    _applyNoise([gA, gB]);
  }

  /// Apply a single qubit gate to a node's local qubit.
  void applyGate(String gateType, int nodeIndex, int localQubit) {
    final gi = globalIndex(nodeIndex, localQubit);
    final gate = builtInGates[gateType];
    if (gate == null) return;
    applySingleQubitGate(globalState, gate, gi);
    log.add('[GATE] $gateType on ${nodes[nodeIndex].name}:q$localQubit');
    _applyNoise([gi]);
  }

  /// Find an entangled partner qubit in src node for a given destination node/dest qubit
  EntangledPair? findPairForTeleport(
    int srcNode,
    int dstNode,
    int dstLocal,
    int dataLocal,
  ) {
    for (final p in entangledPairs) {
      if (p.connectsNodes(srcNode, dstNode)) {
        final srcLocal = p.localIndexForNode(srcNode);
        final dstLocalIndex = p.localIndexForNode(dstNode);
        if (dstLocalIndex == dstLocal && srcLocal != dataLocal) {
          return p.oriented(srcNode, dstNode);
        }
      }
    }
    return null;
  }

  int? firstFreeQubit(int nodeIndex, {int? exclude}) {
    final used = <int>{};
    for (final p in entangledPairs) {
      if (p.aNode == nodeIndex) used.add(p.aLocal);
      if (p.bNode == nodeIndex) used.add(p.bLocal);
    }
    if (exclude != null) used.add(exclude);
    for (int i = 0; i < nodes[nodeIndex].qubits; i++) {
      if (!used.contains(i)) return i;
    }
    return null;
  }

  /// Proper teleportation protocol (simplified ideal gates, no noise).
  /// 1. Ensure Bell pair between an ancilla at srcNode and (dstNode,dstLocal).
  /// 2. Apply CNOT(data -> ancilla), H(data).
  /// 3. Measure data then ancilla qubits (Bell basis via above transforms) -> bits m1,m2.
  /// 4. Send classical bits and apply corrections on destination qubit: if m2==1 apply X, if m1==1 apply Z.
  /// Returns details map.
  Map<String, dynamic> teleport(
    int srcNode,
    int dataLocal,
    int dstNode,
    int dstLocal,
  ) {
    final ancillaPair =
        findPairForTeleport(srcNode, dstNode, dstLocal, dataLocal) ??
        _createTeleportBell(srcNode, dstNode, dstLocal, dataLocal);
    final ancillaLocal = ancillaPair.localIndexForNode(srcNode);
    final gData = globalIndex(srcNode, dataLocal);
    final gAncilla = globalIndex(srcNode, ancillaLocal);
    // Step 2
    applyCNOT(globalState, gData, gAncilla);
    applySingleQubitGate(globalState, builtInGates['H']!, gData);
    // Step 3 measurements
    final m1 = globalState.measureSingle(dataLocal); // after transforms
    final m2 = globalState.measureSingle(ancillaLocal);
    // Corrections on destination
    final gDest = globalIndex(dstNode, dstLocal);
    if (m2 == 1) applySingleQubitGate(globalState, builtInGates['X']!, gDest);
    if (m1 == 1) applySingleQubitGate(globalState, builtInGates['Z']!, gDest);
    // Remove entanglement pair (consumed)
    entangledPairs.removeWhere((p) => p.sameUndirected(ancillaPair));
    final msg =
        '[TELEPORT] data ${nodes[srcNode].name}:q$dataLocal -> ${nodes[dstNode].name}:q$dstLocal with bits ($m1,$m2)';
    log.add(msg);
    return {
      'm1': m1,
      'm2': m2,
      'message': msg,
      'ancilla': ancillaLocal,
      'remainingPairs': entangledPairs.length,
    };
  }

  EntangledPair _createTeleportBell(
    int srcNode,
    int dstNode,
    int dstLocal,
    int dataLocal,
  ) {
    final ancilla = firstFreeQubit(srcNode, exclude: dataLocal);
    if (ancilla == null) {
      throw StateError(
        'No free ancilla qubit in source node for teleportation',
      );
    }
    createBellPair(srcNode, ancilla, dstNode, dstLocal);
    return findPairForTeleport(srcNode, dstNode, dstLocal, dataLocal)!;
  }

  int entanglementCountBetween(int nodeA, int nodeB) {
    int count = 0;
    for (final p in entangledPairs) {
      if (p.connectsNodes(nodeA, nodeB)) count++;
    }
    return count;
  }

  Map<String, double> probabilityDistribution() =>
      globalState.probabilityDistribution();

  /// Attempt multi-hop entanglement swapping: find chain node1 - mid - node2.
  /// Consumes two Bell pairs and creates new one.
  bool entanglementSwap() {
    for (final p1 in entangledPairs) {
      for (final p2 in entangledPairs) {
        if (identical(p1, p2)) continue;
        // share a middle node
        if (p1.bNode == p2.aNode) {
          final nodeMid = p1.bNode;
          final nodeA = p1.aNode;
          final nodeC = p2.bNode;
          // perform swap (simplified: remove p1,p2 and create new entanglement)
          final aLocal = p1.aLocal;
          final cLocal = p2.bLocal;
          entangledPairs.remove(p1);
          entangledPairs.remove(p2);
          // create new Bell between A and C (idealized)
          createBellPair(nodeA, aLocal, nodeC, cLocal);
          log.add(
            '[SWAP] Swapped via node ${nodes[nodeMid].name} -> new pair (${nodeA}:q$aLocal)↔(${nodeC}:q$cLocal)',
          );
          return true;
        }
      }
    }
    log.add('[SWAP] No suitable chain found');
    return false;
  }

  /// Apply simple noise after operations.
  void _applyNoise(List<int> globalIndices) {
    if (!noise.enabled) return;
    final rnd = noise.rng;
    for (final gi in globalIndices) {
      if (rnd.nextDouble() < noise.pBitFlip) {
        applySingleQubitGate(globalState, builtInGates['X']!, gi);
        log.add('[NOISE] Bit-flip on g$gi');
      }
      if (rnd.nextDouble() < noise.pPhaseFlip) {
        applySingleQubitGate(globalState, builtInGates['Z']!, gi);
        log.add('[NOISE] Phase-flip on g$gi');
      }
    }
  }

  /// Reduced density matrix for subset of global qubit indices (0=MSB ordering).
  /// Expensive: O(4^N) worst-case; use for small N.
  List<List<Complex>> reducedDensityMatrix(List<int> subset) {
    subset = subset.toSet().toList()..sort();
    final N = totalQubits;
    final k = subset.length;
    final dim = 1 << k;
    final amps = globalState.amplitudes;
    final rho = List.generate(
      dim,
      (_) => List.generate(dim, (_) => Complex.zero),
    );
    // Precompute masks
    final envBits = [
      for (int i = 0; i < N; i++)
        if (!subset.contains(i)) i,
    ];
    // Map full index -> (sIndex, eIndex) integers
    List<int> subsetMap = List.filled(1 << N, 0);
    List<int> envMap = List.filled(1 << N, 0);
    for (int full = 0; full < (1 << N); full++) {
      int s = 0;
      int e = 0;
      for (final b in subset) {
        s = (s << 1) | ((full >> (N - b - 1)) & 1);
      }
      for (final b in envBits) {
        e = (e << 1) | ((full >> (N - b - 1)) & 1);
      }
      subsetMap[full] = s;
      envMap[full] = e;
    }
    final envSize = 1 << envBits.length;
    // For each environment assignment, gather indices belonging to that env pattern grouped by subset pattern
    List<List<List<int>>> buckets = List.generate(
      envSize,
      (_) => List.generate(dim, (_) => <int>[]),
    );
    for (int full = 0; full < (1 << N); full++) {
      buckets[envMap[full]][subsetMap[full]].add(full);
    }
    for (int e = 0; e < envSize; e++) {
      for (int s1 = 0; s1 < dim; s1++) {
        for (int s2 = 0; s2 < dim; s2++) {
          Complex acc = Complex.zero;
          // cross indices with identical environment -> amplitude products
          for (final i in buckets[e][s1]) {
            for (final j in buckets[e][s2]) {
              acc += amps[i] * amps[j].conjugate();
            }
          }
          rho[s1][s2] = rho[s1][s2] + acc;
        }
      }
    }
    return rho;
  }
}

class EntangledPair {
  final int aNode;
  final int aLocal;
  final int bNode;
  final int bLocal;
  EntangledPair({
    required this.aNode,
    required this.aLocal,
    required this.bNode,
    required this.bLocal,
  });

  String get label => '(${aNode}:q$aLocal)↔(${bNode}:q$bLocal)';

  EntangledPair flipped() =>
      EntangledPair(aNode: bNode, aLocal: bLocal, bNode: aNode, bLocal: aLocal);
  EntangledPair reindexedAfterDeletion(int deletedIndex) {
    int mapNode(int n) => n > deletedIndex ? n - 1 : n;
    return EntangledPair(
      aNode: mapNode(aNode),
      aLocal: aLocal,
      bNode: mapNode(bNode),
      bLocal: bLocal,
    );
  }

  bool connectsNodes(int n1, int n2) =>
      (aNode == n1 && bNode == n2) || (aNode == n2 && bNode == n1);
  bool sameUndirected(EntangledPair other) =>
      connectsNodes(other.aNode, other.bNode) &&
      ((aLocal == other.aLocal && bLocal == other.bLocal) ||
          (aLocal == other.bLocal && bLocal == other.aLocal));
  int localIndexForNode(int node) {
    if (aNode == node) return aLocal;
    if (bNode == node) return bLocal;
    throw ArgumentError('Pair does not include node');
  }

  EntangledPair oriented(int srcNode, int dstNode) {
    if (aNode == srcNode && bNode == dstNode) return this;
    if (bNode == srcNode && aNode == dstNode) return flipped();
    return this;
  }

  @override
  bool operator ==(Object other) =>
      other is EntangledPair &&
      aNode == other.aNode &&
      aLocal == other.aLocal &&
      bNode == other.bNode &&
      bLocal == other.bLocal;
  @override
  int get hashCode => Object.hash(aNode, aLocal, bNode, bLocal);
}

class NetworkNoiseConfig {
  bool enabled = false;
  double pBitFlip = 0.0; // probability per affected qubit per op
  double pPhaseFlip = 0.0;
  final Random rng = Random();
}

class NetworkNode {
  final String name;
  final int qubits;
  NetworkNode({required this.name, required this.qubits});
}
