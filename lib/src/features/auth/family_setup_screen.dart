import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/auth_repository.dart';
import '../../data/family_repository.dart';
import '../../domain/family_membership.dart';
import '../../i18n/app_localizations.dart';
import '../shared/family_hearth_mark.dart';
import '../shared/language_menu.dart';

class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({
    super.key,
    required this.user,
    required this.authRepository,
    required this.familyRepository,
  });

  final User user;
  final AuthRepository authRepository;
  final FamilyRepository familyRepository;

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  late final TextEditingController _familyNameController =
      TextEditingController(text: _initialFamilyName());
  final _inviteCodeController = TextEditingController();
  FamilyRole _joinRole = FamilyRole.relative;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _familyNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    await _run(
      () => widget.familyRepository.createFamily(
        uid: widget.user.uid,
        email: widget.user.email ?? '',
        displayName: widget.user.displayName ?? '',
        familyName: _familyNameController.text,
      ),
    );
  }

  Future<void> _joinFamily() async {
    await _run(
      () => widget.familyRepository.joinFamilyWithInvite(
        uid: widget.user.uid,
        email: widget.user.email ?? '',
        displayName: widget.user.displayName ?? '',
        inviteCode: _inviteCodeController.text,
        role: _joinRole,
      ),
    );
  }

  Future<void> _pasteInviteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      return;
    }
    setState(() => _inviteCodeController.text = text);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await action();
    } on Object catch (error) {
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFFFF7EC)),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: _SetupBackdrop()),
              const Positioned(top: 14, right: 18, child: LanguageMenu()),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 760;
                        final cards = [
                          Expanded(
                            child: _SetupCard(
                              icon: Icons.home_rounded,
                              title: strings.createFamily,
                              subtitle: strings.createFamilySubtitle,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _familyNameController,
                                    decoration: _fieldDecoration(
                                      icon: Icons.favorite_rounded,
                                      label: strings.familyName,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  FilledButton.icon(
                                    style: _primaryButtonStyle(),
                                    onPressed: _busy ? null : _createFamily,
                                    icon: const Icon(Icons.add_home_rounded),
                                    label: Text(strings.createHome),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: _SetupCard(
                              icon: Icons.key_rounded,
                              title: strings.joinWithInvite,
                              subtitle: strings.joinWithInviteSubtitle,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _inviteCodeController,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: _fieldDecoration(
                                      icon: Icons.password_rounded,
                                      label: strings.inviteCode,
                                      suffixIcon: IconButton(
                                        tooltip: strings.pasteInviteCode,
                                        onPressed: _busy
                                            ? null
                                            : _pasteInviteCode,
                                        icon: const Icon(
                                          Icons.content_paste_rounded,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SegmentedButton<FamilyRole>(
                                    segments: [
                                      ButtonSegment(
                                        value: FamilyRole.parent,
                                        icon: const Icon(Icons.shield_rounded),
                                        label: Text(
                                          strings.roleLabel(FamilyRole.parent),
                                        ),
                                      ),
                                      ButtonSegment(
                                        value: FamilyRole.relative,
                                        icon: const Icon(
                                          Icons.favorite_rounded,
                                        ),
                                        label: Text(
                                          strings.roleLabel(
                                            FamilyRole.relative,
                                          ),
                                        ),
                                      ),
                                      ButtonSegment(
                                        value: FamilyRole.childWall,
                                        icon: const Icon(
                                          Icons.tablet_mac_rounded,
                                        ),
                                        label: Text(
                                          strings.roleLabel(
                                            FamilyRole.childWall,
                                          ),
                                        ),
                                      ),
                                    ],
                                    selected: {_joinRole},
                                    onSelectionChanged: _busy
                                        ? null
                                        : (value) => setState(
                                            () => _joinRole = value.first,
                                          ),
                                  ),
                                  const SizedBox(height: 14),
                                  FilledButton.icon(
                                    style: _primaryButtonStyle(),
                                    onPressed: _busy ? null : _joinFamily,
                                    icon: const Icon(Icons.login_rounded),
                                    label: Text(strings.joinHome),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SetupHeader(
                              user: widget.user,
                              onSignOut: _busy
                                  ? null
                                  : widget.authRepository.signOut,
                            ),
                            const SizedBox(height: 16),
                            if (wide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  cards[0],
                                  const SizedBox(width: 16),
                                  cards[1],
                                ],
                              )
                            else
                              Column(
                                children: [
                                  cards[0].child,
                                  const SizedBox(height: 16),
                                  cards[1].child,
                                ],
                              ),
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              _ErrorBox(message: _error!),
                            ],
                            if (_busy) ...[
                              const SizedBox(height: 14),
                              const LinearProgressIndicator(
                                color: Color(0xFFE85D43),
                              ),
                            ],
                          ],
                        );
                      },
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

  String _initialFamilyName() {
    final name = widget.user.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return "$name's Hearth";
    }
    return 'Family Hearth';
  }

  InputDecoration _fieldDecoration({
    required IconData icon,
    required String label,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFFFFBF7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE7D9CC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE85D43), width: 2),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      backgroundColor: const Color(0xFFE85D43),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900),
    );
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('permission-denied')) {
      return context.t.rulesBlocked;
    }
    if (text.contains('Invite code was not found')) {
      return context.t.inviteNotFound;
    }
    return context.t.couldNotFinishSetup('$error');
  }
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({required this.user, required this.onSignOut});

  final User user;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Material(
      color: const Color(0xFF211913),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const FamilyHearthMark(
              size: 62,
              color: Colors.white,
              flameColor: Color(0xFFFFB545),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.setupHome,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email ?? strings.signedIn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFEADCD0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: strings.signOut,
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE7D9CC)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE2BF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFFE85D43)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF221B16),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6F6258),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFECE8),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFFFB8A8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_rounded, color: Color(0xFFE02F2F)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF7B241C),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupBackdrop extends StatelessWidget {
  const _SetupBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SetupBackdropPainter());
  }
}

class _SetupBackdropPainter extends CustomPainter {
  const _SetupBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFFFE2BF);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height * 0.22)
        ..quadraticBezierTo(
          size.width * 0.55,
          size.height * 0.12,
          0,
          size.height * 0.18,
        )
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFDDF2E8);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.78)
        ..quadraticBezierTo(
          size.width * 0.46,
          size.height * 0.9,
          size.width,
          size.height * 0.72,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
