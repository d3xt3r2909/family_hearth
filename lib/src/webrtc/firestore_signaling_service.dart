import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum WebRtcPeerRole {
  caller,
  callee;

  String get localCandidateCollection => switch (this) {
    WebRtcPeerRole.caller => 'callerCandidates',
    WebRtcPeerRole.callee => 'calleeCandidates',
  };

  String get remoteCandidateCollection => switch (this) {
    WebRtcPeerRole.caller => 'calleeCandidates',
    WebRtcPeerRole.callee => 'callerCandidates',
  };
}

class FirestoreSignalingService {
  FirestoreSignalingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _roomRef({
    required String familyId,
    required String roomId,
  }) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('calls')
        .doc(roomId);
  }

  Future<void> setOffer({
    required String familyId,
    required String roomId,
    required String sessionId,
    required RTCSessionDescription offer,
  }) {
    return _roomRef(familyId: familyId, roomId: roomId).set({
      'rtcSessionId': sessionId,
      'offer': _descriptionToJson(offer),
      'answer': FieldValue.delete(),
      'rtcUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<RTCSessionDescription?> watchOffer({
    required String familyId,
    required String roomId,
    required String sessionId,
  }) {
    return _roomRef(familyId: familyId, roomId: roomId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || data['rtcSessionId'] != sessionId) {
        return null;
      }
      return _descriptionFromJson(data['offer']);
    });
  }

  Future<void> setAnswer({
    required String familyId,
    required String roomId,
    required String sessionId,
    required RTCSessionDescription answer,
  }) {
    return _roomRef(familyId: familyId, roomId: roomId).set({
      'rtcSessionId': sessionId,
      'answer': _descriptionToJson(answer),
      'rtcUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<RTCSessionDescription?> watchAnswer({
    required String familyId,
    required String roomId,
    required String sessionId,
  }) {
    return _roomRef(familyId: familyId, roomId: roomId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || data['rtcSessionId'] != sessionId) {
        return null;
      }
      return _descriptionFromJson(data['answer']);
    });
  }

  Future<void> addCandidate({
    required String familyId,
    required String roomId,
    required String sessionId,
    required WebRtcPeerRole role,
    required RTCIceCandidate candidate,
  }) {
    return _roomRef(
      familyId: familyId,
      roomId: roomId,
    ).collection(role.localCandidateCollection).add({
      ..._candidateToJson(candidate),
      'sessionId': sessionId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<RTCIceCandidate> watchRemoteCandidates({
    required String familyId,
    required String roomId,
    required String sessionId,
    required WebRtcPeerRole role,
  }) {
    return _roomRef(familyId: familyId, roomId: roomId)
        .collection(role.remoteCandidateCollection)
        .snapshots()
        .expand((snapshot) => snapshot.docChanges)
        .where((change) => change.type == DocumentChangeType.added)
        .map((change) => change.doc.data())
        .where((data) => data != null)
        .cast<Map<String, dynamic>>()
        .where((data) => data['sessionId'] == sessionId)
        .map(_candidateFromJson);
  }

  Map<String, Object?> _descriptionToJson(RTCSessionDescription description) {
    return {'type': description.type, 'sdp': description.sdp};
  }

  RTCSessionDescription? _descriptionFromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final data = Map<String, Object?>.from(value);
    final sdp = data['sdp'] as String?;
    final type = data['type'] as String?;
    if (sdp == null || type == null) {
      return null;
    }
    return RTCSessionDescription(sdp, type);
  }

  Map<String, Object?> _candidateToJson(RTCIceCandidate candidate) {
    return {
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    };
  }

  RTCIceCandidate _candidateFromJson(Map<String, dynamic> data) {
    return RTCIceCandidate(
      data['candidate'] as String?,
      data['sdpMid'] as String?,
      data['sdpMLineIndex'] as int?,
    );
  }
}
