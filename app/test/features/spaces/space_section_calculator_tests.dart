import 'package:acter/features/space/widgets/related/util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Related Widget Calculations', () {
    test('too many local', () {
      final config = calculateSectionConfig(
        limit: 3,
        localListLen: 5,
        remoteListLen: 0,
      );

      assert(config.listingLimit == 3, 'Wrong listing limit');
      assert(config.isShowSeeAllButton, 'Wrong show all');
      assert(!config.renderRemote, 'Wrong render remote');
      assert(config.remoteCount == 0, 'Wrong remote count');
    });

    test('none local, more remote', () {
      final config = calculateSectionConfig(
        limit: 3,
        localListLen: 0,
        remoteListLen: 5,
      );

      assert(config.listingLimit == 0, 'Wrong listing limit');
      assert(config.isShowSeeAllButton, 'Wrong show all');
      assert(config.renderRemote, 'Wrong render remote');
      assert(config.remoteCount == 3, 'Wrong remote count');
    });

    test('less local, fill remote', () {
      final config = calculateSectionConfig(
        limit: 3,
        localListLen: 2,
        remoteListLen: 1,
      );

      assert(config.listingLimit == 2, 'Wrong listing limit');
      assert(!config.isShowSeeAllButton, 'Wrong show all');
      assert(config.renderRemote, 'Wrong render remote');
      assert(config.remoteCount == 1, 'Wrong remote count');
    });

    test('less local, fill remote with more', () {
      final config = calculateSectionConfig(
        limit: 3,
        localListLen: 1,
        remoteListLen: 4,
      );

      assert(config.listingLimit == 1, 'Wrong listing limit');
      assert(config.isShowSeeAllButton, 'Wrong show all');
      assert(config.renderRemote, 'Wrong render remote');
      assert(config.remoteCount == 2, 'Wrong remote count');
    });

    test('exact local, more remote', () {
      final config = calculateSectionConfig(
        limit: 3,
        localListLen: 3,
        remoteListLen: 4,
      );

      assert(config.listingLimit == 3, 'Wrong listing limit');
      assert(config.isShowSeeAllButton, 'Wrong show all');
      assert(!config.renderRemote, 'Wrong render remote');
      assert(config.remoteCount == 0, 'Wrong remote count');
    });

    test('exact local, none remote', () {
      final config = calculateSectionConfig(
        limit: 3,
        localListLen: 3,
        remoteListLen: 0,
      );

      assert(config.listingLimit == 3, 'Wrong listing limit');
      assert(!config.isShowSeeAllButton, 'Wrong show all');
      assert(!config.renderRemote, 'Wrong render remote');
      assert(config.remoteCount == 0, 'Wrong remote count');
    });
  });
}
