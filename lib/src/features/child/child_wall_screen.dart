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

  @override
  Widget build(BuildContext context) {
    final activeCall = call.isActiveMedia;
    final calledContact = _contactForCall(call, contacts);

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFFFF7EC)),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _WallBackdrop())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
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
                      ? 0.72
                      : isCompact
                      ? 0.82
                      : 0.8;

                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: tileAspect,
                    ),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ContactTile(
                        contact: contact,
                        enabled: !activeCall,
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
              ),
            ),
          if (!activeCall && playSession.hasPlaySurface)
            Positioned.fill(
              child: ChildPlaySurface(
                session: playSession,
                onAnswer: onPlayAnswer,
                onBoardStroke: onPlayBoardStroke,
                actorId: currentUserId ?? 'child-wall',
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
                          onBoardStroke: onPlayBoardStroke,
                          actorId: currentUserId ?? 'child-wall',
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

    paint.color = const Color(0xFFFFE2BF);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.12)
        ..quadraticBezierTo(
          size.width * 0.35,
          size.height * 0.02,
          size.width,
          size.height * 0.18,
        )
        ..lineTo(size.width, 0)
        ..lineTo(0, 0)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFD9F0DF);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.78)
        ..quadraticBezierTo(
          size.width * 0.4,
          size.height * 0.88,
          size.width,
          size.height * 0.7,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      paint,
    );

    paint
      ..color = const Color(0x22E85D43)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.22 + i * 0.11);
      canvas.drawLine(
        Offset(size.width * 0.06, y),
        Offset(size.width * 0.94, y + 20),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
