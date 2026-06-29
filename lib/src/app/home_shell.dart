import 'dart:async';

import 'package:flutter/material.dart';

import '../data/demo_family_data.dart';
import '../data/family_repository.dart';
import '../domain/app_role.dart';
import '../domain/call_session.dart';
import '../domain/family_contact.dart';
import '../domain/family_membership.dart';
import '../domain/family_profile.dart';
import '../domain/family_session.dart';
import '../domain/family_stats.dart';
import '../domain/play_session.dart';
import '../domain/schedule_window.dart';
import '../features/child/child_wall_screen.dart';
import '../features/parent/parent_control_screen.dart';
import '../features/relative/relative_screen.dart';
import '../firebase/firebase_bootstrap.dart';
import '../i18n/app_localizations.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.firebaseStatus,
    this.session,
    this.onSignOut,
  });

  final FirebaseBootstrapResult firebaseStatus;
  final FamilySession? session;
  final VoidCallback? onSignOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final String _familyId =
      Uri.base.queryParameters['family'] ??
      widget.session?.familyId ??
      widget.firebaseStatus.userId ??
      'local-family';
  late final String _callRoomId =
      Uri.base.queryParameters['room'] ?? 'family-main-room';
  late final String _playRoomId =
      Uri.base.queryParameters['play'] ?? 'family-main-playroom';
  late AppRole _role = _initialRole();
  FamilyRepository? _repository;
  StreamSubscription<FamilyProfile?>? _profileSubscription;
  StreamSubscription<List<FamilyMember>>? _membersSubscription;
  StreamSubscription<List<FamilyContact>>? _contactsSubscription;
  StreamSubscription<List<ScheduleWindow>>? _schedulesSubscription;
  StreamSubscription<List<FamilyStatsEntry>>? _statsSubscription;
  StreamSubscription<CallSession?>? _callSubscription;
  StreamSubscription<PlaySession?>? _playSubscription;
  bool _childWallActive = true;
  bool _cameraOn = false;
  CallSession _call = DemoFamilyData.initialCall;
  late PlaySession _playSession;
  late List<FamilyMember> _members;
  late List<FamilyContact> _contacts;
  late List<ScheduleWindow> _schedules;
  late List<FamilyStatsEntry> _statsEvents;

  FamilyStatsSummary get _statsSummary =>
      FamilyStatsEngine.summarize(_statsEvents);

  String get _familyName =>
      widget.session?.profile.name ??
      widget.session?.familyName ??
      'Family Hearth';

  String get _inviteCode => widget.session?.profile.inviteCode ?? '';

  String get _wallPairingCode => widget.session?.profile.wallPairingCode ?? '';

  @override
  void initState() {
    super.initState();
    final usePreviewData = widget.session == null;
    _members = const [];
    _contacts = usePreviewData ? DemoFamilyData.contacts : const [];
    _schedules = usePreviewData ? DemoFamilyData.schedules : const [];
    _statsEvents = usePreviewData ? DemoFamilyData.statsEvents : const [];
    _playSession = PlaySession.idle(id: _playRoomId, familyId: _familyId);
    _childWallActive = widget.session?.profile.childWallActive ?? true;
    _repository = widget.firebaseStatus.isReady && widget.session != null
        ? FirestoreFamilyRepository()
        : null;
    _profileSubscription = _repository
        ?.watchFamilyProfile(_familyId)
        .listen(_applyRemoteProfile);
    _membersSubscription = _repository
        ?.watchMembers(_familyId)
        .listen(_applyRemoteMembers);
    _contactsSubscription = _repository
        ?.watchContacts(_familyId)
        .listen(_applyRemoteContacts);
    _schedulesSubscription = _repository
        ?.watchSchedules(_familyId)
        .listen(_applyRemoteSchedules);
    _statsSubscription = _repository
        ?.watchStats(_familyId)
        .listen(_applyRemoteStats);
    _callSubscription = _repository
        ?.watchCall(_familyId, _callRoomId)
        .listen(_applyRemoteCall);
    _playSubscription = _repository
        ?.watchPlaySession(_familyId, _playRoomId)
        .listen(_applyRemotePlaySession);
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _membersSubscription?.cancel();
    _contactsSubscription?.cancel();
    _schedulesSubscription?.cancel();
    _statsSubscription?.cancel();
    _callSubscription?.cancel();
    _playSubscription?.cancel();
    super.dispose();
  }

  void _setRole(AppRole role) {
    setState(() => _role = role);
  }

  AppRole _initialRole() {
    final session = widget.session;
    if (session != null) {
      return session.role.appRole;
    }

    final value = Uri.base.queryParameters['role'];
    return switch (value) {
      'parent' => AppRole.parent,
      'relative' || 'family' => AppRole.relative,
      _ => AppRole.childWall,
    };
  }

  void _setChildWallActive(bool active) {
    setState(() => _childWallActive = active);
    final repository = _repository;
    if (repository != null) {
      unawaited(
        repository.setChildWallActive(familyId: _familyId, active: active),
      );
    }
  }

  void _startChildCall(FamilyContact contact, {required bool startedByParent}) {
    final eventKind = startedByParent
        ? FamilyStatsEventKind.callStartedByParent
        : FamilyStatsEventKind.callStartedByChild;
    final event = FamilyStatsEntry(
      id: 'event-${DateTime.now().microsecondsSinceEpoch}',
      contactId: contact.id,
      kind: eventKind,
      occurredAt: DateTime.now(),
    );
    final nextCall = CallSession.requested(
      id: _callRoomId,
      familyId: _familyId,
      callerDeviceId: startedByParent
          ? CallSession.parentPhoneDeviceId
          : CallSession.childWallDeviceId,
      calleeDeviceId: contact.id,
      activeEndpoint: CallEndpoint.childWall,
    ).copyWith(status: CallStatus.active);

    setState(() {
      _childWallActive = true;
      _cameraOn = true;
      _call = nextCall;
      _statsEvents = [..._statsEvents, event];
    });
    _saveStats(event);
    _saveCall(nextCall);
  }

  void _startRelativeCallToChild() {
    if (!_childWallActive ||
        _call.isActiveMedia ||
        _call.status.needsParentAction) {
      return;
    }

    final callerDeviceId = widget.session?.uid ?? 'relative-device';
    final event = FamilyStatsEntry(
      id: 'relative-call-${DateTime.now().microsecondsSinceEpoch}',
      contactId: callerDeviceId,
      kind: FamilyStatsEventKind.callStartedByFamily,
      occurredAt: DateTime.now(),
    );
    final nextCall = CallSession.requested(
      id: _callRoomId,
      familyId: _familyId,
      callerDeviceId: callerDeviceId,
      calleeDeviceId: CallSession.childWallDeviceId,
      activeEndpoint: CallEndpoint.childWall,
    ).copyWith(status: CallStatus.awaitingParentApproval);

    setState(() {
      _cameraOn = false;
      _call = nextCall;
      _statsEvents = [..._statsEvents, event];
    });
    _saveStats(event);
    _saveCall(nextCall);
  }

  void _approveCallRequest() {
    if (!_call.status.needsParentAction) {
      return;
    }

    late final CallSession approvedCall;
    setState(() {
      approvedCall = _call.copyWith(status: CallStatus.active);
      _call = approvedCall;
      _cameraOn = true;
      _childWallActive = true;
    });
    _saveCall(approvedCall);
  }

  void _rejectCallRequest() {
    if (!_call.status.needsParentAction) {
      return;
    }

    late final CallSession rejectedCall;
    final event = FamilyStatsEntry(
      id: 'reject-${DateTime.now().microsecondsSinceEpoch}',
      contactId: _contactIdForCallStats(_call),
      kind: FamilyStatsEventKind.callRejected,
      occurredAt: DateTime.now(),
    );
    setState(() {
      rejectedCall = _call.copyWith(status: CallStatus.rejected);
      _call = rejectedCall;
      _cameraOn = false;
      _statsEvents = [..._statsEvents, event];
    });
    _saveStats(event);
    _saveCall(rejectedCall);
  }

  void _recordTap(FamilyContact contact) {
    final event = FamilyStatsEntry(
      id: 'tap-${DateTime.now().microsecondsSinceEpoch}',
      contactId: contact.id,
      kind: FamilyStatsEventKind.tileTapped,
      occurredAt: DateTime.now(),
    );
    setState(() {
      _statsEvents = [..._statsEvents, event];
    });
    _saveStats(event);
    _startChildCall(contact, startedByParent: false);
  }

  void _endCall() {
    late final CallSession endedCall;
    FamilyStatsEntry? completedEvent;
    setState(() {
      if (_call.status == CallStatus.active) {
        completedEvent = FamilyStatsEntry(
          id: 'complete-${DateTime.now().microsecondsSinceEpoch}',
          contactId: _contactIdForCallStats(_call),
          kind: FamilyStatsEventKind.callCompleted,
          occurredAt: DateTime.now(),
          durationSeconds: 60,
        );
        _statsEvents = [..._statsEvents, completedEvent!];
      }
      endedCall = _call.copyWith(status: CallStatus.ended);
      _call = endedCall;
      _cameraOn = false;
    });
    if (completedEvent != null) {
      _saveStats(completedEvent!);
    }
    _saveCall(endedCall);
  }

  void _sendPlayPrompt(PlayActivity activity, String targetKey) {
    final actorId = widget.session?.uid ?? 'preview-family';
    final nextSession = PlaySession.prompt(
      id: _playRoomId,
      familyId: _familyId,
      activity: activity,
      targetKey: targetKey,
      createdBy: actorId,
      boardStrokes: _playSession.boardStrokes,
    );

    setState(() => _playSession = nextSession);
    _savePlaySession(nextSession);
  }

  void _addPlayBoardStroke(PlayBoardStroke stroke) {
    final actorId = widget.session?.uid ?? stroke.actorId;
    final nextSession = _playSession.withBoardStroke(stroke, actorId: actorId);

    setState(() => _playSession = nextSession);
    _savePlaySession(nextSession);
  }

  void _clearPlayBoard() {
    final actorId = widget.session?.uid ?? 'preview-family';
    final nextSession = _playSession.withoutBoard(actorId: actorId);

    setState(() => _playSession = nextSession);
    _savePlaySession(nextSession);
  }

  void _answerPlayPrompt(String responseKey) {
    if (!_playSession.isPrompting) {
      return;
    }

    final nextSession = _playSession.answeredBy(responseKey);
    setState(() => _playSession = nextSession);
    _savePlaySession(nextSession);
  }

  void _clearPlayPrompt() {
    final actorId = widget.session?.uid ?? 'preview-family';
    final nextSession = PlaySession.idle(
      id: _playRoomId,
      familyId: _familyId,
      createdBy: actorId,
    );

    setState(() => _playSession = nextSession);
    _savePlaySession(nextSession);
  }

  String _contactIdForCallStats(CallSession call) {
    return call.isCallingChildWall ? call.callerDeviceId : call.calleeDeviceId;
  }

  void _handoff(CallEndpoint endpoint) {
    late final CallSession handedOffCall;
    setState(() {
      _call = _call.copyWith(
        status: CallStatus.transferring,
        activeEndpoint: endpoint,
      );
      handedOffCall = _call.copyWith(status: CallStatus.active);
      _call = handedOffCall;
      _cameraOn = true;
    });
    _saveCall(handedOffCall);
  }

  void _approveMember(FamilyMember member) {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    unawaited(repository.approveMember(familyId: _familyId, member: member));
  }

  void _rejectMember(FamilyMember member) {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    unawaited(repository.rejectMember(familyId: _familyId, member: member));
  }

  Future<void> _updateMemberProfile(
    FamilyMember member, {
    required String displayName,
    required String familyTag,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    await repository.updateMemberProfile(
      familyId: _familyId,
      member: member,
      displayName: displayName,
      familyTag: familyTag,
    );
  }

  Future<void> _removeMember(FamilyMember member) async {
    final repository = _repository;
    final session = widget.session;
    if (repository == null || session == null) {
      return;
    }

    await repository.removeMember(
      familyId: _familyId,
      member: member,
      currentUid: session.uid,
    );
  }

  Future<void> _resetFamilySpace() async {
    final repository = _repository;
    final session = widget.session;
    if (repository == null || session == null) {
      return;
    }

    await repository.resetFamilySpace(
      profile: session.profile,
      currentUid: session.uid,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _childWallActive = false;
      _cameraOn = false;
      _call = DemoFamilyData.initialCall;
      _playSession = PlaySession.idle(id: _playRoomId, familyId: _familyId);
      _contacts = const [];
      _schedules = const [];
      _statsEvents = const [];
    });
  }

  void _applyRemoteProfile(FamilyProfile? profile) {
    if (!mounted || profile == null) {
      return;
    }

    setState(() => _childWallActive = profile.childWallActive);
  }

  void _applyRemoteMembers(List<FamilyMember> members) {
    if (!mounted) {
      return;
    }

    setState(() => _members = members);
  }

  void _applyRemoteContacts(List<FamilyContact> contacts) {
    if (!mounted) {
      return;
    }

    setState(() => _contacts = contacts);
  }

  void _applyRemoteSchedules(List<ScheduleWindow> schedules) {
    if (!mounted) {
      return;
    }

    setState(() => _schedules = schedules);
  }

  void _applyRemoteStats(List<FamilyStatsEntry> statsEvents) {
    if (!mounted) {
      return;
    }

    setState(() => _statsEvents = statsEvents);
  }

  void _applyRemoteCall(CallSession? remoteCall) {
    if (!mounted || remoteCall == null) {
      return;
    }

    setState(() {
      _call = remoteCall;
      _cameraOn = remoteCall.isActiveMedia;
      if (remoteCall.isActiveMedia) {
        _childWallActive = true;
      }
    });
  }

  void _applyRemotePlaySession(PlaySession? remoteSession) {
    if (!mounted || remoteSession == null) {
      return;
    }

    setState(() => _playSession = remoteSession);
  }

  void _saveCall(CallSession call) {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    unawaited(repository.saveCall(call));
  }

  void _saveStats(FamilyStatsEntry entry) {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    unawaited(repository.recordStatsEntry(_familyId, entry));
  }

  void _savePlaySession(PlaySession session) {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    unawaited(repository.savePlaySession(session));
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    final screen = switch (_role) {
      AppRole.childWall => ChildWallScreen(
        firebaseReady: widget.firebaseStatus.isReady,
        familyId: _familyId,
        currentUserId: widget.session?.uid,
        active: _childWallActive,
        cameraOn: _cameraOn,
        contacts: _contacts,
        call: _call,
        playSession: _playSession,
        onContactPressed: _recordTap,
        onEndCall: _endCall,
        onPlayAnswer: _answerPlayPrompt,
        onPlayBoardStroke: _addPlayBoardStroke,
        onSignOut: widget.onSignOut,
      ),
      AppRole.parent => ParentControlScreen(
        firebaseStatus: widget.firebaseStatus,
        familyName: _familyName,
        inviteCode: _inviteCode,
        wallPairingCode: _wallPairingCode,
        roleLabel: widget.session == null
            ? strings.offline
            : strings.roleLabel(widget.session!.role),
        childWallActive: _childWallActive,
        contacts: _contacts,
        members: _members,
        currentUserId: widget.session?.uid,
        schedules: _schedules,
        statsSummary: _statsSummary,
        activeCall: _call,
        cameraOn: _cameraOn,
        onActiveChanged: _setChildWallActive,
        onStartCallForChild: (contact) =>
            _startChildCall(contact, startedByParent: true),
        onHandoff: _handoff,
        onEndCall: _endCall,
        onApproveCallRequest: _approveCallRequest,
        onRejectCallRequest: _rejectCallRequest,
        onApproveMember: _approveMember,
        onRejectMember: _rejectMember,
        onUpdateMemberProfile: _updateMemberProfile,
        onRemoveMember: _removeMember,
        onResetFamilySpace: _resetFamilySpace,
        onSignOut: widget.onSignOut,
      ),
      AppRole.relative => RelativeScreen(
        firebaseReady: widget.firebaseStatus.isReady,
        familyId: _familyId,
        currentUserId: widget.session?.uid,
        childWallActive: _childWallActive,
        activeCall: _call,
        playSession: _playSession,
        cameraOn: _cameraOn,
        contacts: _contacts,
        onStartCallToChild: _startRelativeCallToChild,
        onEndCall: _endCall,
        onSendPlayPrompt: _sendPlayPrompt,
        onPlayBoardStroke: _addPlayBoardStroke,
        onClearPlayBoard: _clearPlayBoard,
        onClearPlay: _clearPlayPrompt,
        onSignOut: widget.onSignOut,
      ),
    };

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: screen),
          if (widget.session == null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 14,
              right: 18,
              child: _PreviewRoleDock(role: _role, onRoleChanged: _setRole),
            ),
        ],
      ),
    );
  }
}

class _PreviewRoleDock extends StatelessWidget {
  const _PreviewRoleDock({required this.role, required this.onRoleChanged});

  final AppRole role;
  final ValueChanged<AppRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Material(
      color: const Color(0xD91C2024),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: PopupMenuButton<AppRole>(
        tooltip: strings.openPreviewMenu,
        color: const Color(0xFF1C2024),
        position: PopupMenuPosition.under,
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: onRoleChanged,
        itemBuilder: (context) => [
          _roleItem(
            role: AppRole.childWall,
            currentRole: role,
            icon: Icons.grid_view_rounded,
            label: strings.wall,
          ),
          _roleItem(
            role: AppRole.parent,
            currentRole: role,
            icon: Icons.shield_rounded,
            label: strings.parent,
          ),
          _roleItem(
            role: AppRole.relative,
            currentRole: role,
            icon: Icons.favorite_rounded,
            label: strings.family,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<AppRole> _roleItem({
    required AppRole role,
    required AppRole currentRole,
    required IconData icon,
    required String label,
  }) {
    final selected = role == currentRole;

    return PopupMenuItem<AppRole>(
      value: role,
      child: Row(
        children: [
          Icon(icon, color: selected ? Colors.white : const Color(0xFFDACFC4)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
