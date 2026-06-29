import 'package:flutter/material.dart';

import '../../i18n/app_localizations.dart';

class SoundEffectsToggle extends StatelessWidget {
  const SoundEffectsToggle({
    super.key,
    required this.enabled,
    required this.onChanged,
    this.dark = false,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
    final foreground = dark
        ? Colors.white
        : enabled
        ? const Color(0xFF221B16)
        : const Color(0xFF6F6258);
    final background = dark ? const Color(0xD91C2024) : Colors.white;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: dark ? Colors.transparent : const Color(0xFFE7D9CC),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: enabled ? strings.soundEffectsOn : strings.soundEffectsOff,
        color: foreground,
        onPressed: () => onChanged(!enabled),
        icon: Icon(
          enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        ),
      ),
    );
  }
}
