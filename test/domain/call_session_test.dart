import 'package:family_hearth/src/domain/call_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CallSession', () {
    test('marks active and transferring states as media-active', () {
      final requested = CallSession.requested(
        id: 'call-1',
        familyId: 'family',
        callerDeviceId: 'child',
        calleeDeviceId: 'grandma',
        activeEndpoint: CallEndpoint.childWall,
      );

      expect(requested.isActiveMedia, isFalse);
      expect(
        requested.copyWith(status: CallStatus.connecting).isActiveMedia,
        isTrue,
      );
      expect(
        requested.copyWith(status: CallStatus.active).isActiveMedia,
        isTrue,
      );
      expect(
        requested.copyWith(status: CallStatus.transferring).isActiveMedia,
        isTrue,
      );
    });

    test('can hand off the active endpoint without changing participants', () {
      final active = CallSession.requested(
        id: 'call-1',
        familyId: 'family',
        callerDeviceId: 'child',
        calleeDeviceId: 'grandma',
        activeEndpoint: CallEndpoint.childWall,
      ).copyWith(status: CallStatus.active);

      final handedOff = active.copyWith(
        activeEndpoint: CallEndpoint.parentPhone,
      );

      expect(handedOff.callerDeviceId, active.callerDeviceId);
      expect(handedOff.calleeDeviceId, active.calleeDeviceId);
      expect(handedOff.activeEndpoint, CallEndpoint.parentPhone);
    });

    test('recognizes a family member request to the child wall', () {
      final request = CallSession.requested(
        id: 'call-2',
        familyId: 'family',
        callerDeviceId: 'grandma-uid',
        calleeDeviceId: CallSession.childWallDeviceId,
        activeEndpoint: CallEndpoint.childWall,
      ).copyWith(status: CallStatus.awaitingParentApproval);

      expect(request.isCallingChildWall, isTrue);
      expect(request.isActiveMedia, isFalse);
      expect(request.status.needsParentAction, isTrue);
      expect(request.involvesDevice('grandma-uid'), isTrue);
      expect(request.involvesDevice('aunt-uid'), isFalse);
    });
  });
}
