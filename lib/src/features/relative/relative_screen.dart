import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/call_session.dart';
import '../../domain/family_contact.dart';
import '../../domain/play_session.dart';
import '../../i18n/app_localizations.dart';
import '../../webrtc/firestore_signaling_service.dart';
import '../shared/camera_on_frame.dart';
import '../shared/family_hearth_mark.dart';
import '../shared/language_menu.dart';
import '../shared/sound_effects_toggle.dart';
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
    required this.onPlayBoardSticker,
    required this.onClearPlayBoard,
    required this.onClearPlay,
    required this.soundEffectsEnabled,
    required this.onSoundEffectsChanged,
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
  final ValueChanged<PlayBoardSticker> onPlayBoardSticker;
  final VoidCallback onClearPlayBoard;
  final VoidCallback onClearPlay;
  final bool soundEffectsEnabled;
  final ValueChanged<bool> onSoundEffectsChanged;
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
                child: _RelativeHeaderActions(
                  soundEffectsEnabled: soundEffectsEnabled,
                  onSoundEffectsChanged: onSoundEffectsChanged,
                  onSignOut: onSignOut,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 82, 22, 22),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      Widget buildPlayPanel({double? boardHeight}) {
                        return RelativePlayroomPanel(
                          enabled: childWallActive && firebaseReady,
                          session: playSession,
                          actorId: currentUserId ?? 'relative-device',
                          onSendPrompt: onSendPlayPrompt,
                          onBoardStroke: onPlayBoardStroke,
                          onBoardSticker: onPlayBoardSticker,
                          onClearBoard: onClearPlayBoard,
                          onClear: onClearPlay,
                          boardHeight: boardHeight,
                        );
                      }

                      if (hasCall) {
                        return _RelativeCallStage(
                          firebaseReady: firebaseReady,
                          familyId: familyId,
                          activeCall: activeCall,
                          contact: contact,
                          contactName: contactName,
                          role: _peerRoleForCall(),
                          sessionId: _sessionIdFor(activeCall),
                          onEndCall: onEndCall,
                          playPanelBuilder: buildPlayPanel,
                        );
                      }

                      final wide = constraints.maxWidth >= 980;
                      final statusPanel = _RelativeStatusPanel(
                        pendingForThisDevice: pendingForThisDevice,
                        canStartCall: canStartCall,
                        title: pendingForThisDevice
                            ? strings.callRequestSent
                            : strings.familyHearthReady,
                        statusText: statusText,
                        onStartCallToChild: onStartCallToChild,
                      );

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 5, child: statusPanel),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 7,
                              child: _RelativeSurface(child: buildPlayPanel()),
                            ),
                          ],
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            statusPanel,
                            const SizedBox(height: 18),
                            _RelativeSurface(child: buildPlayPanel()),
                          ],
                        ),
                      );
                    },
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

typedef _RelativePlayPanelBuilder = Widget Function({double? boardHeight});

enum _RelativeCallFocus { balanced, video, board }

class _RelativeCallStage extends StatefulWidget {
  const _RelativeCallStage({
    required this.firebaseReady,
    required this.familyId,
    required this.activeCall,
    required this.contact,
    required this.contactName,
    required this.role,
    required this.sessionId,
    required this.onEndCall,
    required this.playPanelBuilder,
  });

  final bool firebaseReady;
  final String familyId;
  final CallSession activeCall;
  final FamilyContact? contact;
  final String contactName;
  final WebRtcPeerRole role;
  final String sessionId;
  final VoidCallback onEndCall;
  final _RelativePlayPanelBuilder playPanelBuilder;

  @override
  State<_RelativeCallStage> createState() => _RelativeCallStageState();
}

class _RelativeCallStageState extends State<_RelativeCallStage> {
  _RelativeCallFocus _focus = _RelativeCallFocus.balanced;

  @override
  Widget build(BuildContext context) {
    final accent = Color(widget.contact?.accentColorValue ?? 0xFFE85D43);
    final callView = WebRtcCallView(
      firebaseReady: widget.firebaseReady,
      familyId: widget.familyId,
      roomId: widget.activeCall.id,
      sessionId: widget.sessionId,
      role: widget.role,
      title: context.t.connectedWith(widget.contactName),
      accent: accent,
      onEndCall: widget.onEndCall,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final focusControls = _RelativeFocusControls(
          focus: _focus,
          onChanged: (focus) => setState(() => _focus = focus),
        );

        if (!wide) {
          final boardBig = _focus == _RelativeCallFocus.board;
          final videoBig = _focus == _RelativeCallFocus.video;
          final boardHeight = boardBig
              ? math.max(300.0, constraints.maxHeight * 0.46)
              : null;

          return Column(
            children: [
              Align(alignment: Alignment.centerLeft, child: focusControls),
              const SizedBox(height: 10),
              Expanded(flex: boardBig ? 3 : 6, child: callView),
              const SizedBox(height: 14),
              Expanded(
                flex: videoBig ? 2 : 5,
                child: _RelativeFloatingSurface(
                  child: widget.playPanelBuilder(boardHeight: boardHeight),
                ),
              ),
            ],
          );
        }

        final panelWidth = switch (_focus) {
          _RelativeCallFocus.video => math.min(
            360.0,
            constraints.maxWidth * 0.28,
          ),
          _RelativeCallFocus.board => math.min(
            820.0,
            constraints.maxWidth * 0.64,
          ),
          _RelativeCallFocus.balanced => math.min(
            470.0,
            constraints.maxWidth * 0.36,
          ),
        };
        final boardHeight = _focus == _RelativeCallFocus.board
            ? math.max(420.0, constraints.maxHeight - 250)
            : null;

        return Stack(
          children: [
            Positioned.fill(child: callView),
            Positioned(top: 18, left: 18, child: focusControls),
            Positioned(
              top: 18,
              right: 18,
              bottom: 18,
              width: panelWidth,
              child: _RelativeFloatingSurface(
                child: widget.playPanelBuilder(boardHeight: boardHeight),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RelativeFocusControls extends StatelessWidget {
  const _RelativeFocusControls({required this.focus, required this.onChanged});

  final _RelativeCallFocus focus;
  final ValueChanged<_RelativeCallFocus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE3D8CD)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RelativeFocusButton(
              selected: focus == _RelativeCallFocus.balanced,
              tooltip: 'Balanced',
              icon: Icons.splitscreen_rounded,
              onPressed: () => onChanged(_RelativeCallFocus.balanced),
            ),
            _RelativeFocusButton(
              selected: focus == _RelativeCallFocus.video,
              tooltip: 'Expand video',
              icon: Icons.video_camera_front_rounded,
              onPressed: () => onChanged(_RelativeCallFocus.video),
            ),
            _RelativeFocusButton(
              selected: focus == _RelativeCallFocus.board,
              tooltip: 'Expand drawing',
              icon: Icons.draw_rounded,
              onPressed: () => onChanged(_RelativeCallFocus.board),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelativeFocusButton extends StatelessWidget {
  const _RelativeFocusButton({
    required this.selected,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final bool selected;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: selected ? const Color(0xFFE85D43) : Colors.white,
          foregroundColor: selected ? Colors.white : const Color(0xFF4B3D35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _RelativeStatusPanel extends StatelessWidget {
  const _RelativeStatusPanel({
    required this.pendingForThisDevice,
    required this.canStartCall,
    required this.title,
    required this.statusText,
    required this.onStartCallToChild,
  });

  final bool pendingForThisDevice;
  final bool canStartCall;
  final String title;
  final String statusText;
  final VoidCallback onStartCallToChild;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return _RelativeSurface(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 154,
                height: 154,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE2BF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE85D43), width: 3),
                ),
                child: const Center(
                  child: FamilyHearthMark(
                    size: 108,
                    color: Color(0xFFE85D43),
                    flameColor: Color(0xFFFFB545),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF221B16),
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6F6258),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE85D43),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(260, 66),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: canStartCall ? onStartCallToChild : null,
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
          ),
        ),
      ),
    );
  }
}

class _RelativeSurface extends StatelessWidget {
  const _RelativeSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE3D8CD)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}

class _RelativeFloatingSurface extends StatelessWidget {
  const _RelativeFloatingSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF7FFFFFF),
      elevation: 22,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE3D8CD)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class _RelativeHeaderActions extends StatelessWidget {
  const _RelativeHeaderActions({
    required this.soundEffectsEnabled,
    required this.onSoundEffectsChanged,
    required this.onSignOut,
  });

  final bool soundEffectsEnabled;
  final ValueChanged<bool> onSoundEffectsChanged;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SoundEffectsToggle(
          enabled: soundEffectsEnabled,
          onChanged: onSoundEffectsChanged,
        ),
        const SizedBox(width: 8),
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
