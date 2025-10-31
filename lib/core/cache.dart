class Cache {
  static Cache? _instance;
  static Cache get instance => _instance ??= Cache._();

  Cache._();

  final Map<String, dynamic> _store = {};
  final Map<String, DateTime> _expiry = {};

  void set(String key, dynamic value) {
    _store[key] = value;
  }

  dynamic get(String key) {
    if (_expiry.containsKey(key)) {
      if (DateTime.now().isAfter(_expiry[key]!)) {
        delete(key);
        return null;
      }
    }
    return _store[key];
  }

  bool has(String key) {
    if (_expiry.containsKey(key)) {
      if (DateTime.now().isAfter(_expiry[key]!)) {
        delete(key);
        return false;
      }
    }
    return _store.containsKey(key);
  }

  void delete(String key) {
    _store.remove(key);
    _expiry.remove(key);
  }

  void clear() {
    _store.clear();
    _expiry.clear();
  }

  List<String> keys() {
    return _store.keys.toList();
  }

  int get length => _store.length;

  void setWithExpiry(String key, dynamic value, Duration duration) {
    _store[key] = value;
    _expiry[key] = DateTime.now().add(duration);
  }
}
