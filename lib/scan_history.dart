class ScanHistory {
  static final List<Map<String, dynamic>> _history = [];

  static void addHistory(Map<String, dynamic> record) {
    _history.add(record);
  }

  static List<Map<String, dynamic>> getHistory() {
    return _history;
  }
}
