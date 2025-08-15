import 'package:flutter/material.dart';
import '../core/quantum_network.dart';
import '../ui/style.dart';

class QuantumNetworkScreen extends StatefulWidget {
  const QuantumNetworkScreen({super.key});

  @override
  State<QuantumNetworkScreen> createState() => _QuantumNetworkScreenState();
}

class _QuantumNetworkScreenState extends State<QuantumNetworkScreen> {
  final QuantumNetwork network = QuantumNetwork();
  final TextEditingController _nodeNameCtrl = TextEditingController();
  final TextEditingController _nodeQubitsCtrl = TextEditingController(
    text: '2',
  );
  int _densityNodeIndex = 0;
  List<List<String>>? _lastDensityMatrixDisplay;

  @override
  void initState() {
    super.initState();
    // Initialize with 2 nodes each 2 qubits for demo
    network.addNode(NetworkNode(name: 'Node A', qubits: 2));
    network.addNode(NetworkNode(name: 'Node B', qubits: 2));
  }

  void _createBell() {
    // entangle first qubit of node A with first of node B
    network.createBellPair(0, 0, 1, 0);
    setState(() {});
  }

  void _applyGate(String gate, int node, int local) {
    network.applyGate(gate, node, local);
    setState(() {});
  }

  void _teleport() {
    try {
      final res = network.teleport(0, 1, 1, 1);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Teleport Result'),
          content: Text(res.toString()),
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Teleport Error'),
          content: Text(e.toString()),
        ),
      );
    }
  }

  void _addNodeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Node'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nodeNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Node X',
              ),
            ),
            TextField(
              controller: _nodeQubitsCtrl,
              decoration: const InputDecoration(labelText: 'Qubits'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text(
              'Total after add: ${network.totalQubits} + n  (limit warn > ${QuantumNetwork.complexityWarnThreshold})',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _nodeNameCtrl.text.trim().isEmpty
                  ? 'Node ${network.nodes.length}'
                  : _nodeNameCtrl.text.trim();
              final q = int.tryParse(_nodeQubitsCtrl.text.trim()) ?? 1;
              setState(() {
                network.addNode(NetworkNode(name: name, qubits: q));
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _swapEntanglement() {
    setState(() {
      network.entanglementSwap();
    });
  }

  void _deleteNode(int index) {
    setState(() {
      network.deleteNode(index);
      if (_densityNodeIndex >= network.nodes.length) _densityNodeIndex = 0;
    });
  }

  void _computeDensityMatrix() {
    if (network.nodes.isEmpty) return;
    final node = network.nodes[_densityNodeIndex];
    // Build global indices for node qubits
    final start = [
      for (int i = 0; i < _densityNodeIndex; i++) network.nodes[i].qubits,
    ].fold<int>(0, (a, b) => a + b);
    final subset = [for (int q = 0; q < node.qubits; q++) start + q];
    final rho = network.reducedDensityMatrix(subset);
    // Format to strings
    _lastDensityMatrixDisplay = rho
        .map(
          (row) => row.map((c) {
            final re = c.real.toStringAsFixed(3);
            final im = c.imaginary.toStringAsFixed(3);
            return im == '0.000'
                ? re
                : '$re${c.imaginary >= 0 ? '+' : ''}${im}i';
          }).toList(),
        )
        .toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dist = network.probabilityDistribution();
    final warn = network.complexityWarning();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Hero(
              tag: HeroTags.network,
              child: Icon(Icons.hub_rounded, size: 22),
            ),
            SizedBox(width: 8),
            Text('Quantum Network'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x33FF2D55), Colors.transparent],
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Small quantum network simulation: nodes own qubits; create Bell pairs between nodes to share entanglement.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _createBell,
                      child: const Text('Create Bell A0-B0'),
                    ),
                    ElevatedButton(
                      onPressed: _teleport,
                      child: const Text('Teleport (demo)'),
                    ),
                    ElevatedButton(
                      onPressed: _addNodeDialog,
                      child: const Text('Add Node'),
                    ),
                    ElevatedButton(
                      onPressed: _swapEntanglement,
                      child: const Text('Swap (multi-hop)'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total qubits: ${network.totalQubits}  | State size: 2^${network.totalQubits}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (warn != null)
                  Text(
                    warn,
                    style: const TextStyle(color: Colors.orangeAccent),
                  ),
                _noiseControls(),
                const SizedBox(height: 16),
                _nodesView(),
                const SizedBox(height: 16),
                _entanglementGraph(),
                const SizedBox(height: 16),
                _logView(),
                const SizedBox(height: 16),
                _densityMatrixSection(),
                const Divider(height: 32),
                const Text('Global probability distribution:'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView(
                    children: dist.entries
                        .take(64)
                        .map(
                          (e) =>
                              Text('${e.key} : ${e.value.toStringAsFixed(4)}'),
                        )
                        .toList(),
                  ),
                ),
                if (dist.length > 64) const Text('Truncated view (>64 states)'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nodesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nodes:'),
        const SizedBox(height: 8),
        ...List.generate(network.nodes.length, (i) {
          final node = network.nodes[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${node.name} (qubits: ${node.qubits})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        tooltip: 'Delete node',
                        onPressed: () => _deleteNode(i),
                        icon: const Icon(Icons.delete, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: List.generate(
                      node.qubits,
                      (q) => _qubitControls(i, q),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _noiseControls() {
    return ExpansionTile(
      title: const Text('Noise Model'),
      initiallyExpanded: false,
      children: [
        SwitchListTile(
          value: network.noise.enabled,
          title: const Text('Enable noise (bit/phase flip)'),
          onChanged: (v) {
            setState(() => network.noise.enabled = v);
          },
        ),
        if (network.noise.enabled)
          Column(
            children: [
              _probSlider('Bit-flip p', network.noise.pBitFlip, (v) {
                setState(() => network.noise.pBitFlip = v);
              }),
              _probSlider('Phase-flip p', network.noise.pPhaseFlip, (v) {
                setState(() => network.noise.pPhaseFlip = v);
              }),
            ],
          ),
      ],
    );
  }

  Widget _probSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text('$label: ${value.toStringAsFixed(3)}'),
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: 0.2,
            divisions: 200,
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _densityMatrixSection() {
    if (network.nodes.isEmpty) return const SizedBox();
    final nodeNames = [for (final n in network.nodes) n.name];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reduced Density Matrix (node)'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Node: '),
                DropdownButton<int>(
                  value: _densityNodeIndex,
                  items: List.generate(
                    nodeNames.length,
                    (i) =>
                        DropdownMenuItem(value: i, child: Text(nodeNames[i])),
                  ),
                  onChanged: (v) {
                    if (v != null) setState(() => _densityNodeIndex = v);
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _computeDensityMatrix,
                  child: const Text('Compute'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_lastDensityMatrixDisplay != null)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _lastDensityMatrixDisplay!
                      .map(
                        (row) => Text(
                          row.join('  '),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _entanglementGraph() {
    if (network.nodes.length < 2) return const SizedBox();
    final pairs = <Widget>[];
    for (int i = 0; i < network.nodes.length; i++) {
      for (int j = i + 1; j < network.nodes.length; j++) {
        final c = network.entanglementCountBetween(i, j);
        final color = c == 0
            ? Colors.grey.shade700
            : Colors.green.withOpacity((0.3 + c / 5).clamp(0.3, 1));
        pairs.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${network.nodes[i].name}—${network.nodes[j].name}: $c',
            ),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Entanglement Graph (Bell pair counts):'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: pairs),
        if (network.entangledPairs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Pairs: ${network.entangledPairs.map((e) => e.label).join(', ')}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
      ],
    );
  }

  Widget _logView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Log:'),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxHeight: 160),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade700),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView(
            children: network.log.reversed
                .take(50)
                .map((e) => Text(e, style: const TextStyle(fontSize: 12)))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _qubitControls(int nodeIndex, int localQubit) {
    final gates = ['H', 'X', 'Z'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('q$localQubit'),
        ...gates.map(
          (g) => SizedBox(
            width: 48,
            child: ElevatedButton(
              onPressed: () => _applyGate(g, nodeIndex, localQubit),
              child: Text(g),
            ),
          ),
        ),
      ],
    );
  }
}
