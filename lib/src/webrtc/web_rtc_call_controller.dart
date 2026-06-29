import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'firestore_signaling_service.dart';

enum WebRtcCallPhase {
  idle,
  openingMedia,
  creatingPeer,
  waitingForPeer,
  connecting,
  connected,
  ended,
  failed;

  String get label => switch (this) {
    WebRtcCallPhase.idle => 'Ready',
    WebRtcCallPhase.openingMedia => 'Opening camera',
    WebRtcCallPhase.creatingPeer => 'Preparing call',
    WebRtcCallPhase.waitingForPeer => 'Waiting for family',
    WebRtcCallPhase.connecting => 'Connecting',
    WebRtcCallPhase.connected => 'Connected',
    WebRtcCallPhase.ended => 'Ended',
    WebRtcCallPhase.failed => 'Needs attention',
  };
}

class WebRtcCallController extends ChangeNotifier {
  WebRtcCallController({
    required this.signaling,
    required this.familyId,
    required this.roomId,
    required this.sessionId,
    required this.role,
  });

  static const googleStunConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
  };

  final FirestoreSignalingService signaling;
  final String familyId;
  final String roomId;
  final String sessionId;
  final WebRtcPeerRole role;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  WebRtcCallPhase _phase = WebRtcCallPhase.idle;
  String? _errorMessage;
  bool _started = false;
  bool _disposed = false;
  bool _remoteDescriptionSet = false;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamSubscription<RTCSessionDescription?>? _descriptionSubscription;
  StreamSubscription<RTCIceCandidate>? _candidateSubscription;

  WebRtcCallPhase get phase => _phase;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _phase == WebRtcCallPhase.connected;
  bool get hasRemoteVideo => remoteRenderer.srcObject != null;

  Future<void> start() async {
    if (_started || _disposed) {
      return;
    }
    _started = true;

    try {
      _setPhase(WebRtcCallPhase.openingMedia);
      await localRenderer.initialize();
      await remoteRenderer.initialize();

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 960},
          'height': {'ideal': 540},
        },
      });
      localRenderer.srcObject = _localStream;

      _setPhase(WebRtcCallPhase.creatingPeer);
      final peerConnection = await createPeerConnection(
        Map<String, dynamic>.from(googleStunConfiguration),
      );
      _peerConnection = peerConnection;
      _attachPeerCallbacks(peerConnection);

      for (final track in _localStream!.getTracks()) {
        await peerConnection.addTrack(track, _localStream!);
      }

      _candidateSubscription = signaling
          .watchRemoteCandidates(
            familyId: familyId,
            roomId: roomId,
            sessionId: sessionId,
            role: role,
          )
          .listen((candidate) async {
            try {
              await _peerConnection?.addCandidate(candidate);
            } on Object catch (error) {
              _setError('Could not add remote candidate: $error');
            }
          });

      if (role == WebRtcPeerRole.caller) {
        await _startCaller(peerConnection);
      } else {
        await _startCallee(peerConnection);
      }
    } on Object catch (error) {
      _setError('WebRTC start failed: $error');
    }
  }

  Future<void> end() async {
    if (_disposed) {
      return;
    }

    await _descriptionSubscription?.cancel();
    await _candidateSubscription?.cancel();
    _descriptionSubscription = null;
    _candidateSubscription = null;

    await _peerConnection?.close();
    await _peerConnection?.dispose();
    _peerConnection = null;

    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
    }
    _localStream = null;

    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    _setPhase(WebRtcCallPhase.ended);
  }

  Future<void> disposeController() async {
    if (_disposed) {
      return;
    }
    await end();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    _disposed = true;
  }

  Future<void> _startCaller(RTCPeerConnection peerConnection) async {
    _setPhase(WebRtcCallPhase.connecting);
    final offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);
    await signaling.setOffer(
      familyId: familyId,
      roomId: roomId,
      sessionId: sessionId,
      offer: offer,
    );

    _descriptionSubscription = signaling
        .watchAnswer(familyId: familyId, roomId: roomId, sessionId: sessionId)
        .where((answer) => answer != null)
        .listen((answer) async {
          if (_remoteDescriptionSet || answer == null) {
            return;
          }
          try {
            await peerConnection.setRemoteDescription(answer);
            _remoteDescriptionSet = true;
            _setPhase(WebRtcCallPhase.connecting);
          } on Object catch (error) {
            _setError('Could not accept answer: $error');
          }
        });

    _setPhase(WebRtcCallPhase.waitingForPeer);
  }

  Future<void> _startCallee(RTCPeerConnection peerConnection) async {
    _setPhase(WebRtcCallPhase.waitingForPeer);
    _descriptionSubscription = signaling
        .watchOffer(familyId: familyId, roomId: roomId, sessionId: sessionId)
        .where((offer) => offer != null)
        .listen((offer) async {
          if (_remoteDescriptionSet || offer == null) {
            return;
          }
          try {
            _setPhase(WebRtcCallPhase.connecting);
            await peerConnection.setRemoteDescription(offer);
            _remoteDescriptionSet = true;
            final answer = await peerConnection.createAnswer();
            await peerConnection.setLocalDescription(answer);
            await signaling.setAnswer(
              familyId: familyId,
              roomId: roomId,
              sessionId: sessionId,
              answer: answer,
            );
          } on Object catch (error) {
            _setError('Could not answer call: $error');
          }
        });
  }

  void _attachPeerCallbacks(RTCPeerConnection peerConnection) {
    peerConnection.onIceCandidate = (candidate) {
      if (candidate.candidate == null) {
        return;
      }
      unawaited(
        signaling.addCandidate(
          familyId: familyId,
          roomId: roomId,
          sessionId: sessionId,
          role: role,
          candidate: candidate,
        ),
      );
    };

    peerConnection.onTrack = (event) {
      if (event.streams.isEmpty) {
        return;
      }
      remoteRenderer.srcObject = event.streams.first;
      _setPhase(WebRtcCallPhase.connected);
    };

    peerConnection.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _setPhase(WebRtcCallPhase.connected);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _setError('Peer connection failed');
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _setPhase(WebRtcCallPhase.connecting);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _setPhase(WebRtcCallPhase.ended);
      }
    };
  }

  void _setPhase(WebRtcCallPhase phase) {
    if (_disposed || _phase == phase) {
      return;
    }
    _phase = phase;
    notifyListeners();
  }

  void _setError(String message) {
    if (_disposed) {
      return;
    }
    _errorMessage = message;
    _phase = WebRtcCallPhase.failed;
    notifyListeners();
  }
}
