class LocationIQApiException implements Exception {
  LocationIQApiException(this.statusCode, this.message, {this.body});

  final int statusCode;
  final String message;
  final String? body;

  @override
  String toString() => 'LocationIQApiException($statusCode): $message';
}

class LocationIQRateLimitedException extends LocationIQApiException {
  LocationIQRateLimitedException(super.statusCode, super.message, {super.body});
}
