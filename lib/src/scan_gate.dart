/// Guards a scan callback so that it runs at most once per scan.
class ScanGate {
  bool _handled = false;

  /// Returns `true` for the first call and `false` for every later call
  /// until [reset] is called.
  bool tryHandle() {
    if (_handled) return false;
    _handled = true;
    return true;
  }

  /// Allows the gate to accept a new scan.
  void reset() {
    _handled = false;
  }
}
