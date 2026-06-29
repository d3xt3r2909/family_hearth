class FamilyProfile {
  const FamilyProfile({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.wallPairingCode,
    required this.childWallActive,
  });

  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;
  final String wallPairingCode;
  final bool childWallActive;

  FamilyProfile copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? inviteCode,
    String? wallPairingCode,
    bool? childWallActive,
  }) {
    return FamilyProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      inviteCode: inviteCode ?? this.inviteCode,
      wallPairingCode: wallPairingCode ?? this.wallPairingCode,
      childWallActive: childWallActive ?? this.childWallActive,
    );
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'ownerId': ownerId,
    'inviteCode': inviteCode,
    'wallPairingCode': wallPairingCode,
    'childWallActive': childWallActive,
  };

  static FamilyProfile fromJson(String id, Map<String, Object?> json) {
    return FamilyProfile(
      id: id,
      name: json['name'] as String? ?? 'Family Hearth',
      ownerId: json['ownerId'] as String? ?? '',
      inviteCode: json['inviteCode'] as String? ?? '',
      wallPairingCode: json['wallPairingCode'] as String? ?? '',
      childWallActive: json['childWallActive'] as bool? ?? true,
    );
  }
}
