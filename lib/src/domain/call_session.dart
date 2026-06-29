enum CallStatus {
  idle,
  requested,
  awaitingParentApproval,
  ringing,
  connecting,
  active,
  transferring,
  rejected,
  expired,
  ended;

  bool get isTerminal => switch (this) {
    CallStatus.rejected || CallStatus.expired || CallStatus.ended => true,
    _ => false,
  };

  bool get needsParentAction => this == CallStatus.awaitingParentApproval;
}

enum CallEndpoint {
  childWall,
  parentPhone,
  relativeDevice;

  String get label => switch (this) {
    CallEndpoint.childWall => 'Child wall',
    CallEndpoint.parentPhone => 'Parent phone',
    CallEndpoint.relativeDevice => 'Relative',
  };
}

class CallSession {
  const CallSession({
    required this.id,
    required this.familyId,
    required this.callerDeviceId,
    required this.calleeDeviceId,
    required this.status,
    required this.activeEndpoint,
    required this.createdAt,
    this.updatedAt,
  });

  static const childWallDeviceId = 'child-wall';
  static const parentPhoneDeviceId = 'parent-phone';

  final String id;
  final String familyId;
  final String callerDeviceId;
  final String calleeDeviceId;
  final CallStatus status;
  final CallEndpoint activeEndpoint;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory CallSession.idle() {
    return CallSession(
      id: 'idle',
      familyId: 'demo-family',
      callerDeviceId: '',
      calleeDeviceId: '',
      status: CallStatus.idle,
      activeEndpoint: CallEndpoint.childWall,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory CallSession.requested({
    required String id,
    required String familyId,
    required String callerDeviceId,
    required String calleeDeviceId,
    required CallEndpoint activeEndpoint,
  }) {
    final now = DateTime.now();
    return CallSession(
      id: id,
      familyId: familyId,
      callerDeviceId: callerDeviceId,
      calleeDeviceId: calleeDeviceId,
      status: CallStatus.requested,
      activeEndpoint: activeEndpoint,
      createdAt: now,
      updatedAt: now,
    );
  }

  bool get isActiveMedia => switch (status) {
    CallStatus.connecting ||
    CallStatus.active ||
    CallStatus.transferring => true,
    _ => false,
  };

  bool get isCallingChildWall =>
      calleeDeviceId == childWallDeviceId && callerDeviceId.isNotEmpty;

  bool involvesDevice(String? deviceId) {
    if (deviceId == null || deviceId.isEmpty) {
      return true;
    }
    return callerDeviceId == deviceId || calleeDeviceId == deviceId;
  }

  CallSession copyWith({
    String? id,
    String? familyId,
    String? callerDeviceId,
    String? calleeDeviceId,
    CallStatus? status,
    CallEndpoint? activeEndpoint,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CallSession(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      callerDeviceId: callerDeviceId ?? this.callerDeviceId,
      calleeDeviceId: calleeDeviceId ?? this.calleeDeviceId,
      status: status ?? this.status,
      activeEndpoint: activeEndpoint ?? this.activeEndpoint,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toJson() => {
    'familyId': familyId,
    'callerDeviceId': callerDeviceId,
    'calleeDeviceId': calleeDeviceId,
    'status': status.name,
    'activeEndpoint': activeEndpoint.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static CallSession fromJson(String id, Map<String, Object?> json) {
    return CallSession(
      id: id,
      familyId: json['familyId'] as String? ?? '',
      callerDeviceId: json['callerDeviceId'] as String? ?? '',
      calleeDeviceId: json['calleeDeviceId'] as String? ?? '',
      status: CallStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => CallStatus.idle,
      ),
      activeEndpoint: CallEndpoint.values.firstWhere(
        (endpoint) => endpoint.name == json['activeEndpoint'],
        orElse: () => CallEndpoint.childWall,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}
