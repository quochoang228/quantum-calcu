import 'package:flutter/material.dart';
import '../core/quantum_state.dart';
import '../core/circuit_model.dart';
import 'package:complex/complex.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../ui/style.dart';
import '../widgets/illustrations.dart';

class CircuitSimulatorScreen extends StatefulWidget {
  const CircuitSimulatorScreen({super.key});

  @override
  State<CircuitSimulatorScreen> createState() => _CircuitSimulatorScreenState();
}

class _CircuitSimulatorScreenState extends State<CircuitSimulatorScreen> {
  QuantumCircuit circuit = QuantumCircuit(qubits: 2);
  QuantumState? lastRun;
  String? jsonExport;
  double phaseTheta = 0.0;
  CircuitGate? draggingGate; // temp gate while dragging
  bool dragActive = false;
  final Map<String, List<List<Complex>>> customGateLibrary = {};
  // Selected qubits for partial measurement (marginal distribution)
  final Set<int> selectedQubits = {};
  Map<String, double>? partialDistribution;
  // Multi-circuit persistence
  Map<String, String> savedCircuits = {}; // name -> json
  String? currentCircuitName;
  // Unified history timeline (snapshots after each change)
  final List<String> _history = [];
  int _historyIndex = -1; // points to current snapshot in _history

  @override
  void initState() {
    super.initState();
    _loadSavedCircuits();
    // initial snapshot
    _pushHistory();
  }

  void _runCircuit() {
    lastRun = circuit.run();
    partialDistribution = null;
    if (selectedQubits.isNotEmpty && lastRun != null) {
      final indices = selectedQubits.toList()..sort();
      final dist = lastRun!.probabilityDistribution();
      final reduced = <String, double>{};
      dist.forEach((bits, p) {
        final proj = indices
            .map((i) => bits.padLeft(circuit.qubits, '0')[i])
            .join();
        reduced[proj] = (reduced[proj] ?? 0) + p;
      });
      partialDistribution = reduced;
    }
    setState(() {});
  }

  void _exportJson() {
    jsonExport = circuit.toJsonString();
    setState(() {});
  }

  void _importJson(String s) {
    try {
      circuit = QuantumCircuit.fromJsonString(s);
      lastRun = null;
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import error: $e')));
    }
  }

  Future<void> _loadSavedCircuits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('saved_circuits');
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      savedCircuits = decoded.map((k, v) => MapEntry(k, v as String));
      setState(() {});
    }
  }

  Future<void> _persistSavedCircuits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_circuits', jsonEncode(savedCircuits));
  }

  Future<void> _saveCircuitAs() async {
    final controller = TextEditingController(
      text: currentCircuitName ?? 'circuit_${savedCircuits.length + 1}',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save Circuit As'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      savedCircuits[name] = circuit.toJsonString();
      currentCircuitName = name;
      await _persistSavedCircuits();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved "$name"')));
      }
      setState(() {});
    }
  }

  void _loadCircuitByName(String name) {
    final json = savedCircuits[name];
    if (json != null) {
      circuit = QuantumCircuit.fromJsonString(json);
      currentCircuitName = name;
      lastRun = null;
      partialDistribution = null;
      setState(() {});
    }
  }

  Future<void> _deleteCircuit(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      savedCircuits.remove(name);
      if (currentCircuitName == name) currentCircuitName = null;
      await _persistSavedCircuits();
      setState(() {});
    }
  }

  void _addGate(CircuitGate g) {
    circuit.add(g);
    _afterStructuralChange();
  }

  void _removeAt(int idx) {
    circuit.gates.removeAt(idx);
    _afterStructuralChange();
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final g = circuit.gates.removeAt(oldIndex);
    circuit.gates.insert(newIndex, g);
    _afterStructuralChange(pushEvenIfSame: true);
  }

  void _changeQubitCount(int newCount) {
    circuit = QuantumCircuit(qubits: newCount, gates: []);
    lastRun = null;
    partialDistribution = null;
    _afterStructuralChange();
  }

  void _resetCircuit() {
    circuit.clear();
    lastRun = null;
    partialDistribution = null;
    _afterStructuralChange();
  }

  void _afterStructuralChange({bool pushEvenIfSame = false}) {
    final currentJson = circuit.toJsonString();
    if (!pushEvenIfSame &&
        _historyIndex >= 0 &&
        _history[_historyIndex] == currentJson) {
      setState(() {}); // nothing changed
      return;
    }
    _pushHistory();
    setState(() {});
  }

  void _pushHistory() {
    final snap = circuit.toJsonString();
    // Discard forward history if we branched
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(snap);
    if (_history.length > 101) {
      _history.removeAt(0);
      _historyIndex = _history.length - 1;
    } else {
      _historyIndex = _history.length - 1;
    }
  }

  void _undo() {
    if (_historyIndex <= 0) return;
    _historyIndex--;
    _loadSnapshot(_history[_historyIndex]);
  }

  void _redo() {
    if (_historyIndex >= _history.length - 1) return;
    _historyIndex++;
    _loadSnapshot(_history[_historyIndex]);
  }

  void _jumpTo(int index) {
    if (index < 0 || index >= _history.length) return;
    _historyIndex = index;
    _loadSnapshot(_history[_historyIndex]);
  }

  void _loadSnapshot(String json) {
    circuit = QuantumCircuit.fromJsonString(json);
    lastRun = null;
    partialDistribution = null;
    setState(() {});
  }

  int get _undoCount => _historyIndex.clamp(0, _historyIndex);
  int get _redoCount => (_history.length - _historyIndex - 1).clamp(0, 1 << 30);

  Future<void> _openHistoryTimeline() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Column(
          children: [
            ListTile(
              title: const Text('History Timeline'),
              subtitle: Text(
                'Snapshots: ${_history.length}  Current: ${_historyIndex + 1}/${_history.length}',
              ),
              trailing: IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (c, i) {
                  final parsed = _snapshotSummary(_history[i]);
                  final isCurrent = i == _historyIndex;
                  return ListTile(
                    dense: true,
                    selected: isCurrent,
                    leading: Text('#${i + 1}'),
                    title: Text(parsed),
                    trailing: isCurrent
                        ? const Icon(Icons.radio_button_checked)
                        : null,
                    onTap: () {
                      _jumpTo(i);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _snapshotSummary(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final q = map['qubits'];
      final gates = (map['gates'] as List).length;
      return 'Qubits: $q | Gates: $gates';
    } catch (_) {
      return 'Invalid snapshot';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Hero(
              tag: HeroTags.circuit,
              child: Icon(Icons.memory_rounded, size: 22),
            ),
            SizedBox(width: 8),
            Text('Circuit Simulator'),
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            children: [
              SectionCard(
                title: 'Configuration',
                illustration: const GateIllustration(
                  gates: ['Qubits', '→', 'Circuit'],
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    const Text('Qubits:'),
                    DropdownButton<int>(
                      value: circuit.qubits,
                      items: [1, 2, 3, 4]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _changeQubitCount(v);
                      },
                    ),
                    ElevatedButton(
                      onPressed: _runCircuit,
                      child: const Text('Run'),
                    ),
                    ElevatedButton(
                      onPressed: _resetCircuit,
                      child: const Text('Reset'),
                    ),
                    ElevatedButton(
                      onPressed: _optimizeCircuit,
                      child: const Text('Optimize'),
                    ),
                    _historyButtons(),
                    IconButton(
                      tooltip: 'Export JSON',
                      onPressed: _exportJson,
                      icon: const Icon(Icons.save),
                    ),
                    IconButton(
                      tooltip: 'Import JSON',
                      onPressed: _showImportDialog,
                      icon: const Icon(Icons.upload),
                    ),
                    IconButton(
                      tooltip: 'Save As',
                      onPressed: _saveCircuitAs,
                      icon: const Icon(Icons.save_as),
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: 'Circuit Builders',
                illustration: const GateIllustration(gates: ['Templates']),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _buildTeleportation(),
                      child: const Text('Teleportation'),
                    ),
                    ElevatedButton(
                      onPressed: () => _buildTeleportationAdvanced(),
                      child: const Text('Teleport+Corr'),
                    ),
                    ElevatedButton(
                      onPressed: () => _buildQft(),
                      child: const Text('QFT'),
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: 'Measure Subset',
                illustration: const ProbabilityBarIllustration(
                  sample: {'00': 0.5, '11': 0.5},
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    const Text('Select:'),
                    for (var i = 0; i < circuit.qubits; i++)
                      FilterChip(
                        label: Text('q$i'),
                        selected: selectedQubits.contains(i),
                        onSelected: (sel) => setState(
                          () => sel
                              ? selectedQubits.add(i)
                              : selectedQubits.remove(i),
                        ),
                      ),
                    if (selectedQubits.isNotEmpty)
                      Text(
                        '→ {${(selectedQubits.toList()..sort()).join(',')}}',
                      ),
                    if (selectedQubits.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedQubits.clear();
                            partialDistribution = null;
                          });
                        },
                        child: const Text('Clear'),
                      ),
                  ],
                ),
              ),
              SectionCard(
                title: 'Saved Circuits',
                child: Row(
                  children: [
                    Expanded(
                      child: savedCircuits.isEmpty
                          ? const Text('No saved circuits')
                          : DropdownButton<String>(
                              value: currentCircuitName,
                              hint: const Text('Load circuit'),
                              isExpanded: true,
                              items: savedCircuits.keys
                                  .map(
                                    (k) => DropdownMenuItem(
                                      value: k,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              k,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 16,
                                            ),
                                            onPressed: () => _deleteCircuit(k),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) _loadCircuitByName(v);
                              },
                            ),
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: 'Add Gates',
                illustration: const GateIllustration(
                  gates: ['H', 'X', 'Y', 'Z', 'CNOT'],
                ),
                child: SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final name in ['H', 'X', 'Y', 'Z'])
                        _gateDraggable(name),
                      _ryGatePicker(),
                      _phaseGatePicker(),
                      _cphaseBuilder(),
                      _cnotBuilder(),
                      _swapBuilder(),
                      _customGateBuilder(),
                      if (customGateLibrary.isNotEmpty)
                        const VerticalDivider(width: 20, thickness: 1),
                      for (final entry in customGateLibrary.entries)
                        _customLibraryDraggable(entry.key, entry.value),
                    ],
                  ),
                ),
              ),
              SectionCard(
                title: 'Sequence',
                illustration: const GateIllustration(
                  gates: ['Build', '→', 'Run'],
                ),
                actions: [
                  IconButton(
                    onPressed: _history.length <= 1
                        ? null
                        : _openHistoryTimeline,
                    icon: const Icon(Icons.timeline),
                  ),
                ],
                child: SizedBox(
                  height: 260,
                  child: DragTarget<CircuitGate>(
                    onWillAccept: (g) {
                      setState(() => dragActive = true);
                      return true;
                    },
                    onLeave: (_) {
                      setState(() => dragActive = false);
                    },
                    onAccept: (g) {
                      setState(() => dragActive = false);
                      if (g.type != 'CNOT' &&
                          g.type != 'CUSTOM' &&
                          g.type != 'PHASE') {
                        _pickTarget().then((t) {
                          if (t != null)
                            _addGate(CircuitGate(type: g.type, target: t));
                        });
                      } else {
                        _addGate(g);
                      }
                    },
                    builder: (c, _, __) => Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: dragActive
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ReorderableListView(
                        onReorder: _reorder,
                        children: [
                          for (var i = 0; i < circuit.gates.length; i++)
                            ListTile(
                              key: ValueKey('g$i'),
                              title: Text(_gateLabel(circuit.gates[i])),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeAt(i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: lastRun == null
                    ? const SizedBox(key: ValueKey('empty'))
                    : Column(
                        key: const ValueKey('dist'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionCard(
                            title: 'Probability Distribution',
                            illustration: ProbabilityBarIllustration(
                              sample: lastRun!.probabilityDistribution().map(
                                (k, v) => MapEntry(k, v),
                              ),
                            ),
                            child: Wrap(
                              spacing: 8,
                              children: (lastRun!.probabilityDistribution())
                                  .entries
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
                          if (partialDistribution != null)
                            SectionCard(
                              title:
                                  'Partial (qubits ${(selectedQubits.toList()..sort()).join(',')})',
                              child: Wrap(
                                spacing: 8,
                                children: partialDistribution!.entries
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
                        ],
                      ),
              ),
              if (jsonExport != null)
                SectionCard(
                  title: 'Exported JSON',
                  child: SelectableText(jsonExport!, maxLines: 4),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyButtons() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Column(
        children: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _undoCount == 0 ? null : _undo,
            icon: const Icon(Icons.undo),
          ),
          Text(_undoCount.toString(), style: const TextStyle(fontSize: 10)),
        ],
      ),
      const SizedBox(width: 4),
      Column(
        children: [
          IconButton(
            tooltip: 'Redo',
            onPressed: _redoCount == 0 ? null : _redo,
            icon: const Icon(Icons.redo),
          ),
          Text(_redoCount.toString(), style: const TextStyle(fontSize: 10)),
        ],
      ),
    ],
  );

  void _showImportDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Circuit JSON'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(hintText: 'Paste JSON'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _importJson(controller.text);
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }

  void _buildTeleportation() {
    if (circuit.qubits < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teleportation requires at least 3 qubits.'),
        ),
      );
      return;
    }
    circuit.clear();
    for (final g in [
      CircuitGate(type: 'H', target: 1),
      CircuitGate(type: 'CNOT', control: 1, target: 0),
      CircuitGate(type: 'CNOT', control: 1, target: 2),
      CircuitGate(type: 'H', target: 2),
      CircuitGate(type: 'CNOT', control: 0, target: 2),
      CircuitGate(type: 'H', target: 0),
    ]) {
      circuit.add(g);
    }
    _afterStructuralChange();
  }

  void _buildQft() {
    circuit.clear();
    final n = circuit.qubits;
    for (var j = 0; j < n; j++) {
      circuit.add(CircuitGate(type: 'H', target: j));
      // controlled phase rotations with decreasing angles (simulate via PHASE + CNOT sandwich since no native controlled-phase gate button yet)
      for (var k = 1; k + j < n; k++) {
        final control = j + k;
        final angle = pi / (1 << k); // π / 2^{k}
        // Use custom gate type CPHASE that runtime supports
        circuit.add(
          CircuitGate(
            type: 'CPHASE',
            control: control,
            target: j,
            theta: angle,
          ),
        );
      }
    }
    // final swaps to reverse order
    for (var i = 0; i < n ~/ 2; i++) {
      final a = i;
      final b = n - i - 1;
      circuit.add(CircuitGate(type: 'SWAP', target: a, control: b));
    }
    _afterStructuralChange();
  }

  void _buildTeleportationAdvanced() {
    if (circuit.qubits < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need ≥3 qubits for teleportation.')),
      );
      return;
    }
    circuit.clear();
    final angle = Random().nextDouble() * 2 * pi; // random state
    circuit.add(CircuitGate(type: 'RY', target: 0, theta: angle));
    circuit.add(CircuitGate(type: 'H', target: 1));
    circuit.add(CircuitGate(type: 'CNOT', control: 1, target: 2));
    circuit.add(CircuitGate(type: 'CNOT', control: 0, target: 1));
    circuit.add(CircuitGate(type: 'H', target: 0));
    final copy = QuantumCircuit(
      qubits: circuit.qubits,
      gates: [for (final g in circuit.gates) g.copy()],
    );
    final st = copy.run();
    final m0 = st.measureSingle(0);
    final m1 = st.measureSingle(1);
    // Insert pseudo measurement gates to show classical outcomes
    circuit.add(CircuitGate(type: 'MEASURE', target: 0, measResult: m0));
    circuit.add(CircuitGate(type: 'MEASURE', target: 1, measResult: m1));
    if (m1 == 1) circuit.add(CircuitGate(type: 'X', target: 2));
    if (m0 == 1) circuit.add(CircuitGate(type: 'Z', target: 2));
    _afterStructuralChange();
    final corr = [if (m1 == 1) 'X', if (m0 == 1) 'Z'].join();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Teleportation complete: m0=$m0 m1=$m1 ${corr.isEmpty ? '(no correction)' : 'applied $corr on q2'}',
        ),
      ),
    );
  }

  void _optimizeCircuit() {
    final beforeJson = circuit.toJsonString();
    final depthBefore = circuit.depth();
    final (before, after) = circuit.optimize();
    final depthAfter = circuit.depth();
    _pushHistory();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Optimized: gates $before→$after (Δ${before - after}, ${(before == 0 ? 0 : ((before - after) / before) * 100).toStringAsFixed(1)}%), depth $depthBefore→$depthAfter (Δ${depthAfter - depthBefore})',
        ),
        action: SnackBarAction(
          label: 'Details',
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Optimization Result'),
                content: SelectableText(
                  'Before (depth $depthBefore):\n$beforeJson\n\nAfter (depth $depthAfter):\n${circuit.toJsonString()}',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

extension on _CircuitSimulatorScreenState {
  Widget _gateDraggable(String name) => Draggable<CircuitGate>(
    data: CircuitGate(type: name, target: 0), // target decided later via dialog
    feedback: _gateChip(name),
    child: GestureDetector(
      onTap: () async {
        final target = await _pickTarget();
        if (target != null) _addGate(CircuitGate(type: name, target: target));
      },
      child: _gateChip(name),
    ),
  );

  Widget _gateChip(String label) => Padding(
    padding: const EdgeInsets.all(4.0),
    child: Chip(label: Text(label)),
  );

  Future<int?> _pickTarget() async {
    int sel = 0;
    return showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Target Qubit'),
        content: StatefulBuilder(
          builder: (c, setSt) {
            return DropdownButton<int>(
              value: sel,
              items: List.generate(
                circuit.qubits,
                (i) => DropdownMenuItem(value: i, child: Text('q$i')),
              ),
              onChanged: (v) => setSt(() => sel = v!),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, sel),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _phaseGatePicker() => GestureDetector(
    onTap: () async {
      final target = await _pickTarget();
      if (target == null) return;
      double theta = phaseTheta;
      final res = await showDialog<double>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Phase θ (radians)'),
          content: StatefulBuilder(
            builder: (c, setSt) {
              return Slider(
                value: theta,
                min: 0,
                max: 3.14159,
                onChanged: (v) => setSt(() => theta = v),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, theta),
              child: const Text('Add'),
            ),
          ],
        ),
      );
      if (res != null) {
        phaseTheta = res;
        _addGate(CircuitGate(type: 'PHASE', target: target, theta: res));
      }
    },
    child: _gateChip('PHASE'),
  );

  Widget _cnotBuilder() => GestureDetector(
    onTap: () async {
      final control = await _pickTarget();
      if (control == null) return;
      int target = (control + 1) % circuit.qubits;
      final res = await showDialog<int>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Select Target'),
          content: StatefulBuilder(
            builder: (c, setSt) {
              return DropdownButton<int>(
                value: target,
                items: List.generate(
                  circuit.qubits,
                  (i) => DropdownMenuItem(value: i, child: Text('q$i')),
                ),
                onChanged: (v) => setSt(() => target = v!),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, target),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (res != null) {
        _addGate(CircuitGate(type: 'CNOT', control: control, target: res));
      }
    },
    child: _gateChip('CNOT'),
  );

  Widget _customGateBuilder() => GestureDetector(
    onTap: () async {
      // Enter 4 complex numbers (a,b,c,d) for matrix [[a,b],[c,d]] in a+bi form
      final ctrls = List.generate(4, (_) => TextEditingController());
      final nameController = TextEditingController();
      final target = await _pickTarget();
      if (target == null) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Custom 2x2 (a+bi values)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Gate Name'),
              ),
              Wrap(
                spacing: 8,
                children: List.generate(
                  4,
                  (i) => SizedBox(
                    width: 80,
                    child: TextField(
                      controller: ctrls[i],
                      decoration: InputDecoration(hintText: 'm$i (a+bi)'),
                      keyboardType: TextInputType.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      );
      if (ok == true) {
        final parsed = ctrls.map((c) => _parseComplex(c.text)).toList();
        final matrix = [
          [parsed[0], parsed[1]],
          [parsed[2], parsed[3]],
        ];
        final isUnitary = _isUnitaryComplex(matrix);
        if (!isUnitary) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Matrix not unitary – normalized.')),
          );
          _normalizeColumnsComplex(matrix);
        }
        final gName = nameController.text.trim().isEmpty
            ? 'CUSTOM'
            : nameController.text.trim();
        customGateLibrary[gName] = matrix;
        _addGate(CircuitGate(type: 'CUSTOM', target: target, custom: matrix));
      }
    },
    child: _gateChip('CUSTOM'),
  );

  String _gateLabel(CircuitGate g) {
    switch (g.type) {
      case 'CNOT':
        return 'CNOT c:q${g.control}→t:q${g.target}';
      case 'PHASE':
        return 'PHASE θ=${g.theta!.toStringAsFixed(2)} q${g.target}';
      case 'RY':
        return 'RY θ=${g.theta!.toStringAsFixed(2)} q${g.target}';
      case 'CPHASE':
        return 'CPHASE θ=${g.theta!.toStringAsFixed(2)} c:q${g.control}→t:q${g.target}';
      case 'SWAP':
        return 'SWAP q${g.target}↔q${g.control}';
      case 'MEASURE':
        return 'MEASURE q${g.target} = ${g.measResult}';
      case 'CUSTOM':
        final name = customGateLibrary.entries
            .firstWhere(
              (e) => e.value == g.custom,
              orElse: () => MapEntry('CUSTOM', g.custom!),
            )
            .key;
        return '$name q${g.target}';
      default:
        return '${g.type} q${g.target}';
    }
  }

  // Parse complex number in forms: a, a+bi, a-bi, bi, i, -i
  Complex _parseComplex(String s) {
    var txt = s.trim();
    if (txt.isEmpty) return Complex.zero;
    if (txt == 'i') return const Complex(0, 1);
    if (txt == '-i') return const Complex(0, -1);
    // If contains 'i'
    if (txt.contains('i')) {
      txt = txt.replaceAll(' ', '').replaceAll('−', '-');
      final pattern = RegExp(r'^([+-]?\d*\.?\d+)?([+-]\d*\.?\d+)?i$');
      final m = pattern.firstMatch(txt);
      if (m != null) {
        final reStr = m.group(1);
        final imStr = m.group(2);
        final re = reStr == null || reStr.isEmpty ? 0.0 : double.parse(reStr);
        final im = imStr == null || imStr.isEmpty ? 1.0 : double.parse(imStr);
        return Complex(re, im);
      }
      // Pure imaginary like 0.5i or -2i
      final pureIm = RegExp(r'^([+-]?\d*\.?\d+)i$');
      final pm = pureIm.firstMatch(txt);
      if (pm != null) {
        return Complex(0, double.parse(pm.group(1)!));
      }
    }
    final re = double.tryParse(txt);
    if (re != null) return Complex(re, 0);
    return Complex.zero;
  }

  bool _isUnitaryComplex(List<List<Complex>> m) {
    final a = m[0][0];
    final b = m[0][1];
    final c = m[1][0];
    final d = m[1][1];
    final col1Norm = a.abs() * a.abs() + c.abs() * c.abs();
    final col2Norm = b.abs() * b.abs() + d.abs() * d.abs();
    final dot = a.conjugate() * b + c.conjugate() * d;
    return (col1Norm - 1).abs() < 1e-6 &&
        (col2Norm - 1).abs() < 1e-6 &&
        dot.abs() < 1e-6;
  }

  void _normalizeColumnsComplex(List<List<Complex>> m) {
    double norm(List<Complex> col) =>
        sqrt(col.fold(0.0, (s, v) => s + v.abs() * v.abs()));
    // First column
    var c1 = [m[0][0], m[1][0]];
    final n1 = norm(c1);
    if (n1 != 0) {
      m[0][0] = m[0][0] / Complex(n1, 0);
      m[1][0] = m[1][0] / Complex(n1, 0);
    }
    // Orthogonalize second
    var c2 = [m[0][1], m[1][1]];
    final projCoeff =
        (m[0][0].conjugate() * c2[0] + m[1][0].conjugate() * c2[1]);
    c2[0] = c2[0] - m[0][0] * projCoeff;
    c2[1] = c2[1] - m[1][0] * projCoeff;
    final n2 = norm(c2);
    if (n2 != 0) {
      m[0][1] = c2[0] / Complex(n2, 0);
      m[1][1] = c2[1] / Complex(n2, 0);
    } else {
      m[0][1] = Complex.zero;
      m[1][1] = Complex.one;
    }
  }

  Widget _customLibraryDraggable(String name, List<List<Complex>> matrix) =>
      Draggable<CircuitGate>(
        data: CircuitGate(type: 'CUSTOM', target: 0, custom: matrix),
        feedback: _gateChip(name),
        child: GestureDetector(
          onTap: () async {
            final target = await _pickTarget();
            if (target != null) {
              _addGate(
                CircuitGate(type: 'CUSTOM', target: target, custom: matrix),
              );
            }
          },
          child: _gateChip(name),
        ),
      );

  Widget _ryGatePicker() => GestureDetector(
    onTap: () async {
      final target = await _pickTarget();
      if (target == null) return;
      double theta = pi / 4;
      final res = await showDialog<double>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('RY θ (radians)'),
          content: StatefulBuilder(
            builder: (c, setSt) => Slider(
              value: theta,
              min: -pi,
              max: pi,
              onChanged: (v) => setSt(() => theta = v),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, theta),
              child: const Text('Add'),
            ),
          ],
        ),
      );
      if (res != null) {
        _addGate(CircuitGate(type: 'RY', target: target, theta: res));
      }
    },
    child: _gateChip('RY'),
  );

  Widget _cphaseBuilder() => GestureDetector(
    onTap: () async {
      final control = await _pickTarget();
      if (control == null) return;
      int target = (control + 1) % circuit.qubits;
      double theta = pi / 4;
      final res = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('CPHASE control/target/θ'),
          content: StatefulBuilder(
            builder: (c, setSt) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: target,
                  items: List.generate(
                    circuit.qubits,
                    (i) => DropdownMenuItem(value: i, child: Text('q$i')),
                  ),
                  onChanged: (v) => setSt(() => target = v!),
                ),
                Slider(
                  value: theta,
                  min: -pi,
                  max: pi,
                  onChanged: (v) => setSt(() => theta = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, {'theta': theta, 'target': target}),
              child: const Text('Add'),
            ),
          ],
        ),
      );
      if (res != null) {
        _addGate(
          CircuitGate(
            type: 'CPHASE',
            control: control,
            target: res['target'] as int,
            theta: res['theta'] as double,
          ),
        );
      }
    },
    child: _gateChip('CPHASE'),
  );

  Widget _swapBuilder() => GestureDetector(
    onTap: () async {
      final a = await _pickTarget();
      if (a == null) return;
      int b = (a + 1) % circuit.qubits;
      final res = await showDialog<int>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('SWAP second qubit'),
          content: StatefulBuilder(
            builder: (c, setSt) => DropdownButton<int>(
              value: b,
              items: List.generate(
                circuit.qubits,
                (i) => DropdownMenuItem(value: i, child: Text('q$i')),
              ).toList(),
              onChanged: (v) => setSt(() => b = v!),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, b),
              child: const Text('Add'),
            ),
          ],
        ),
      );
      if (res != null) {
        _addGate(CircuitGate(type: 'SWAP', target: a, control: res));
      }
    },
    child: _gateChip('SWAP'),
  );
}
