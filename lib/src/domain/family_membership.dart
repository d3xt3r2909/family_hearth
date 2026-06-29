import 'app_role.dart';

enum FamilyRole {
  parent,
  relative,
  childWall;

  String get label => switch (this) {
    FamilyRole.parent => 'Parent',
    FamilyRole.relative => 'Family',
    FamilyRole.childWall => 'Wall',
  };

  AppRole get appRole => switch (this) {
    FamilyRole.parent => AppRole.parent,
    FamilyRole.relative => AppRole.relative,
    FamilyRole.childWall => AppRole.childWall,
  };
}

enum FamilyMemberStatus {
  pending,
  approved,
  rejected;

  String get label => switch (this) {
    FamilyMemberStatus.pending => 'Waiting for parent',
    FamilyMemberStatus.approved => 'Approved',
    FamilyMemberStatus.rejected => 'Not approved',
  };
}

FamilyRole familyRoleFromName(String? value) {
  return FamilyRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => FamilyRole.relative,
  );
}

FamilyMemberStatus familyMemberStatusFromName(String? value) {
  return FamilyMemberStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => FamilyMemberStatus.approved,
  );
}

class FamilyMembership {
  const FamilyMembership({
    required this.familyId,
    required this.familyName,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  final String familyId;
  final String familyName;
  final FamilyRole role;
  final FamilyMemberStatus status;
  final DateTime joinedAt;

  Map<String, Object?> toJson() => {
    'familyId': familyId,
    'familyName': familyName,
    'role': role.name,
    'status': status.name,
    'joinedAt': joinedAt.toIso8601String(),
  };

  static FamilyMembership fromJson(String familyId, Map<String, Object?> json) {
    return FamilyMembership(
      familyId: json['familyId'] as String? ?? familyId,
      familyName: json['familyName'] as String? ?? 'Family Hearth',
      role: familyRoleFromName(json['role'] as String?),
      status: familyMemberStatusFromName(json['status'] as String?),
      joinedAt:
          DateTime.tryParse(json['joinedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class FamilyMember {
  const FamilyMember({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.familyTag = '',
    this.inviteCode,
  });

  final String uid;
  final String displayName;
  final String email;
  final FamilyRole role;
  final FamilyMemberStatus status;
  final DateTime joinedAt;
  final String familyTag;
  final String? inviteCode;

  Map<String, Object?> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'role': role.name,
    'status': status.name,
    'joinedAt': joinedAt.toIso8601String(),
    if (familyTag.isNotEmpty) 'familyTag': familyTag,
    if (inviteCode != null) 'inviteCode': inviteCode,
  };

  static FamilyMember fromJson(String uid, Map<String, Object?> json) {
    return FamilyMember(
      uid: json['uid'] as String? ?? uid,
      displayName: json['displayName'] as String? ?? 'Family',
      email: json['email'] as String? ?? '',
      role: familyRoleFromName(json['role'] as String?),
      status: familyMemberStatusFromName(json['status'] as String?),
      joinedAt:
          DateTime.tryParse(json['joinedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      familyTag: json['familyTag'] as String? ?? '',
      inviteCode: json['inviteCode'] as String?,
    );
  }
}
