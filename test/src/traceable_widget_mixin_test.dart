// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/traceable_widget_mixin.dart';

import '../ressources/utils/get_initialized_mamoto_tracker.dart';
import '../ressources/utils/matomo_tracker_setup.dart';

void main() {
  group('TraceableClientMixin', () {
    setUpAll(() async {
      matomoTrackerSetup();
      await getInitializedMatomoTracker(shouldForceCreation: false);
    });

    testWidgets(
      'default actionName should be a short string representation of the widget',
      (tester) async {
        const widget = _TestWidget();

        await tester.pumpWidget(widget);

        final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

        expect(state.actionName, 'Created widget ${widget.toStringShort()}');
      },
    );
  });
}

class _TestWidget extends StatefulWidget {
  const _TestWidget();

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget> with TraceableClientMixin {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
