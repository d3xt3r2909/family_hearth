import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../i18n/app_localizations.dart';
import '../../webrtc/firestore_signaling_service.dart';
import '../../webrtc/web_rtc_call_controller.dart';

class WebRtcCallView extends StatefulWidget {
  const WebRtcCallView({
    super.key,
    required this.firebaseReady,
    required this.familyId,
    required this.roomId,
    required this.sessionId,
    required this.role,
    required this.title,
    required this.accent,
    required this.onEndCall,
  });

  final bool firebaseReady;
  final String familyId;
  final String roomId;
  final String sessionId;
  final WebRtcPeerRole role;
  final String title;
  final Color accent;
  final VoidCallback onEndCall;

  @override
  State<WebRtcCallView> createState() => _WebRtcCallViewState();
}

class _WebRtcCallViewState extends State<WebRtcCallView> {
  WebRtcCallController? _controller;

  @override
  void initState() {
    super.initState();
    _startIfPossible();
  }

  @override
  void didUpdateWidget(covariant WebRtcCallView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.firebaseReady != widget.firebaseReady ||
        oldWidget.familyId != widget.familyId ||
        oldWidget.roomId != widget.roomId ||
        oldWidget.sessionId != widget.sessionId ||
        oldWidget.role != widget.role) {
      _disposeController();
      _startIfPossible();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _startIfPossible() {
    if (!widget.firebaseReady) {
      return;
    }

    final controller = WebRtcCallController(
      signaling: FirestoreSignalingService(),
      familyId: widget.familyId,
      roomId: widget.roomId,
      sessionId: widget.sessionId,
      role: widget.role,
    );
    _controller = controller;
    unawaited(controller.start());
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(controller.disposeController());
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    if (!widget.firebaseReady) {
      return _CallUnavailable(
        accent: widget.accent,
        onEndCall: widget.onEndCall,
      );
    }

    final controller = _controller;
    if (controller == null) {
      return _CallUnavailable(
        accent: widget.accent,
        onEndCall: widget.onEndCall,
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Color(0xFF0F0D0B)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (controller.hasRemoteVideo)
                        RTCVideoView(
                          controller.remoteRenderer,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      else
                        _WaitingSurface(
                          title: widget.title,
                          phase: controller.phase,
                          message: controller.errorMessage,
                        ),
                      Positioned(
                        left: 14,
                        top: 14,
                        child: _StateBadge(
                          phase: controller.phase,
                          accent: widget.accent,
                        ),
                      ),
                      if (controller.localRenderer.srcObject != null)
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: _LocalPreview(
                            renderer: controller.localRenderer,
                            accent: widget.accent,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE02F2F),
                foregroundColor: Colors.white,
                minimumSize: const Size(220, 62),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: widget.onEndCall,
              icon: const Icon(Icons.call_end_rounded),
              label: Text(strings.hangUp),
            ),
          ],
        );
      },
    );
  }
}

class _WaitingSurface extends StatelessWidget {
  const _WaitingSurface({
    required this.title,
    required this.phase,
    required this.message,
  });

  final String title;
  final WebRtcCallPhase phase;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final failed = phase == WebRtcCallPhase.failed;
    final strings = context.t;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failed ? Icons.warning_rounded : Icons.video_camera_front_rounded,
              color: Colors.white,
              size: 74,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message ?? strings.webRtcPhaseLabel(phase),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.phase, required this.accent});

  final WebRtcCallPhase phase;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: phase == WebRtcCallPhase.connected
            ? const Color(0xFF0F7A5B)
            : accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 7),
          Text(
            strings.webRtcPhaseLabel(phase),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalPreview extends StatelessWidget {
  const _LocalPreview({required this.renderer, required this.accent});

  final RTCVideoRenderer renderer;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 172,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: RTCVideoView(
        renderer,
        mirror: true,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      ),
    );
  }
}

class _CallUnavailable extends StatelessWidget {
  const _CallUnavailable({required this.accent, required this.onEndCall});

  final Color accent;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.34)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, color: accent, size: 58),
                  const SizedBox(height: 14),
                  Text(
                    strings.firebaseSignalingOffline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF221B16),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.firebaseSignalingHelp,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6F6258),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE02F2F),
            foregroundColor: Colors.white,
            minimumSize: const Size(220, 62),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onEndCall,
          icon: const Icon(Icons.call_end_rounded),
          label: Text(strings.close),
        ),
      ],
    );
  }
}
