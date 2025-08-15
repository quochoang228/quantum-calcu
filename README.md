# Quantum Calcu

Interactive quantum computing playground built with **Flutter** (multi‑platform: Android, iOS, Web, Desktop). It provides an intuitive way to build, run, and optimize small quantum circuits plus educational modules: teleportation, QFT, error correction, VQE, QML, entanglement metrics, QKD (BB84) and simple circuit synthesis.

> Goal: Make quantum concepts tangible, visually explorable, and extensible for teaching / lightweight experimentation.

---

## 🌟 Key Features

- Manual circuit builder (append gates then simulate state vector).
- Gate set: `H, X, Y, Z, RY(θ), PHASE(θ), CPHASE(θ), CNOT, SWAP (abstract), MEASURE (pseudo)`.
- Circuit optimization:
	- Inverse pair cancellation (H–H, X–X, Z–Z, PHASE θ + −θ, RY θ + −θ).
	- Sequential PHASE / RY merging (mod 2π).
	- Depth recomputation with per‑pass Δ gate / Δ depth metrics.
- Algorithm builders:
	- Quantum Teleportation (basic + measured/corrected variant).
	- Quantum Fourier Transform (standard controlled phases + final SWAPs).
- Quantum error correction:
	- 3‑qubit bit‑flip code (encode, inject, syndrome, correct).
	- Simplified 9‑qubit Shor code (encode, X/Z noise injection, heuristic syndrome, placeholder correction).
- Entanglement visualizer:
	- Interactive gate sandbox with ⟨Z⟩, ⟨ZᵢZⱼ⟩, single‑qubit purity approximation.
- Mini VQE:
	- 2‑qubit ansatz RY(θ1) – CNOT – RY(θ2).
	- Gradient via parameter‑shift rule or finite difference.
	- Animated gradient descent steps.
- QML mini demo:
	- Feature map RY(α x0) ⊗ RY(α x1) + CNOT.
	- Variational layer RY – RY – CNOT.
	- MSE loss, accuracy metric, mini‑batching, parameter persistence via SharedPreferences.
- Quantum RNG: measure |+> shots, frequency & entropy display.
- QKD (BB84) simulation: loss probability, eavesdrop probability, QBER & sifted key preview.
- Simple circuit synthesis: phase oracle gate list marking solution bitstrings.
- Analytical helpers: ⟨ZZ⟩ expectation, ⟨Z⟩, correlations, purity approximation.

---

## 🖼 Module Overview

| Module | Description |
|--------|-------------|
| Circuit Simulator | Build & run circuits, view probability distribution |
| Optimization | Sample run, per pass Δ gates & Δ depth summary |
| Error Correction | 3‑qubit bit‑flip + simplified Shor |
| Entanglement | Gate sandbox + expectation & correlation metrics |
| VQE / QML | Interactive parameter training, loss / gradient display |
| RNG | Quantum random bit generation + entropy chart |
| QKD | BB84 simulation, QBER & sifted key preview |
| Circuit Synthesis | Simple phase oracle gate list |

> Add screenshots inside `docs/` and embed them here if desired.

---

## 🛠 Core Architecture

### 1. State & Gates
- `QuantumState`: holds amplitude vector (Complex list), normalization & measurement.
- `CircuitGate`: gate descriptor (type, target, optional control, theta).
- Gate application = small matrix transforms over the state vector (no external simulator dependency).

### 2. Circuit & Optimization
- `QuantumCircuit`: gate list + `run()` to simulate.
- Current passes:
	- Inverse Cancellation
	- Phase / RY Merge
	- (Planned) Commutation reorder, Template fusion, CNOT chain reduction.
- `depth()` builds greedy parallel layers to estimate circuit depth.

### 3. Algorithms / Utils (`quantum_utils.dart`)
- Bit‑flip code, simplified Shor, VQE ansatz + parameter‑shift gradient.
- Metrics: expectationZ, correlationZZ, single‑qubit purity approximation.
- BB84: random bits, bases, Bob results, sifted key, QBER.
- Circuit synthesis: naive phase oracle marking solutions.

---

## 🚀 Setup & Run

Requirements: [Flutter](https://flutter.dev) (stable channel), bundled Dart SDK.

### Step 1: Clone
```bash
git clone <repo-url>
cd quantum_calcu
```
### Step 2: Dependencies
```bash
flutter pub get
```
### Step 3: Run (Windows / Web examples)
```bash
flutter run -d windows
# or
flutter run -d chrome
```
### Build APK (release)
```bash
flutter build apk --release
```
> If no devices appear, run `flutter devices`.

---

## 📂 Condensed Directory Structure
	screens/                 // UI (simulator, advanced, ...)
	ui/                      // Style, widgets
    lib/
	main.dart                // App entry
	core/                    // Simulation & utilities
		quantum_state.dart
		quantum_gates.dart
		circuit_model.dart
		quantum_utils.dart
	screens/                 // UI screens (simulator, advanced, ...)
	ui/                      // Styles / reusable widgets
    docs/                      // Docs
    test/                      //
```

---

## 🧪 Testing & Correctness
Currently minimal tests. Suggested additions:
1. Compare known circuits (Bell state, small QFT) against hand‑computed amplitudes.
2. Verify optimization preserves output distribution (fidelity ≈ 1).
3. Cross‑check VQE gradients: parameter‑shift vs finite difference.

---

## 🗺 Roadmap (Proposed)

- [ ] Exact purity (partial trace) instead of approximation.
- [ ] QSVM (kernel) & deeper QNN layers.
- [ ] Additional optimization passes (commutation reorder, pattern fusion).
- [ ] Export circuits (JSON / simple QASM subset).
- [ ] Visual gate timeline + parallel layer highlighting.
- [ ] CI test suite.
- [ ] Multi‑language toggle (en/vi).

Contributions & feature ideas welcome.

---

## 🤝 Contributing
1. Fork & create a feature branch: `feature/short-description`.
2. Clear commits: *Add: CNOT chain optimization pass*.
3. Open a PR with description & optional screenshots.

---

## ⚖️ License
Add a `LICENSE` file (e.g. MIT) if distributing. Currently treated as educational sample.

---

## ❓ FAQ
**Why not use an external simulator library?** – To keep code minimal & educational.

**General noise channels supported?** – Not yet; only simple bit/phase style errors in bit‑flip & simplified Shor demos.

**Can I scale to more qubits?** – State vector cost grows 2^n; intended practical demo range ≤ 10 qubits.

---

## 📬 Contact
Open an Issue / PR for feature requests, bugs, or questions.

Happy exploring with Quantum Calcu!
