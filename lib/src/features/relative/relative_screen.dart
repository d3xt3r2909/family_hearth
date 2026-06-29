import 'package:flutter/material.dart';

import '../../domain/call_session.dart';
import '../../domain/family_contact.dart';
import '../../domain/play_session.dart';
import '../../i18n/app_localizations.dart';
import '../../webrtc/firestore_signaling_service.dart';
import '../shared/camera_on_frame.dart';
import '../shared/family_hearth_mark.dart';
import '../shared/language_menu.dart';
import '../shared/web_rtc_call_view.dart';
import '../play/playroom_widgets.dart';

class RelativeScreen extends StatelessWidget {
  const RelativeScreen({
    super.key,
    required this.firebaseReady,
    required this.familyId,
    this.currentUserId,
    required this.childWallActive,
    required this.activeCall,
    required this.playSession,
    required this.cameraOn,
    required this.contacts,
    required this.onStartCallToChild,
    required this.onEndCall,
    required this.onSendPlayPrompt,
    required this.onPlayBoardStroke,
    required this.onClearPlayBoard,
    required this.onClearPlay,
    this.onSignOut,
  });

  final bool firebaseReady;
  final String familyId;
  final String? currentUserId;
  final bool childWallActive;
  final CallSession activeCall;
  final PlaySession playSession;
  final bool cameraOn;
  final List<FamilyContact> contacts;
  final VoidCallback onStartCallToChild;
  final VoidCallback onEndCall;
  final void Function(PlayActivity activity, String targetKey) onSendPlayPrompt;
  final ValueChanged<PlayBoardStroke> onPlayBoardStroke;
  final VoidCallback onClearPlayBoard;
  final VoidCallback onClearPlay;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final hasCall = activeCall.isActiveMedia && _callTargetsThisDevice();
    final pendingForThisDevice =
        activeCall.status.needsParentAction && _callTargetsThisDevice();
    final callBusy =
        activeCall.isActiveMedia || activeCall.status.needsParentAction;
    final otherCallBusy = callBusy && !hasCall && !pendingForThisDevice;
    final canStartCall = childWallActive && !callBusy;
    final contact = _contactForCall();
    final strings = context.t;
    final contactName = _counterpartName(context, contact);
    final statusText = hasCall
        ? strings.callSimpleFocused
        : pendingForThisDevice
        ? strings.waitingForParentCallApproval
        : otherCallBusy
        ? activeCall.status.needsParentAction
              ? strings.anotherCallWaitingForParent
              : strings.anotherFamilyCallLive
        : childWallActive
        ? strings.wallOpenForFamilyCalls
        : strings.wallClosedForFamilyCalls;

    return CameraOnFrame(
      active: cameraOn && hasCall,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF3E3), Color(0xFFDDF2E8)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 14,
                right: 18,
                child: _RelativeHeaderActions(onSignOut: onSignOut),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 88, 22, 22),
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Color(0xFFE3D8CD)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(26),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 132,
                                  height: 132,
                                  decoration: BoxDecoration(
                                    color: hasCall
                                        ? const Color(0xFFE85D43)
                                        : const Color(0xFFFFE2BF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: hasCall
                                        ? const Icon(
                                            Icons.video_camera_front_rounded,
                                            size: 70,
                                            color: Colors.white,
                                          )
                                        : const FamilyHearthMark(
                                            size: 94,
                                            color: Color(0xFFE85D43),
                                            flameColor: Color(0xFFFFB545),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  pendingForThisDevice
                                      ? strings.callRequestSent
                                      : hasCall
                                      ? strings.connectedWith(contactName)
                                      : strings.familyHearthReady,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF221B16),
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  statusText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF6F6258),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (hasCall) ...[
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 480,
                                    child: WebRtcCallView(
                                      firebaseReady: firebaseReady,
                                      familyId: familyId,
                                      roomId: activeCall.id,
                                      sessionId: _sessionIdFor(activeCall),
                                      role: _peerRoleForCall(),
                                      title: strings.connectedWith(contactName),
                                      accent: Color(
                                        contact?.accentColorValue ?? 0xFFE85D43,
                                      ),
                                      onEndCall: onEndCall,
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 24),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFE85D43),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(240, 62),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: canStartCall
                                        ? onStartCallToChild
                                        : null,
                                    icon: Icon(
                                      pendingForThisDevice
                                          ? Icons.hourglass_top_rounded
                                          : Icons.video_call_rounded,
                                    ),
                                    label: Text(
                                      pendingForThisDevice
                                          ? strings.waitingForParent
                                          : strings.callChildWall,
                                    ),
                                  ),
                                ],
                                RelativePlayroomPanel(
                                  enabled: childWallActive && firebaseReady,
                                  session: playSession,
                                  actorId: currentUserId ?? 'relative-device',
                                  onSendPrompt: onSendPlayPrompt,
                                  onBoardStroke: onPlayBoardStroke,
                                  onClearBoard: onClearPlayBoard,
                                  onClear: onClearPlay,
                                ),
                              ],
                            ),
                          ),
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

  FamilyContact? _contactForCall() {
    final contactId = activeCall.isCallingChildWall
        ? activeCall.callerDeviceId
        : activeCall.calleeDeviceId;
    for (final item in contacts) {
      if (item.id == contactId) {
        return item;
      }
    }
    return null;
  }

  bool _callTargetsThisDevice() {
    return activeCall.involvesDevice(currentUserId);
  }

  WebRtcPeerRole _peerRoleForCall() {
    final uid = currentUserId;
    if (uid == null || uid.isEmpty) {
      return activeCall.isCallingChildWall
          ? WebRtcPeerRole.caller
          : WebRtcPeerRole.callee;
    }
    return activeCall.callerDeviceId == uid
        ? WebRtcPeerRole.caller
        : WebRtcPeerRole.callee;
  }

  String _counterpartName(BuildContext context, FamilyContact? contact) {
    final uid = currentUserId;
    if (uid == null || uid.isEmpty) {
      return activeCall.isCallingChildWall
          ? context.t.childWall
          : contact?.displayName ?? context.t.family;
    }
    if (activeCall.callerDeviceId == uid &&
        activeCall.calleeDeviceId == CallSession.childWallDeviceId) {
      return context.t.childWall;
    }
    if (activeCall.calleeDeviceId == uid) {
      return context.t.childWall;
    }
    return contact?.displayName ?? context.t.family;
  }

  String _sessionIdFor(CallSession call) {
    return '${call.id}-${call.createdAt.millisecondsSinceEpoch}';
  }
}

class _RelativeHeaderActions extends StatelessWidget {
  const _RelativeHeaderActions({required this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LanguageMenu(),
        if (onSignOut != null) ...[
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: strings.signOut,
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ],
    );
  }
}
