import 'package:flutter/material.dart';

import '../../i18n/app_localizations.dart';

class LanguageMenu extends StatelessWidget {
  const LanguageMenu({
    super.key,
    this.dark = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final bool dark;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final controller = context.languageController;
    final strings = context.t;
    final fg =
        foregroundColor ?? (dark ? Colors.white : const Color(0xFF221B16));

    return Material(
      color:
          backgroundColor ??
          (dark ? const Color(0xD91C2024) : const Color(0xFFFFFFFF)),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: dark ? Colors.transparent : const Color(0xFFE7D9CC),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<AppLanguage>(
        tooltip: strings.language,
        color: dark ? const Color(0xFF1C2024) : Colors.white,
        position: PopupMenuPosition.under,
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, color: fg, size: 20),
            const SizedBox(width: 6),
            Text(
              controller.language.shortName,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        onSelected: controller.setLanguage,
        itemBuilder: (context) => [
          for (final language in AppLanguage.values)
            PopupMenuItem<AppLanguage>(
              value: language,
              child: Row(
                children: [
                  Icon(
                    controller.language == language
                        ? Icons.check_rounded
                        : Icons.language_rounded,
                    color: dark ? Colors.white : const Color(0xFF221B16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    language.nativeName,
                    style: TextStyle(
                      color: dark ? Colors.white : const Color(0xFF221B16),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
