import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../domain/call_session.dart';
import '../domain/family_contact.dart';
import '../domain/family_membership.dart';
import '../domain/family_profile.dart';
import '../domain/family_stats.dart';
import '../domain/play_session.dart';
import '../domain/schedule_window.dart';
import 'demo_family_data.dart';

abstract interface class FamilyRepository {
  Stream<List<FamilyMembership>> watchUserFamilies(String uid);
  Stream<FamilyProfile?> watchFamilyProfile(String familyId);
  Stream<List<FamilyMember>> watchMembers(String familyId);
  Stream<List<FamilyContact>> watchContacts(String familyId);
  Stream<List<ScheduleWindow>> watchSchedules(String familyId);
  Stream<List<FamilyStatsEntry>> watchStats(String familyId);
  Stream<CallSession?> watchCall(String familyId, String callId);
  Stream<PlaySession?> watchPlaySession(String familyId, String playSessionId);
  Future<FamilyMembership> createFamily({
    required String uid,
    required String email,
    required String displayName,
    required String familyName,
  });
  Future<FamilyMembership> joinFamilyWithInvite({
    required String uid,
    required String email,
    required String displayName,
    required String inviteCode,
    required FamilyRole role,
  });
  Future<void> saveCall(CallSession call);
  Future<void> savePlaySession(PlaySession session);
  Future<void> setChildWallActive({
    required String familyId,
    required bool active,
  });
  Future<void> resetFamilySpace({
    required FamilyProfile profile,
    required String currentUid,
  });
  Future<void> updateMemberProfile({
    required String familyId,
    required FamilyMember member,
    required String displayName,
    required String familyTag,
  });
  Future<void> removeMember({
    required String familyId,
    required FamilyMember member,
    required String currentUid,
  });
  Future<void> approveMember({
    required String familyId,
    required FamilyMember member,
  });
  Future<void> rejectMember({
    required String familyId,
    required FamilyMember member,
  });
  Future<void> setContactAllowed({
    required String familyId,
    required String contactId,
    required bool allowed,
  });
  Future<void> recordStatsEntry(String familyId, FamilyStatsEntry entry);
}

class FirestoreFamilyRepository implements FamilyRepository {
  FirestoreFamilyRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> _families() {
    return _firestore.collection('families');
  }

  CollectionReference<Map<String, dynamic>> _userFamilies(String uid) {
    return _firestore.collection('users').doc(uid).collection('families');
  }

  CollectionReference<Map<String, dynamic>> _subcollection(
    String familyId,
    String name,
  ) {
    return _families().doc(familyId).collection(name);
  }

  @override
  Stream<List<FamilyMembership>> watchUserFamilies(String uid) {
    return _userFamilies(uid)
        .orderBy('familyName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FamilyMembership.fromJson(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  @override
  Stream<FamilyProfile?> watchFamilyProfile(String familyId) {
    return _families().doc(familyId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return FamilyProfile.fromJson(doc.id, data);
    });
  }

  @override
  Stream<List<FamilyMember>> watchMembers(String familyId) {
    return _subcollection(familyId, 'members')
        .orderBy('joinedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FamilyMember.fromJson(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<FamilyContact>> watchContacts(String familyId) {
    return _subcollection(familyId, 'contacts')
        .orderBy('displayName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FamilyContact.fromJson(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<ScheduleWindow>> watchSchedules(String familyId) {
    return _subcollection(familyId, 'schedules')
        .orderBy('startMinute')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ScheduleWindow.fromJson(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<FamilyStatsEntry>> watchStats(String familyId) {
    return _subcollection(familyId, 'stats')
        .orderBy('occurredAt', descending: true)
        .limit(250)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FamilyStatsEntry.fromJson(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  @override
  Stream<CallSession?> watchCall(String familyId, String callId) {
    return _subcollection(familyId, 'calls').doc(callId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return CallSession.fromJson(doc.id, data);
    });
  }

  @override
  Stream<PlaySession?> watchPlaySession(String familyId, String playSessionId) {
    return _subcollection(
      familyId,
      'playSessions',
    ).doc(playSessionId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return PlaySession.fromJson(doc.id, data);
    });
  }

  @override
  Future<FamilyMembership> createFamily({
    required String uid,
    required String email,
    required String displayName,
    required String familyName,
  }) async {
    final familyRef = _families().doc();
    final now = DateTime.now();
    final normalizedName = familyName.trim().isEmpty
        ? 'Family Hearth'
        : familyName.trim();
    final inviteCode = _newCode();
    final wallPairingCode = _newCode();
    final profile = FamilyProfile(
      id: familyRef.id,
      name: normalizedName,
      ownerId: uid,
      inviteCode: inviteCode,
      wallPairingCode: wallPairingCode,
      childWallActive: true,
    );
    final member = FamilyMember(
      uid: uid,
      displayName: _safeDisplayName(displayName, email),
      email: email,
      role: FamilyRole.parent,
      status: FamilyMemberStatus.approved,
      joinedAt: now,
    );
    final membership = FamilyMembership(
      familyId: familyRef.id,
      familyName: normalizedName,
      role: FamilyRole.parent,
      status: FamilyMemberStatus.approved,
      joinedAt: now,
    );

    await familyRef.set({
      ...profile.toJson(),
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
    await familyRef.collection('members').doc(uid).set(member.toJson());
    await _userFamilies(uid).doc(familyRef.id).set(membership.toJson());
    await _seedStarterFamilyData(familyRef);
    await _writeInvite(
      code: inviteCode,
      familyId: familyRef.id,
      familyName: normalizedName,
      createdBy: uid,
      roleHint: FamilyRole.relative,
    );
    await _writeInvite(
      code: wallPairingCode,
      familyId: familyRef.id,
      familyName: normalizedName,
      createdBy: uid,
      roleHint: FamilyRole.childWall,
    );

    return membership;
  }

  @override
  Future<FamilyMembership> joinFamilyWithInvite({
    required String uid,
    required String email,
    required String displayName,
    required String inviteCode,
    required FamilyRole role,
  }) async {
    final normalizedCode = _normalizeCode(inviteCode);
    final invite = await _firestore
        .collection('invites')
        .doc(normalizedCode)
        .get();
    final inviteData = invite.data();
    if (inviteData == null) {
      throw StateError('Invite code was not found.');
    }

    final familyId = inviteData['familyId'] as String? ?? '';
    final familyName = inviteData['familyName'] as String? ?? 'Family Hearth';
    if (familyId.isEmpty) {
      throw StateError('Invite code is missing a family.');
    }

    final now = DateTime.now();
    final member = FamilyMember(
      uid: uid,
      displayName: _safeDisplayName(displayName, email),
      email: email,
      role: role,
      status: FamilyMemberStatus.pending,
      joinedAt: now,
      inviteCode: normalizedCode,
    );
    final membership = FamilyMembership(
      familyId: familyId,
      familyName: familyName,
      role: role,
      status: FamilyMemberStatus.pending,
      joinedAt: now,
    );

    await _subcollection(familyId, 'members').doc(uid).set(member.toJson());
    await _userFamilies(uid).doc(familyId).set(membership.toJson());
    return membership;
  }

  @override
  Future<void> saveCall(CallSession call) {
    return _subcollection(
      call.familyId,
      'calls',
    ).doc(call.id).set(call.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> savePlaySession(PlaySession session) {
    return _subcollection(
      session.familyId,
      'playSessions',
    ).doc(session.id).set(session.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> setChildWallActive({
    required String familyId,
    required bool active,
  }) {
    return _families().doc(familyId).set({
      'childWallActive': active,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> resetFamilySpace({
    required FamilyProfile profile,
    required String currentUid,
  }) async {
    final familyRef = _families().doc(profile.id);
    final members = await _subcollection(profile.id, 'members').get();
    final calls = await _subcollection(profile.id, 'calls').get();

    for (final call in calls.docs) {
      await _deleteCollection(call.reference.collection('callerCandidates'));
      await _deleteCollection(call.reference.collection('calleeCandidates'));
    }

    await _deleteCollection(_subcollection(profile.id, 'contacts'));
    await _deleteCollection(_subcollection(profile.id, 'schedules'));
    await _deleteCollection(_subcollection(profile.id, 'stats'));
    await _deleteCollection(_subcollection(profile.id, 'playSessions'));
    await _deleteDocuments(calls.docs.map((doc) => doc.reference));

    for (final memberDoc in members.docs) {
      if (memberDoc.id == currentUid) {
        await memberDoc.reference.set({
          'status': FamilyMemberStatus.approved.name,
          'role': FamilyRole.parent.name,
        }, SetOptions(merge: true));
        continue;
      }

      await _userFamilies(memberDoc.id).doc(profile.id).delete();
      await memberDoc.reference.delete();
    }

    if (profile.inviteCode.isNotEmpty) {
      await _firestore.collection('invites').doc(profile.inviteCode).delete();
    }
    if (profile.wallPairingCode.isNotEmpty) {
      await _firestore
          .collection('invites')
          .doc(profile.wallPairingCode)
          .delete();
    }

    final newInviteCode = _newCode();
    final newWallPairingCode = _newCode();
    await familyRef.set({
      'inviteCode': newInviteCode,
      'wallPairingCode': newWallPairingCode,
      'childWallActive': false,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
    await _writeInvite(
      code: newInviteCode,
      familyId: profile.id,
      familyName: profile.name,
      createdBy: currentUid,
      roleHint: FamilyRole.relative,
    );
    await _writeInvite(
      code: newWallPairingCode,
      familyId: profile.id,
      familyName: profile.name,
      createdBy: currentUid,
      roleHint: FamilyRole.childWall,
    );
  }

  @override
  Future<void> updateMemberProfile({
    required String familyId,
    required FamilyMember member,
    required String displayName,
    required String familyTag,
  }) async {
    final normalizedName = _safeDisplayName(displayName, member.email);
    final normalizedTag = _safeFamilyTag(familyTag);
    final updatedMember = FamilyMember(
      uid: member.uid,
      displayName: normalizedName,
      email: member.email,
      role: member.role,
      status: member.status,
      joinedAt: member.joinedAt,
      familyTag: normalizedTag,
      inviteCode: member.inviteCode,
    );

    await _subcollection(familyId, 'members').doc(member.uid).set({
      'displayName': normalizedName,
      'familyTag': normalizedTag,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    if (member.role == FamilyRole.relative &&
        member.status == FamilyMemberStatus.approved) {
      await _syncContactForMember(familyId, updatedMember);
    }
  }

  @override
  Future<void> removeMember({
    required String familyId,
    required FamilyMember member,
    required String currentUid,
  }) async {
    if (member.uid == currentUid) {
      throw StateError('You cannot remove your own parent account here.');
    }

    await _userFamilies(member.uid).doc(familyId).delete();
    await _subcollection(familyId, 'contacts').doc(member.uid).delete();
    await _subcollection(familyId, 'members').doc(member.uid).delete();
  }

  @override
  Future<void> approveMember({
    required String familyId,
    required FamilyMember member,
  }) async {
    await _subcollection(familyId, 'members').doc(member.uid).set({
      'status': FamilyMemberStatus.approved.name,
      'approvedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
    await _userFamilies(member.uid).doc(familyId).set({
      'status': FamilyMemberStatus.approved.name,
    }, SetOptions(merge: true));

    if (member.role == FamilyRole.relative) {
      await _syncContactForMember(familyId, member);
    }
  }

  @override
  Future<void> rejectMember({
    required String familyId,
    required FamilyMember member,
  }) async {
    await _subcollection(familyId, 'members').doc(member.uid).set({
      'status': FamilyMemberStatus.rejected.name,
      'rejectedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
    await _userFamilies(member.uid).doc(familyId).set({
      'status': FamilyMemberStatus.rejected.name,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setContactAllowed({
    required String familyId,
    required String contactId,
    required bool allowed,
  }) {
    return _subcollection(familyId, 'contacts').doc(contactId).set({
      'isManuallyAllowed': allowed,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> recordStatsEntry(String familyId, FamilyStatsEntry entry) {
    return _subcollection(familyId, 'stats').doc(entry.id).set(entry.toJson());
  }

  Future<void> _seedStarterFamilyData(
    DocumentReference<Map<String, dynamic>> familyRef,
  ) async {
    for (final schedule in DemoFamilyData.schedules) {
      await familyRef
          .collection('schedules')
          .doc(schedule.id)
          .set(schedule.toJson(), SetOptions(merge: true));
    }
  }

  Future<void> _writeInvite({
    required String code,
    required String familyId,
    required String familyName,
    required String createdBy,
    required FamilyRole roleHint,
  }) {
    final now = DateTime.now();
    return _firestore.collection('invites').doc(code).set({
      'familyId': familyId,
      'familyName': familyName,
      'createdBy': createdBy,
      'roleHint': roleHint.name,
      'createdAt': now.toIso8601String(),
      'isActive': true,
    });
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
    await _deleteDocuments(snapshot.docs.map((doc) => doc.reference));
  }

  Future<void> _deleteDocuments(
    Iterable<DocumentReference<Map<String, dynamic>>> references,
  ) async {
    final refs = references.toList(growable: false);
    for (var index = 0; index < refs.length; index += 450) {
      final batch = _firestore.batch();
      for (final ref in refs.skip(index).take(450)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  Future<void> _syncContactForMember(
    String familyId,
    FamilyMember member,
  ) async {
    final contact = _contactForMember(member);
    await _subcollection(familyId, 'contacts').doc(member.uid).set({
      'displayName': contact.displayName,
      'relationship': contact.relationship,
      'avatarText': contact.avatarText,
      'accentColorValue': contact.accentColorValue,
    }, SetOptions(merge: true));
  }

  static FamilyContact _contactForMember(FamilyMember member) {
    return FamilyContact(
      id: member.uid,
      displayName: member.displayName,
      relationship: _relationshipForMember(member),
      avatarText: _initialsFor(member.displayName, member.email),
      accentColorValue: _accentFor(member.uid),
    );
  }

  static String _newCode() {
    return _uuid.v4().replaceAll('-', '').substring(0, 8).toUpperCase();
  }

  static String _normalizeCode(String code) {
    return code.trim().replaceAll('-', '').replaceAll(' ', '').toUpperCase();
  }

  static String _safeDisplayName(String displayName, String email) {
    final trimmed = displayName.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    final emailName = email.split('@').first.trim();
    return emailName.isEmpty ? 'Family' : emailName;
  }

  static String _safeFamilyTag(String familyTag) {
    return familyTag.trim();
  }

  static String _relationshipForMember(FamilyMember member) {
    final tag = member.familyTag.trim();
    return tag.isNotEmpty ? tag : _relationshipFor(member.displayName);
  }

  static String _relationshipFor(String displayName) {
    final lower = displayName.toLowerCase();
    if (lower.contains('grandma') ||
        lower.contains('nana') ||
        lower.contains('baka')) {
      return 'Grandma';
    }
    if (lower.contains('grandpa') ||
        lower.contains('dedo') ||
        lower.contains('deda')) {
      return 'Grandpa';
    }
    if (lower.contains('aunt') || lower.contains('tetka')) {
      return 'Aunt';
    }
    if (lower.contains('uncle') || lower.contains('amid')) {
      return 'Uncle';
    }
    return 'Family';
  }

  static String _initialsFor(String displayName, String email) {
    final source = displayName.trim().isEmpty
        ? email.split('@').first
        : displayName;
    final parts = source
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'FH';
    }
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static int _accentFor(String uid) {
    const palette = [
      0xFFE85D43,
      0xFF197A6E,
      0xFFFFB545,
      0xFF4967B1,
      0xFFB34D8A,
      0xFF7C6A3D,
      0xFF2F8C9D,
      0xFF8B5FBF,
    ];
    final hash = uid.codeUnits.fold<int>(0, (value, unit) => value + unit);
    return palette[hash % palette.length];
  }
}
