/// Suppresses repeated scans of the same code for a short window.
///
/// Cameras report the same barcode on many consecutive frames. In continuous
/// mode the scanner reports each code once per window, so one barcode held in
/// front of the camera does not flood the callback.
class ScanDeduper {
  /// Creates a deduper with the minimum time between two reports of one code.
  ///
  /// [clock] replaces the current time source, which keeps tests instant.
  ScanDeduper({
    this.window = const Duration(seconds: 2),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Minimum time between two reports of the same code.
  final Duration window;

  final DateTime Function() _clock;
  final Map<String, DateTime> _lastSeen = <String, DateTime>{};

  /// Returns `true` when [value] was reported less than [window] ago.
  ///
  /// A new value is recorded, so the next call with the same value inside the
  /// window returns `true`.
  bool isDuplicate(String value) {
    final DateTime now = _clock();
    final DateTime? last = _lastSeen[value];
    if (last != null && now.difference(last) < window) {
      return true;
    }
    _lastSeen[value] = now;
    return false;
  }

  /// Forgets every recorded code.
  void reset() {
    _lastSeen.clear();
  }
}
