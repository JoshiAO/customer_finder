import 'package:flutter/foundation.dart';

class ProgressOperation {
  ProgressOperation({
    required this.id,
    required this.label,
    required this.type,
    this.progress = 0.0,
  });

  final int id;
  final String label;
  final String type;
  final double progress;

  ProgressOperation copyWith({
    String? label,
    String? type,
    double? progress,
  }) {
    return ProgressOperation(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      progress: progress ?? this.progress,
    );
  }
}

class ImportNotifier extends ChangeNotifier {
  final List<ProgressOperation> _operations = [];
  int _nextId = 1;

  List<ProgressOperation> get operations => List.unmodifiable(_operations);
  bool get isImporting => _operations.isNotEmpty;

  int start({required String label, required String type}) {
    final id = _nextId++;
    _operations.insert(0, ProgressOperation(id: id, label: label, type: type, progress: 0.0));
    notifyListeners();
    return id;
  }

  void update(int id, double value) {
    final idx = _operations.indexWhere((op) => op.id == id);
    if (idx < 0) return;
    _operations[idx] = _operations[idx].copyWith(progress: value.clamp(0.0, 1.0));
    notifyListeners();
  }

  void finish(int id) {
    final idx = _operations.indexWhere((op) => op.id == id);
    if (idx < 0) return;
    _operations[idx] = _operations[idx].copyWith(progress: 1.0);
    notifyListeners();

    // Small delay so progress bar reaches 100% visually before hiding
    Future.delayed(const Duration(milliseconds: 600), () {
      _operations.removeWhere((op) => op.id == id);
      notifyListeners();
    });
  }

  bool isTypeRunning(String type) {
    return _operations.any((op) => op.type == type);
  }
}
