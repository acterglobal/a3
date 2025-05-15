import 'dart:convert';

import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/shared_prefs.dart';

void main() {
  group('asyncFeaturesProvider', () {
    test('handles non-existent features gracefully', () async {
      mockSharedPrefs({
        labsKey: json.encode([
          {'key': 'nonExistentFeature', 'active': true},
          {'key': 'chatNG', 'active': false},
        ]),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Get the features from the provider
      final features = await container.read(asyncFeaturesProvider.future);

      // Verify that:
      // 1. The non-existent feature was ignored
      // 2. The chatNG feature was properly parsed
      // 3. Default features are still applied
      expect(features.flags.length, 1); // Only chatNG should be present
      expect(features.flags.first.feature, LabsFeature.chatNG);
      expect(features.flags.first.active, false);

      // Verify default features are still applied
      for (final defaultFeature in LabsFeature.defaults) {
        if (defaultFeature != LabsFeature.chatNG) {
          expect(features.isActive(defaultFeature), true);
        }
      }
    });

    test('handles empty features list', () async {
      // Mock shared preferences to return an empty array
      mockSharedPrefs({labsKey: '[]'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Get the features from the provider
      final features = await container.read(asyncFeaturesProvider.future);

      // Verify that:
      // 1. No features are explicitly set
      // 2. Default features are applied
      expect(features.flags.length, 0);

      // Verify all default features are active
      for (final defaultFeature in LabsFeature.defaults) {
        expect(features.isActive(defaultFeature), true);
      }
    });
  });
}
