import 'dart:async';

import 'package:flutter/material.dart';

import '../api/exceptions.dart';
import '../api/locationiq_autocomplete_api.dart';
import '../api/models.dart';
import '../utils/debouncer.dart';
import '../utils/lru_cache.dart';

enum LocationIQAutocompleteStatus {
  idle,
  loading,
  success,
  empty,
  error,
  rateLimited,
}

class LocationIQAutocompleteSnapshot {
  const LocationIQAutocompleteSnapshot({
    required this.status,
    required this.query,
    required this.items,
    required this.updatedAt,
    this.error,
    this.cooldownUntil,
  });

  final LocationIQAutocompleteStatus status;
  final String query;
  final List<LocationIQAutocompleteResult> items;
  final DateTime updatedAt;

  final Object? error;
  final DateTime? cooldownUntil;

  bool get isCoolingDown => cooldownUntil != null && DateTime.now().isBefore(cooldownUntil!);

  LocationIQAutocompleteSnapshot copyWith({
    LocationIQAutocompleteStatus? status,
    String? query,
    List<LocationIQAutocompleteResult>? items,
    DateTime? updatedAt,
    Object? error,
    DateTime? cooldownUntil,
  }) {
    return LocationIQAutocompleteSnapshot(
      status: status ?? this.status,
      query: query ?? this.query,
      items: items ?? this.items,
      updatedAt: updatedAt ?? this.updatedAt,
      error: error ?? this.error,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
    );
  }

  static LocationIQAutocompleteSnapshot idle() => LocationIQAutocompleteSnapshot(
    status: LocationIQAutocompleteStatus.idle,
    query: '',
    items: const [],
    updatedAt: DateTime.now(),
  );
}

class LocationIQAutocompleteController {
  LocationIQAutocompleteController({
    required this.api,
    this.request = const LocationIQAutocompleteRequest(),
    this.minChars = 3,
    Duration debounce = const Duration(milliseconds: 500),
    int cacheSize = 50,
    this.rateLimitCooldown = const Duration(seconds: 3),
  })  : assert(minChars >= 1),
        _debouncer = Debouncer(debounce),
        _cache = LruCache<String, List<LocationIQAutocompleteResult>>(capacity: cacheSize),
        snapshot = ValueNotifier<LocationIQAutocompleteSnapshot>(LocationIQAutocompleteSnapshot.idle());

  final LocationIQAutocompleteApi api;
  LocationIQAutocompleteRequest request;

  final int minChars;
  final Duration rateLimitCooldown;

  final Debouncer _debouncer;
  final LruCache<String, List<LocationIQAutocompleteResult>> _cache;

  final ValueNotifier<LocationIQAutocompleteSnapshot> snapshot;

  int _seq = 0;
  DateTime? _cooldownUntil;

  String _normalizeKey(String query) => query.trim().toLowerCase();

  void dispose() {
    _debouncer.dispose();
    snapshot.dispose();
  }

  void clearCache() => _cache.clear();

  void clear() {
    _seq++;
    _debouncer.cancel();
    snapshot.value = LocationIQAutocompleteSnapshot.idle();
  }

  void setQuery(String query) {
    final q = query.trim();
    if (q.length < minChars) {
      clear();
      return;
    }
    _debouncer.run(() => _fetch(q));
  }

  Future<void> _fetch(String query) async {
    final now = DateTime.now();
    final mySeq = ++_seq;

    // cooldown after 429 to avoid spamming API
    if (_cooldownUntil != null && now.isBefore(_cooldownUntil!)) {
      snapshot.value = LocationIQAutocompleteSnapshot(
        status: LocationIQAutocompleteStatus.rateLimited,
        query: query,
        items: const [],
        updatedAt: now,
        error: LocationIQRateLimitedException(429, 'Cooling down (recent 429)'),
        cooldownUntil: _cooldownUntil,
      );
      return;
    }

    final key = _normalizeKey(query);

    final cached = _cache.get(key);
    if (cached != null) {
      snapshot.value = LocationIQAutocompleteSnapshot(
        status: cached.isEmpty ? LocationIQAutocompleteStatus.empty : LocationIQAutocompleteStatus.success,
        query: query,
        items: cached,
        updatedAt: now,
      );
      return;
    }

    snapshot.value = LocationIQAutocompleteSnapshot(
      status: LocationIQAutocompleteStatus.loading,
      query: query,
      items: const [],
      updatedAt: now,
    );

    try {
      final results = await api.suggest(query: query, request: request);
      if (mySeq != _seq) return;

      _cache.set(key, results);

      snapshot.value = LocationIQAutocompleteSnapshot(
        status: results.isEmpty ? LocationIQAutocompleteStatus.empty : LocationIQAutocompleteStatus.success,
        query: query,
        items: results,
        updatedAt: DateTime.now(),
      );
    } on LocationIQRateLimitedException catch (e) {
      if (mySeq != _seq) return;
      _cooldownUntil = DateTime.now().add(rateLimitCooldown);

      snapshot.value = LocationIQAutocompleteSnapshot(
        status: LocationIQAutocompleteStatus.rateLimited,
        query: query,
        items: const [],
        updatedAt: DateTime.now(),
        error: e,
        cooldownUntil: _cooldownUntil,
      );
    } catch (e) {
      if (mySeq != _seq) return;

      snapshot.value = LocationIQAutocompleteSnapshot(
        status: LocationIQAutocompleteStatus.error,
        query: query,
        items: const [],
        updatedAt: DateTime.now(),
        error: e,
      );
    }
  }
}
