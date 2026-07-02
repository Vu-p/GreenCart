import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greencart_app/src/core/services/signalr_service.dart';
import 'package:greencart_app/src/core/widgets/app_nav_bar.dart';
import 'package:greencart_app/src/features/auth/application/auth_controller.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectSignalR();
    });
  }

  void _connectSignalR() {
    final user = ref.read(authControllerProvider).user;
    if (user != null) {
      ref.read(signalRServiceProvider).connect(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.user != null && previous?.user?.id != next.user?.id) {
        ref.read(signalRServiceProvider).connect(next.user!.id);
      } else if (next.user == null) {
        ref.read(signalRServiceProvider).disconnect();
      }
    });

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: AppNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
