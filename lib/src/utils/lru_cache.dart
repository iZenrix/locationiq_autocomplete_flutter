class LruCache<K, V> {
  LruCache({required this.capacity}) : assert(capacity > 0);

  final int capacity;
  final _map = <K, V>{};

  V? get(K key) {
    final v = _map.remove(key);
    if (v == null) return null;
    _map[key] = v;
    return v;
  }

  void set(K key, V value) {
    if (_map.containsKey(key)) {
      _map.remove(key);
    } else if (_map.length >= capacity) {
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }

  void clear() => _map.clear();

  int get length => _map.length;
}
