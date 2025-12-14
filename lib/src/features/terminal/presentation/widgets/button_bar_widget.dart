import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/data/global_command_repository.dart';

class ButtonBarWidget extends ConsumerStatefulWidget {
  final Function(String) onCommand;

  const ButtonBarWidget({super.key, required this.onCommand});

  @override
  ConsumerState<ButtonBarWidget> createState() => _ButtonBarWidgetState();
}

class _ButtonBarWidgetState extends ConsumerState<ButtonBarWidget> {
  @override
  Widget build(BuildContext context) {
    final commandsAsync = ref.watch(globalCommandsProvider);

    // If data is not yet loaded or empty, hide the widget completely (return shrinking SizedBox).
    return commandsAsync.when(
      data: (commands) {
        if (commands.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: commands.length,
            itemBuilder: (context, index) {
              final cmd = commands[index];
              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        String finalCommand = cmd.command;
                        if (!finalCommand.endsWith('\r') &&
                            !finalCommand.endsWith('\n')) {
                          finalCommand += '\r';
                        }
                        widget.onCommand(finalCommand);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          cmd.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
