import 'package:flutter/material.dart';
import 'package:locationiq_autocomplete_flutter/locationiq_autocomplete_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocationIQ Autocomplete Demo',
      theme: ThemeData(useMaterial3: true),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  // Replace with your own LocationIQ key, get one at https://locationiq.com/
  // Recommended to use a environment variable or secure storage for real apps.
  static const _apiKey = 'YOUR_LOCATIONIQ_KEY_HERE';

  late final LocationIQAutocompleteApi api = LocationIQAutocompleteApi(
    apiKey: _apiKey,
    userAgent: 'demo-app/0.1.0',
  );

  LocationIQAutocompleteResult? selected;

  @override
  void dispose() {
    api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = selected;

    return Scaffold(
      appBar: AppBar(title: const Text('LocationIQ Autocomplete')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LocationIQAutocompleteField(
              // api: api,
              request: const LocationIQAutocompleteRequest(
                limit: 8,
                countrycodes: 'id',
                acceptLanguage: 'id',
                normalizecity: 1,
              ),
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onSelected: (r) => setState(() => selected = r),
              optionBuilder: (context, r) {
                return ListTile(
                  title: Text(r.title),
                  subtitle: Text('${r.subtitle}\n(${r.lat}, ${r.lon})'),
                  isThreeLine: true,
                );
              },
              errorBuilder: (context, err) {
                if (err is LocationIQApiException && err.statusCode == 404) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Location not found.'),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('An error occurred while fetching suggestions.'),
                );
              },
            ),
            const SizedBox(height: 16),
            if (s != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Selected:\n${s.displayName}\nLat: ${s.lat}\nLon: ${s.lon}',
                  ),
                ),
              )
            else
              const Text('Pick a location from suggestions.'),
          ],
        ),
      ),
    );
  }
}
