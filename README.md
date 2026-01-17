# locationiq_autocomplete_flutter

A Flutter autocomplete TextField widget and controller for the LocationIQ Autocomplete API.

## Features

- Ready-to-use autocomplete TextField with an overlay dropdown
- Debounced requests to reduce API calls
- In-memory LRU cache for repeated queries
- Rate-limit handling (HTTP 429) with cooldown state
- Customizable UI builders (loading, empty, error, rate-limited, option item)
- Reusable controller (share one controller across screens/widgets)
- Optional `FormField` wrapper for validation and forms

## Disclaimer

This package is not affiliated with, endorsed by, or sponsored by LocationIQ.  
LocationIQ is a trademark of its respective owner.

Use of the LocationIQ API is subject to LocationIQ’s Terms of Service. You must use your own API key.

## Installation

Until this package is published on pub.dev, add it from Git:

```yaml
dependencies:
  locationiq_autocomplete_flutter:
    git:
      url: https://github.com/iZenrix/locationiq_autocomplete_flutter.git
      ref: main
```

Then run:

```bash
flutter pub get
```

Import:

```dart
import 'package:locationiq_autocomplete_flutter/locationiq_autocomplete_flutter.dart';
```

## Getting an API key

Create an API key from your LocationIQ account, then pass it to the API client.

## Basic usage

```dart
import 'package:flutter/material.dart';
import 'package:locationiq_autocomplete_flutter/locationiq_autocomplete_flutter.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  late final LocationIQAutocompleteApi _api;

  @override
  void initState() {
    super.initState();
    _api = LocationIQAutocompleteApi(
      apiKey: 'YOUR_LOCATIONIQ_KEY',
      userAgent: 'com.example.myapp/1.0',
    );
  }

  @override
  void dispose() {
    _api.close(); // Close only if you created this instance.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LocationIQ Autocomplete')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LocationIQAutocompleteField(
          api: _api,
          onSelected: (result) {
            // Use result.lat, result.lon, result.displayName, etc.
            debugPrint('Selected: ${result.displayName} (${result.lat}, ${result.lon})');
          },
        ),
      ),
    );
  }
}
```

## Configure the request

You can configure request parameters using `LocationIQAutocompleteRequest`:

```dart
LocationIQAutocompleteField(
  api: _api,
  request: const LocationIQAutocompleteRequest(
    limit: 8,
    countrycodes: 'id',     // e.g. "id" or "id,sg"
    normalizecity: 1,
    acceptLanguage: 'id',
    // viewbox: '106.6,-6.1,107.0,-6.4', // left,top,right,bottom
    // bounded: 1,
    // tag: 'place',
  ),
  onSelected: (r) {},
)
```

## Customizing the dropdown UI

### Option item UI

```dart
LocationIQAutocompleteField(
  api: _api,
  optionBuilder: (context, option) {
    return ListTile(
      title: Text(option.title),
      subtitle: option.subtitle.isEmpty ? null : Text(option.subtitle),
      trailing: Text('${option.lat.toStringAsFixed(5)}, ${option.lon.toStringAsFixed(5)}'),
    );
  },
  onSelected: (r) {},
)
```

### Loading / empty / error / rate-limited

```dart
LocationIQAutocompleteField(
  api: _api,
  loadingBuilder: (_) => const Padding(
    padding: EdgeInsets.all(12),
    child: Text('Searching...'),
  ),
  emptyBuilder: (_) => const Padding(
    padding: EdgeInsets.all(12),
    child: Text('No results'),
  ),
  errorBuilder: (_, err) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text('Error: $err'),
  ),
  rateLimitedBuilder: (_, until) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      until == null ? 'Rate limited. Please try again.' : 'Rate limited. Try again later.',
    ),
  ),
  onSelected: (r) {},
)
```

## Using a reusable controller

If you want to reuse the same controller instance (for caching or cross-widget sharing), provide a controller:

```dart
class PageWithController extends StatefulWidget {
  const PageWithController({super.key});

  @override
  State<PageWithController> createState() => _PageWithControllerState();
}

class _PageWithControllerState extends State<PageWithController> {
  late final LocationIQAutocompleteApi _api;
  late final LocationIQAutocompleteController _controller;

  @override
  void initState() {
    super.initState();
    _api = LocationIQAutocompleteApi(apiKey: 'YOUR_LOCATIONIQ_KEY');
    _controller = LocationIQAutocompleteController(
      api: _api,
      minChars: 3,
      debounce: const Duration(milliseconds: 300),
      cacheSize: 50,
      rateLimitCooldown: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocationIQAutocompleteField(
      controller: _controller,
      onSelected: (r) {},
    );
  }
}
```

You can also clear cache manually:

```dart
_controller.clearCache();
```

## Form integration

Use `LocationIQAutocompleteFormField` for form validation:

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: LocationIQAutocompleteFormField(
    api: _api,
    onSelected: (r) {
      // Save selection if needed.
    },
    validator: (value) {
      if (value == null || value.trim().isEmpty) return 'Please select a location';
      return null;
    },
  ),
);
```

## Notes

* This package uses an in-memory cache (LRU). It does not persist results to disk.
* You must provide your own LocationIQ API key.
* Requests are sent to LocationIQ’s autocomplete endpoint. Usage is subject to LocationIQ’s limits and terms.
* If you pass a custom `http.Client` into `LocationIQAutocompleteApi`, you are responsible for closing it.

## Example

See the `example/` folder in the repository for a runnable sample app.

## License

MIT License. See `LICENSE`.
