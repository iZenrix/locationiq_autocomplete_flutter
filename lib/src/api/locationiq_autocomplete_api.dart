import 'dart:convert';

import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'models.dart';

class LocationIQAutocompleteApi {
  LocationIQAutocompleteApi({
    required this.apiKey,
    this.treat404AsEmpty = true,
    http.Client? httpClient,
    Uri? baseUri,
    this.userAgent,
  })  : _http = httpClient ?? http.Client(),
        _baseUri = baseUri ?? Uri.parse('https://api.locationiq.com/v1/autocomplete');

  final String apiKey;
  final http.Client _http;
  final Uri _baseUri;

  /// Optional User-Agent to help you identify your app in logs.
  final String? userAgent;

  final bool treat404AsEmpty;

  Future<List<LocationIQAutocompleteResult>> suggest({
    required String query,
    LocationIQAutocompleteRequest request = const LocationIQAutocompleteRequest(),
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    if (q.length > 200) {
      throw ArgumentError('Query too long (max 200 chars).');
    }

    final params = <String, String>{
      'key': apiKey,
      'q': q,
      ...request.toQueryParams(),
    };

    final uri = _baseUri.replace(queryParameters: params);

    final headers = <String, String>{};
    if (userAgent != null && userAgent!.trim().isNotEmpty) {
      headers['User-Agent'] = userAgent!;
    }

    final resp = await _http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => LocationIQAutocompleteResult.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    }

    if (resp.statusCode == 429) {
      throw LocationIQRateLimitedException(429, 'Rate limited (HTTP 429)', body: resp.body);
    }

    if (resp.statusCode == 404 && treat404AsEmpty) {
      final body = resp.body.toLowerCase();
      if (body.contains('unable to geocode') || body.contains('no location')) {
        return const [];
      }
    }

    throw LocationIQApiException(resp.statusCode, 'HTTP ${resp.statusCode}', body: resp.body);
  }

  void close() => _http.close();
}
