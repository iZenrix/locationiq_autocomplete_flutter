import 'package:flutter/material.dart';

import '../api/locationiq_autocomplete_api.dart';
import '../api/models.dart';
import 'autocomplete_field.dart';
import 'controller.dart';

class LocationIQAutocompleteFormField extends FormField<String> {
  LocationIQAutocompleteFormField({
    super.key,
    LocationIQAutocompleteApi? api,
    LocationIQAutocompleteController? controller,
    LocationIQAutocompleteRequest request = const LocationIQAutocompleteRequest(),
    required ValueChanged<LocationIQAutocompleteResult> onSelected,
    InputDecoration decoration = const InputDecoration(hintText: 'Search location…'),
    int minChars = 3,
    Duration debounce = const Duration(milliseconds: 300),
    super.onSaved,
    super.validator,
    super.initialValue,
    AutovalidateMode super.autovalidateMode = AutovalidateMode.disabled,
    super.enabled,
  }) : super(
    builder: (state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LocationIQAutocompleteField(
            api: api,
            controller: controller,
            request: request,
            minChars: minChars,
            debounce: debounce,
            decoration: decoration.copyWith(errorText: state.errorText),
            onSelected: (r) {
              state.didChange(r.displayName);
              onSelected(r);
            },
          ),
        ],
      );
    },
  );
}
