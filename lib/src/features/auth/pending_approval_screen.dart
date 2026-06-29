import 'package:flutter/material.dart';

import '../../domain/family_membership.dart';
import '../../i18n/app_localizations.dart';
import '../shared/family_hearth_mark.dart';
import '../shared/language_menu.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({
    super.key,
    required this.membership,
    required this.onSignOut,
  });

  final FamilyMembership membership;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final rejected = membership.status == FamilyMemberStatus.rejected;
    final strings = context.t;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF7EC), Color(0xFFFFE2BF), Color(0xFFDDF2E8)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(top: 14, right: 18, child: LanguageMenu()),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Color(0xFFE7D9CC)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FamilyHearthMark(
                              size: 96,
                              backgroundColor: rejected
                                  ? const Color(0xFFFFD7D0)
                                  : const Color(0xFFFFC56B),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              rejected
                                  ? strings.accessNotApproved
                                  : strings.waitingForParent,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF221B16),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rejected
                                  ? strings.notApprovedBy(membership.familyName)
                                  : strings.opensAfterApproval(
                                      membership.familyName,
                                    ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF6F6258),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBF7),
                                border: Border.all(
                                  color: const Color(0xFFE7D9CC),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    rejected
                                        ? Icons.block_rounded
                                        : Icons.hourglass_top_rounded,
                                    color: rejected
                                        ? const Color(0xFFE02F2F)
                                        : const Color(0xFFE85D43),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${strings.roleLabel(membership.role)} · ${strings.memberStatusLabel(membership.status)}',
                                      style: const TextStyle(
                                        color: Color(0xFF221B16),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextButton.icon(
                              onPressed: onSignOut,
                              icon: const Icon(Icons.logout_rounded),
                              label: Text(strings.signOut),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
