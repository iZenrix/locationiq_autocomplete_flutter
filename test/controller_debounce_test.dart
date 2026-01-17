import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:locationiq_autocomplete_flutter/locationiq_autocomplete_flutter.dart';

class FakeApi extends LocationIQAutocompleteApi {
  FakeApi() : super(apiKey: 'x');
  int calls = 0;

  @override
  Future<List<LocationIQAutocompleteResult>> suggest({
    required String query,
    LocationIQAutocompleteRequest request = const LocationIQAutocompleteRequest(),
  }) async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return [
      LocationIQAutocompleteResult(
        placeId: '1',
        lat: 0,
        lon: 0,
        displayName: '$query, Test',
      ),
    ];
  }
}

void main() {
  test('controller debounces rapid query updates', () async {
    final api = FakeApi();
    final c = LocationIQAutocompleteController(
      api: api,
      debounce: const Duration(milliseconds: 50),
      minChars: 1,
    );

    c.setQuery('a');
    c.setQuery('ab');
    c.setQuery('abc');

    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(api.calls, 1);
    expect(c.snapshot.value.status, LocationIQAutocompleteStatus.success);
    expect(c.snapshot.value.items.first.displayName.startsWith('abc'), true);

    c.dispose();
  });

  test('controller clears to idle for short queries', () async {
    final api = FakeApi();
    final c = LocationIQAutocompleteController(api: api, minChars: 3);

    c.setQuery('ab'); // too short
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(c.snapshot.value.status, LocationIQAutocompleteStatus.idle);
    c.dispose();
  });
}
