import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/call_session.dart';
import '../../domain/family_contact.dart';
import '../../domain/play_session.dart';
import '../../i18n/app_localizations.dart';
import '../../webrtc/firestore_signaling_service.dart';
import '../shared/camera_on_frame.dart';
import '../shared/family_hearth_mark.dart';
import '../shared/web_rtc_call_view.dart';
import '../play/playroom_widgets.dart';
import 'contact_tile.dart';

class ChildWallScreen extends StatelessWidget {
  const ChildWallScreen({
    super.key,
    required this.firebaseReady,
    required this.familyId,
    this.currentUserId,
    required this.active,
    required this.cameraOn,
    required this.contacts,
    required this.call,
    required this.playSession,
    required this.onContactPressed,
    required this.onEndCall,
    required this.onPlayAnswer,
    required this.onPlayBoardStroke,
    this.readOnly = false,
    this.onSignOut,
  });

  final bool firebaseReady;
  final String familyId;
  final String? currentUserId;
  final bool active;
  final bool cameraOn;
  final List<FamilyContact> contacts;
  final CallSession call;
  final PlaySession playSession;
  final ValueChanged<FamilyContact> onContactPressed;
  final VoidCallback onEndCall;
  final ValueChanged<String> onPlayAnswer;
  final ValueChanged<PlayBoardStroke> onPlayBoardStroke;
  final bool readOnly;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return CameraOnFrame(
      active: cameraOn,
      child: Stack(
        children: [
          Positioned.fill(
            child: active
                ? _ActiveWall(
                    firebaseReady: firebaseReady,
                    familyId: familyId,
                    currentUserId: currentUserId,
                    contacts: contacts,
                    call: call,
                    playSession: playSession,
                    onContactPressed: onContactPressed,
                    onEndCall: onEndCall,
                    onPlayAnswer: onPlayAnswer,
                    onPlayBoardStroke: onPlayBoardStroke,
                    readOnly: readOnly,
                  )
                : const _DimWall(),
          ),
          if (onSignOut != null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 14,
              right: 18,
              child: _WallAccountMenu(onSignOut: onSignOut!),
            ),
        ],
      ),
    );
  }
}

class _WallAccountMenu extends StatelessWidget {
  const _WallAccountMenu({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Material(
      color: const Color(0xCC1C2024),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: PopupMenuButton<_WallAccountAction>(
        tooltip: strings.signOut,
        color: const Color(0xFF1C2024),
        position: PopupMenuPosition.under,
        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: (action) {
          switch (action) {
            case _WallAccountAction.signOut:
              onSignOut();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<_WallAccountAction>(
            value: _WallAccountAction.signOut,
            child: Row(
              children: [
                const Icon(Icons.logout_rounded),
                const SizedBox(width: 10),
                Text(strings.signOut),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _WallAccountAction { signOut }

class _DimWall extends StatelessWidget {
  const _DimWall();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF090B0D),
      child: Center(
        child: Opacity(
          opacity: 0.28,
          child: FamilyHearthMark(
            size: 180,
            color: Colors.white,
            flameColor: const Color(0xFFFFB545),
          ),
        ),
      ),
    );
  }
}

class _ActiveWall extends StatelessWidget {
  const _ActiveWall({
    required this.firebaseReady,
    required this.familyId,
    required this.currentUserId,
    required this.contacts,
    required this.call,
    required this.playSession,
    required this.onContactPressed,
    required this.onEndCall,
    required this.onPlayAnswer,
    required this.onPlayBoardStroke,
    required this.readOnly,
  });

  final bool firebaseReady;
  final String familyId;
  final String? currentUserId;
  final List<FamilyContact> contacts;
  final CallSession call;
  final PlaySession playSession;
  final ValueChanged<FamilyContact> onContactPressed;
  final VoidCallback onEndCall;
  final ValueChanged<String> onPlayAnswer;
  final ValueChanged<PlayBoardStroke> onPlayBoardStroke;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final activeCall = !readOnly && call.isActiveMedia;
    final calledContact = activeCall ? _contactForCall(call, contacts) : null;

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFFFF8EA)),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _WallBackdrop())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 700;
                  final columns = constraints.maxWidth > 1100
                      ? 4
                      : constraints.maxWidth > 760
                      ? 3
                      : constraints.maxWidth > 540
                      ? 2
                      : 1;
                  final tileAspect = constraints.maxWidth > 1100
                      ? 0.9
                      : isCompact
                      ? 0.86
                      : 0.88;

                  return GridView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 28),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 22,
                      crossAxisSpacing: 22,
                      childAspectRatio: tileAspect,
                    ),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ContactTile(
                        contact: contact,
                        enabled: !activeCall && !readOnly,
                        gardenIndex: index,
                        onPressed: () => onContactPressed(contact),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          if (activeCall)
            Positioned.fill(
              child: _CallingOverlay(
                firebaseReady: firebaseReady,
                familyId: familyId,
                call: call,
                contact: calledContact,
                playSession: playSession,
                currentUserId: currentUserId,
                onEndCall: onEndCall,
                onPlayAnswer: onPlayAnswer,
                onPlayBoardStroke: onPlayBoardStroke,
                readOnly: readOnly,
              ),
            ),
          if (!activeCall && playSession.hasPlaySurface)
            Positioned.fill(
              child: ChildPlaySurface(
                session: playSession,
                onAnswer: onPlayAnswer,
                onBoardStroke: readOnly ? null : onPlayBoardStroke,
                actorId: currentUserId ?? 'child-wall',
                interactive: !readOnly,
                playfulButton: true,
              ),
            ),
        ],
      ),
    );
  }

  FamilyContact? _contactForCall(
    CallSession call,
    List<FamilyContact> contacts,
  ) {
    final contactId = call.isCallingChildWall
        ? call.callerDeviceId
        : call.calleeDeviceId;
    for (final contact in contacts) {
      if (contact.id == contactId) {
        return contact;
      }
    }
    return null;
  }
}

class _CallingOverlay extends StatelessWidget {
  const _CallingOverlay({
    required this.firebaseReady,
    required this.familyId,
    required this.call,
    required this.contact,
    required this.playSession,
    required this.currentUserId,
    required this.onEndCall,
    required this.onPlayAnswer,
    required this.onPlayBoardStroke,
    required this.readOnly,
  });

  final bool firebaseReady;
  final String familyId;
  final CallSession call;
  final FamilyContact? contact;
  final PlaySession playSession;
  final String? currentUserId;
  final VoidCallback onEndCall;
  final ValueChanged<String> onPlayAnswer;
  final ValueChanged<PlayBoardStroke> onPlayBoardStroke;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final accent = Color(contact?.accentColorValue ?? 0xFFE85D43);
    final strings = context.t;
    final role = call.isCallingChildWall
        ? WebRtcPeerRole.callee
        : WebRtcPeerRole.caller;

    return ColoredBox(
      color: const Color(0xE61B1613),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 88, 22, 22),
          child: Stack(
            children: [
              Positioned.fill(
                child: playSession.hasPlaySurface
                    ? _CallPlaySplit(
                        callView: WebRtcCallView(
                          firebaseReady: firebaseReady,
                          familyId: familyId,
                          roomId: call.id,
                          sessionId: _sessionIdFor(call),
                          role: role,
                          title: contact == null
                              ? strings.familyIsHere
                              : contact!.displayName,
                          accent: accent,
                          onEndCall: onEndCall,
                        ),
                        playSurface: ChildPlaySurface(
                          session: playSession,
                          onAnswer: onPlayAnswer,
                          onBoardStroke: readOnly ? null : onPlayBoardStroke,
                          actorId: currentUserId ?? 'child-wall',
                          interactive: !readOnly,
                          overlay: true,
                          playfulButton: true,
                        ),
                      )
                    : WebRtcCallView(
                        firebaseReady: firebaseReady,
                        familyId: familyId,
                        roomId: call.id,
                        sessionId: _sessionIdFor(call),
                        role: role,
                        title: contact == null
                            ? strings.familyIsHere
                            : contact!.displayName,
                        accent: accent,
                        onEndCall: onEndCall,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sessionIdFor(CallSession call) {
    return '${call.id}-${call.createdAt.millisecondsSinceEpoch}';
  }
}

class _CallPlaySplit extends StatelessWidget {
  const _CallPlaySplit({required this.callView, required this.playSurface});

  final Widget callView;
  final Widget playSurface;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 820;
        final videoFlex = sideBySide ? 5 : 4;
        final playFlex = sideBySide ? 4 : 5;

        if (sideBySide) {
          return Row(
            children: [
              Expanded(flex: videoFlex, child: callView),
              const SizedBox(width: 16),
              Expanded(
                flex: playFlex,
                child: _PlaySurfaceFrame(child: playSurface),
              ),
            ],
          );
        }

        return Column(
          children: [
            Expanded(flex: videoFlex, child: callView),
            const SizedBox(height: 14),
            Expanded(
              flex: playFlex,
              child: _PlaySurfaceFrame(child: playSurface),
            ),
          ],
        );
      },
    );
  }
}

class _PlaySurfaceFrame extends StatelessWidget {
  const _PlaySurfaceFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: child);
  }
}

class _WallBackdrop extends CustomPainter {
  const _WallBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFFFE7C7);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.12)
        ..quadraticBezierTo(
          size.width * 0.3,
          size.height * 0.04,
          size.width,
          size.height * 0.14,
        )
        ..lineTo(size.width, 0)
        ..lineTo(0, 0)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFDDF2E8);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.74)
        ..quadraticBezierTo(
          size.width * 0.42,
          size.height * 0.91,
          size.width,
          size.height * 0.72,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      paint,
    );

    _drawSoftCircle(
      canvas,
      Offset(size.width * 0.12, size.height * 0.22),
      size.shortestSide * 0.1,
      const Color(0xFFFFB545).withValues(alpha: 0.24),
    );
    _drawSoftCircle(
      canvas,
      Offset(size.width * 0.86, size.height * 0.28),
      size.shortestSide * 0.07,
      const Color(0xFF4967B1).withValues(alpha: 0.16),
    );
    _drawSoftCircle(
      canvas,
      Offset(size.width * 0.2, size.height * 0.86),
      size.shortestSide * 0.08,
      const Color(0xFFE85D43).withValues(alpha: 0.14),
    );

    paint
      ..color = const Color(0x1A197A6E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < 6; index += 1) {
      final y = size.height * (0.18 + index * 0.12);
      final path = Path()
        ..moveTo(size.width * 0.08, y)
        ..quadraticBezierTo(
          size.width * 0.28,
          y + (index.isEven ? 30 : -24),
          size.width * 0.48,
          y,
        )
        ..quadraticBezierTo(
          size.width * 0.68,
          y - (index.isEven ? 24 : -30),
          size.width * 0.92,
          y + 18,
        );
      canvas.drawPath(path, paint);
    }

    final starPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x22E85D43);
    for (var index = 0; index < 16; index += 1) {
      final x = size.width * ((0.11 + index * 0.173) % 0.92);
      final y = size.height * ((0.16 + index * 0.119) % 0.84);
      _drawStar(
        canvas,
        Offset(x, y),
        8 + (index % 3) * 2,
        index * 0.4,
        starPaint,
      );
    }
  }

  void _drawSoftCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color,
    );
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Paint paint,
  ) {
    final path = Path();
    for (var index = 0; index < 10; index += 1) {
      final pointRadius = index.isEven ? radius : radius * 0.48;
      final angle = rotation - 1.5708 + index * 0.6283;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * pointRadius;
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
