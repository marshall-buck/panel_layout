import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:panel_layout/panel_layout.dart';

// --- Cubit ---
class LayoutState {
  final bool leftVisible;
  final bool rightVisible;
  LayoutState({this.leftVisible = true, this.rightVisible = true});
}

class LayoutCubit extends Cubit<LayoutState> {
  LayoutCubit() : super(LayoutState());

  void toggleLeft() => emit(LayoutState(leftVisible: !state.leftVisible, rightVisible: state.rightVisible));
  void toggleRight() => emit(LayoutState(leftVisible: state.leftVisible, rightVisible: !state.rightVisible));
}

// --- Tab ---
class BlocTab extends StatelessWidget {
  const BlocTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LayoutCubit(),
      child: const BlocLayoutBody(),
    );
  }
}

class BlocLayoutBody extends StatelessWidget {
  const BlocLayoutBody({super.key});

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      builder: (context, controller) {
        // Initialize
        final left = controller.registerPanel(
          const PanelId('left'),
          sizing: const FixedSizing(200),
          mode: PanelMode.inline,
          anchor: PanelAnchor.left,
          visuals: const PanelVisuals(showBorders: true),
        );
        controller.registerPanel(
          const PanelId('center'),
          sizing: const FlexibleSizing(1),
          mode: PanelMode.inline,
          anchor: PanelAnchor.left,
        );
        final right = controller.registerPanel(
          const PanelId('right'),
          sizing: const FixedSizing(200),
          mode: PanelMode.inline,
          anchor: PanelAnchor.right,
          visuals: const PanelVisuals(showBorders: true),
        );

        return BlocListener<LayoutCubit, LayoutState>(
          listener: (context, state) {
            left.setVisible(visible: state.leftVisible);
            right.setVisible(visible: state.rightVisible);
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('BLoC Sync Example'),
              automaticallyImplyLeading: false,
              backgroundColor: Colors.grey[200],
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => context.read<LayoutCubit>().toggleLeft(),
                tooltip: 'Toggle Left via BLoC',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info, color: Colors.black),
                  onPressed: () => context.read<LayoutCubit>().toggleRight(),
                  tooltip: 'Toggle Right via BLoC',
                ),
              ],
            ),
            body: PanelArea(
              controller: controller,
              panelIds: const [PanelId('left'), PanelId('center'), PanelId('right')],
              panelBuilder: (context, id) {
                if (id.value == 'center') {
                  return const Center(child: Text('Main Content\n(Controlled by BLoC)'));
                }
                return Center(child: Text(id.value));
              },
            ),
          ),
        );
      },
    );
  }
}
