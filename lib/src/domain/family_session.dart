import 'family_membership.dart';
import 'family_profile.dart';

class FamilySession {
  const FamilySession({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.membership,
    required this.profile,
  });

  final String uid;
  final String email;
  final String displayName;
  final FamilyMembership membership;
  final FamilyProfile profile;

  String get familyId => profile.id;
  String get familyName => profile.name;
  FamilyRole get role => membership.role;
}
