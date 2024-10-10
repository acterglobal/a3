import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/pins/widgets/pin_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PinsListPage extends ConsumerWidget {
  final String? spaceId;

  const PinsListPage({
    super.key,
    this.spaceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(context, ref),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      centerTitle: false,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).pins),
          if (spaceId != null) SpaceNameWidget(spaceId: spaceId!),
        ],
      ),
      actions: [
        AddButtonWithCanPermission(
          canString: 'CanPostPin',
          onPressed: () => context.pushNamed(
            Routes.createPin.name,
            queryParameters: {'spaceId': spaceId},
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ActerSearchWidget(),
        Expanded(child: PinListWidget(spaceId: spaceId, shrinkWrap: false)),
      ],
    );
  }
}
