class LocationIQAddress {
  const LocationIQAddress({
    this.name,
    this.houseNumber,
    this.road,
    this.neighbourhood,
    this.suburb,
    this.city,
    this.county,
    this.state,
    this.postcode,
    this.country,
    this.countryCode,
    this.extra = const {},
  });

  final String? name;
  final String? houseNumber;
  final String? road;
  final String? neighbourhood;
  final String? suburb;
  final String? city;
  final String? county;
  final String? state;
  final String? postcode;
  final String? country;
  final String? countryCode;

  final Map<String, dynamic> extra;

  factory LocationIQAddress.fromJson(Map<String, dynamic> j) {
    final known = <String>{
      'name',
      'house_number',
      'road',
      'neighbourhood',
      'suburb',
      'city',
      'county',
      'state',
      'postcode',
      'country',
      'country_code',
    };

    final extra = <String, dynamic>{};
    for (final e in j.entries) {
      if (!known.contains(e.key)) extra[e.key] = e.value;
    }

    return LocationIQAddress(
      name: j['name']?.toString(),
      houseNumber: j['house_number']?.toString(),
      road: j['road']?.toString(),
      neighbourhood: j['neighbourhood']?.toString(),
      suburb: j['suburb']?.toString(),
      city: j['city']?.toString(),
      county: j['county']?.toString(),
      state: j['state']?.toString(),
      postcode: j['postcode']?.toString(),
      country: j['country']?.toString(),
      countryCode: j['country_code']?.toString(),
      extra: extra,
    );
  }
}

class LocationIQAutocompleteResult {
  const LocationIQAutocompleteResult({
    required this.placeId,
    required this.lat,
    required this.lon,
    required this.displayName,
    this.osmType,
    this.osmId,
    this.licence,
    this.boundingbox,
    this.categoryClass,
    this.type,
    this.importance,
    this.icon,
    this.displayPlace,
    this.displayAddress,
    this.address,
    this.raw = const {},
  });

  final String placeId;
  final double lat;
  final double lon;
  final String displayName;
  final String? osmType;
  final String? osmId;
  final String? licence;
  final List<String>? boundingbox;
  final String? categoryClass;
  final String? type;
  final double? importance;
  final String? icon;
  final String? displayPlace;
  final String? displayAddress;
  final LocationIQAddress? address;
  final Map<String, dynamic> raw;

  String get title {
    final dp = displayPlace?.trim();
    if (dp != null && dp.isNotEmpty) return dp;

    final idx = displayName.indexOf(',');
    return idx == -1 ? displayName : displayName.substring(0, idx).trim();
  }

  String get subtitle {
    final da = displayAddress?.trim();
    if (da != null && da.isNotEmpty) return da;

    final idx = displayName.indexOf(',');
    return idx == -1 ? '' : displayName.substring(idx + 1).trim();
  }

  factory LocationIQAutocompleteResult.fromJson(Map<String, dynamic> j) {
    double parseNum(dynamic v) {
      if (v is num) return v.toDouble();
      return double.parse(v.toString());
    }

    final addr = j['address'];
    LocationIQAddress? parsedAddress;
    if (addr is Map<String, dynamic>) {
      parsedAddress = LocationIQAddress.fromJson(addr);
    } else if (addr is Map) {
      parsedAddress = LocationIQAddress.fromJson(addr.cast<String, dynamic>());
    }

    return LocationIQAutocompleteResult(
      placeId: j['place_id']?.toString() ?? '',
      lat: parseNum(j['lat']),
      lon: parseNum(j['lon']),
      displayName: j['display_name']?.toString() ?? '',
      osmType: j['osm_type']?.toString(),
      osmId: j['osm_id']?.toString(),
      licence: j['licence']?.toString(),
      boundingbox: (j['boundingbox'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      categoryClass: j['class']?.toString(),
      type: j['type']?.toString(),
      importance: j['importance'] == null ? null : parseNum(j['importance']),
      icon: j['icon']?.toString(),
      displayPlace: j['display_place']?.toString(),
      displayAddress: j['display_address']?.toString(),
      address: parsedAddress,
      raw: j.map((k, v) => MapEntry(k.toString(), v)),
    );
  }
}

class LocationIQAutocompleteRequest {
  const LocationIQAutocompleteRequest({
    this.limit = 10,
    this.viewbox,
    this.bounded,
    this.countrycodes,
    this.normalizecity,
    this.acceptLanguage,
    this.tag,
  });

  final int limit;

  final String? viewbox;

  final int? bounded;

  final String? countrycodes;

  final int? normalizecity;

  final String? acceptLanguage;

  final String? tag;

  Map<String, String> toQueryParams() {
    final p = <String, String>{'limit': limit.toString()};
    if (viewbox != null) p['viewbox'] = viewbox!;
    if (bounded != null) p['bounded'] = bounded.toString();
    if (countrycodes != null) p['countrycodes'] = countrycodes!;
    if (normalizecity != null) p['normalizecity'] = normalizecity.toString();
    if (acceptLanguage != null) p['accept-language'] = acceptLanguage!;
    if (tag != null) p['tag'] = tag!;
    return p;
  }

  LocationIQAutocompleteRequest copyWith({
    int? limit,
    String? viewbox,
    int? bounded,
    String? countrycodes,
    int? normalizecity,
    String? acceptLanguage,
    String? tag,
  }) {
    return LocationIQAutocompleteRequest(
      limit: limit ?? this.limit,
      viewbox: viewbox ?? this.viewbox,
      bounded: bounded ?? this.bounded,
      countrycodes: countrycodes ?? this.countrycodes,
      normalizecity: normalizecity ?? this.normalizecity,
      acceptLanguage: acceptLanguage ?? this.acceptLanguage,
      tag: tag ?? this.tag,
    );
  }
}
