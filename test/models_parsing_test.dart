import 'package:flutter_test/flutter_test.dart';
import 'package:locationiq_autocomplete_flutter/locationiq_autocomplete_flutter.dart';

void main() {
  test('LocationIQAutocompleteResult.fromJson parses basic fields', () {
    final json = <String, dynamic>{
      'place_id': '123',
      'lat': '1.23',
      'lon': '4.56',
      'display_name': 'Jakarta, Indonesia',
      'class': 'place',
      'type': 'city',
      'importance': 0.9,
    };

    final r = LocationIQAutocompleteResult.fromJson(json);
    expect(r.placeId, '123');
    expect(r.lat, closeTo(1.23, 1e-9));
    expect(r.lon, closeTo(4.56, 1e-9));
    expect(r.displayName, 'Jakarta, Indonesia');
    expect(r.categoryClass, 'place');
    expect(r.type, 'city');
    expect(r.importance, closeTo(0.9, 1e-9));
    expect(r.title, 'Jakarta');
    expect(r.subtitle, 'Indonesia');
  });
}
