import '../domain/call_session.dart';
import '../domain/family_contact.dart';
import '../domain/family_stats.dart';

abstract interface class CallCapability {
  Future<void> startPairCall(FamilyContact contact);
  Future<void> handoffTo(CallEndpoint endpoint);
  Future<void> hangUp();
}

abstract interface class ChildSurfaceCapability {
  Future<void> setActiveContacts(List<String> contactIds);
  Future<void> dim();
  Future<void> wakeForParentStartedCall(String contactId);
}

abstract interface class InteractionCapability {
  Future<void> receiveRemoteColor(String colorHex);
  Future<void> receiveLearningPrompt(String promptId);
}

abstract interface class AmbientOutputCapability {
  Future<void> showOnScreenEffect(String effectId);
  Future<void> sendLedEffect(String effectId);
}

abstract interface class CameraRigCapability {
  Future<void> useFixedCamera();
  Future<void> followRoomPreset(String presetId);
  Future<void> stopMotion();
}

abstract interface class StatsCapability {
  Future<void> record(FamilyStatsEntry entry);
  Stream<FamilyStatsSummary> watchSummary(String familyId);
}
