import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/call_session.dart';
import '../../domain/family_contact.dart';
import '../../domain/family_membership.dart';
import '../../domain/family_stats.dart';
import '../../domain/play_session.dart';
import '../../domain/schedule_window.dart';
import '../../firebase/firebase_bootstrap.dart';
import '../../i18n/app_localizations.dart';
import '../child/child_wall_screen.dart';
import '../shared/family_hearth_mark.dart';
import '../shared/language_menu.dart';
import '../shared/sound_effects_toggle.dart';

class ParentControlScreen extends StatelessWidget {
  const ParentControlScreen({
    super.key,
    required this.firebaseStatus,
    required this.familyId,
    required this.familyName,
    required this.inviteCode,
    required this.wallPairingCode,
    required this.roleLabel,
    required this.childWallActive,
    required this.contacts,
    required this.members,
    required this.currentUserId,
    required this.schedules,
    required this.statsSummary,
    required this.activeCall,
    required this.playSession,
    required this.cameraOn,
    required this.onActiveChanged,
    required this.onStartCallForChild,
    required this.onHandoff,
    required this.onEndCall,
    required this.onApproveCallRequest,
    required this.onRejectCallRequest,
    required this.onApproveMember,
    required this.onRejectMember,
    required this.onUpdateMemberProfile,
    required this.onRemoveMember,
    required this.onResetFamilySpace,
    required this.soundEffectsEnabled,
    required this.onSoundEffectsChanged,
    this.onSignOut,
  });

  final FirebaseBootstrapResult firebaseStatus;
  final String familyId;
  final String familyName;
  final String inviteCode;
  final String wallPairingCode;
  final String roleLabel;
  final bool childWallActive;
  final List<FamilyContact> contacts;
  final List<FamilyMember> members;
  final String? currentUserId;
  final List<ScheduleWindow> schedules;
  final FamilyStatsSummary statsSummary;
  final CallSession activeCall;
  final PlaySession playSession;
  final bool cameraOn;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<FamilyContact> onStartCallForChild;
  final ValueChanged<CallEndpoint> onHandoff;
  final VoidCallback onEndCall;
  final VoidCallback onApproveCallRequest;
  final VoidCallback onRejectCallRequest;
  final ValueChanged<FamilyMember> onApproveMember;
  final ValueChanged<FamilyMember> onRejectMember;
  final Future<void> Function(
    FamilyMember member, {
    required String displayName,
    required String familyTag,
  })
  onUpdateMemberProfile;
  final Future<void> Function(FamilyMember member) onRemoveMember;
  final Future<void> Function() onResetFamilySpace;
  final bool soundEffectsEnabled;
  final ValueChanged<bool> onSoundEffectsChanged;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final activeContact = _contactForCall(activeCall, contacts);

    return DefaultTabController(
      length: 2,
      child: Stack(
        children: [
          Positioned.fill(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildControls(context, activeContact),
                ChildWallScreen(
                  firebaseReady: firebaseStatus.isReady,
                  familyId: familyId,
                  currentUserId: currentUserId,
                  active: childWallActive,
                  cameraOn: cameraOn,
                  contacts: contacts,
                  call: activeCall,
                  playSession: playSession,
                  readOnly: true,
                  onContactPressed: (_) {},
                  onEndCall: () {},
                  onPlayAnswer: (_) {},
                  onPlayBoardStroke: (_) {},
                  onPlayBoardSticker: (_) {},
                  soundEffectsEnabled: soundEffectsEnabled,
                  onSoundEffectsChanged: onSoundEffectsChanged,
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 14,
            left: 18,
            child: const _ParentViewSwitcher(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, FamilyContact? activeContact) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFFFF7EC)),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _ParentBackdrop())),
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 88, 18, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 920;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ParentHero(
                            familyName: familyName,
                            inviteCode: inviteCode,
                            wallPairingCode: wallPairingCode,
                            roleLabel: roleLabel,
                            childWallActive: childWallActive,
                            firebaseStatus: firebaseStatus,
                            soundEffectsEnabled: soundEffectsEnabled,
                            onSoundEffectsChanged: onSoundEffectsChanged,
                            onSignOut: onSignOut,
                          ),
                          const SizedBox(height: 16),
                          _PendingMembersPanel(
                            members: members,
                            onApproveMember: onApproveMember,
                            onRejectMember: onRejectMember,
                          ),
                          if (_pendingMembers.isNotEmpty)
                            const SizedBox(height: 16),
                          _UserManagementPanel(
                            members: members,
                            currentUserId: currentUserId,
                            onUpdateMemberProfile: onUpdateMemberProfile,
                            onRemoveMember: onRemoveMember,
                          ),
                          const SizedBox(height: 16),
                          _FamilyTimeCard(
                            active: childWallActive,
                            cameraOn: cameraOn,
                            call: activeCall,
                            onChanged: onActiveChanged,
                          ),
                          const SizedBox(height: 16),
                          if (activeCall.status.needsParentAction) ...[
                            _CallApprovalPanel(
                              requester: activeContact,
                              onApprove: onApproveCallRequest,
                              onReject: onRejectCallRequest,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: Column(
                                    children: [
                                      _StartCallPanel(
                                        contacts: contacts,
                                        onStartCallForChild:
                                            onStartCallForChild,
                                      ),
                                      const SizedBox(height: 16),
                                      _SchedulePanel(
                                        schedules: schedules,
                                        contacts: contacts,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _LiveCallPanel(
                                        call: activeCall,
                                        cameraOn: cameraOn,
                                        activeContact: activeContact,
                                        onHandoff: onHandoff,
                                        onEndCall: onEndCall,
                                      ),
                                      const SizedBox(height: 16),
                                      _StatsPanel(
                                        contacts: contacts,
                                        summary: statsSummary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _StartCallPanel(
                              contacts: contacts,
                              onStartCallForChild: onStartCallForChild,
                            ),
                            const SizedBox(height: 16),
                            _LiveCallPanel(
                              call: activeCall,
                              cameraOn: cameraOn,
                              activeContact: activeContact,
                              onHandoff: onHandoff,
                              onEndCall: onEndCall,
                            ),
                            const SizedBox(height: 16),
                            _SchedulePanel(
                              schedules: schedules,
                              contacts: contacts,
                            ),
                            const SizedBox(height: 16),
                            _StatsPanel(
                              contacts: contacts,
                              summary: statsSummary,
                            ),
                          ],
                          const SizedBox(height: 16),
                          _DangerZonePanel(
                            familyName: familyName,
                            onResetFamilySpace: onResetFamilySpace,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<FamilyMember> get _pendingMembers => members
      .where((member) => member.status == FamilyMemberStatus.pending)
      .toList(growable: false);

  FamilyContact? _contactForCall(
    CallSession call,
    List<FamilyContact> contacts,
  ) {
    final contactId = call.isCallingChildWall
        ? call.callerDeviceId
        : call.calleeDeviceId;
    for (final contact in contacts) {
      if (contact.id == contactId) {
        return contact;
      }
    }
    return null;
  }
}

class _ParentViewSwitcher extends StatelessWidget {
  const _ParentViewSwitcher();

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Material(
      color: const Color(0xEE211913),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: const Color(0xFFFFE2BF),
            borderRadius: BorderRadius.circular(8),
          ),
          labelColor: const Color(0xFF221B16),
          unselectedLabelColor: Colors.white,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.tune_rounded),
              text: strings.parentControls,
            ),
            Tab(
              icon: const Icon(Icons.tablet_mac_rounded),
              text: strings.wallPreview,
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentHero extends StatelessWidget {
  const _ParentHero({
    required this.familyName,
    required this.inviteCode,
    required this.wallPairingCode,
    required this.roleLabel,
    required this.childWallActive,
    required this.firebaseStatus,
    required this.soundEffectsEnabled,
    required this.onSoundEffectsChanged,
    required this.onSignOut,
  });

  final String familyName;
  final String inviteCode;
  final String wallPairingCode;
  final String roleLabel;
  final bool childWallActive;
  final FirebaseBootstrapResult firebaseStatus;
  final bool soundEffectsEnabled;
  final ValueChanged<bool> onSoundEffectsChanged;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return _PanelCard(
      color: const Color(0xFF211913),
      borderColor: const Color(0xFF211913),
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final brand = FamilyHearthLockup(
            markSize: compact ? 56 : 68,
            textColor: Colors.white,
            subtitleColor: const Color(0xFFEADCD0),
            subtitle: '$familyName · $roleLabel',
          );
          final chips = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _SoftChip(
                icon: childWallActive
                    ? Icons.wb_sunny_rounded
                    : Icons.dark_mode_rounded,
                label: childWallActive ? strings.wallAwake : strings.wallDim,
                background: childWallActive
                    ? const Color(0xFF0F7A5B)
                    : const Color(0xFF4C4743),
                foreground: Colors.white,
              ),
              _SoftChip(
                icon: firebaseStatus.isReady
                    ? Icons.cloud_done_rounded
                    : Icons.offline_bolt_rounded,
                label: firebaseStatus.isReady
                    ? strings.cloudReady
                    : strings.offline,
                background: const Color(0xFFFFE2BF),
                foreground: const Color(0xFF221B16),
              ),
              if (inviteCode.isNotEmpty)
                _CopyCodeChip(
                  icon: Icons.key_rounded,
                  label: strings.invite,
                  code: inviteCode,
                  background: const Color(0xFFF4E7FF),
                  foreground: const Color(0xFF3D2458),
                ),
              if (wallPairingCode.isNotEmpty)
                _CopyCodeChip(
                  icon: Icons.tablet_mac_rounded,
                  label: strings.wall,
                  code: wallPairingCode,
                  background: const Color(0xFFDDF2E8),
                  foreground: const Color(0xFF164F46),
                ),
              if (onSignOut != null)
                IconButton.filledTonal(
                  tooltip: strings.signOut,
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                ),
              SoundEffectsToggle(
                enabled: soundEffectsEnabled,
                onChanged: onSoundEffectsChanged,
                dark: true,
              ),
              const LanguageMenu(
                dark: true,
                backgroundColor: Color(0xFF3A2D24),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [brand, const SizedBox(height: 16), chips],
            );
          }

          return Row(
            children: [
              Expanded(child: brand),
              const SizedBox(width: 18),
              chips,
            ],
          );
        },
      ),
    );
  }
}

class _PendingMembersPanel extends StatelessWidget {
  const _PendingMembersPanel({
    required this.members,
    required this.onApproveMember,
    required this.onRejectMember,
  });

  final List<FamilyMember> members;
  final ValueChanged<FamilyMember> onApproveMember;
  final ValueChanged<FamilyMember> onRejectMember;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
    final pending = members
        .where((member) => member.status == FamilyMemberStatus.pending)
        .toList(growable: false);

    if (pending.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      icon: Icons.verified_user_rounded,
      title: strings.familyRequests,
      subtitle: strings.approvePeople,
      child: Column(
        children: [
          for (var i = 0; i < pending.length; i++) ...[
            _PendingMemberRow(
              member: pending[i],
              onApprove: () => onApproveMember(pending[i]),
              onReject: () => onRejectMember(pending[i]),
            ),
            if (i < pending.length - 1)
              const Divider(height: 18, color: Color(0xFFE7D9CC)),
          ],
        ],
      ),
    );
  }
}

class _PendingMemberRow extends StatelessWidget {
  const _PendingMemberRow({
    required this.member,
    required this.onApprove,
    required this.onReject,
  });

  final FamilyMember member;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final identity = Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFE85D43),
              foregroundColor: Colors.white,
              child: Text(
                _initials(member.displayName, member.email),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF221B16),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${strings.roleLabel(member.role)} · ${member.email}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6F6258),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: compact ? WrapAlignment.start : WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close_rounded),
              label: Text(strings.reject),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F7A5B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onApprove,
              icon: const Icon(Icons.check_rounded),
              label: Text(strings.approve),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [identity, const SizedBox(height: 12), actions],
          );
        }

        return Row(
          children: [
            Expanded(child: identity),
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }

  String _initials(String displayName, String email) {
    final source = displayName.trim().isEmpty
        ? email.split('@').first
        : displayName.trim();
    final parts = source
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
}

class _UserManagementPanel extends StatefulWidget {
  const _UserManagementPanel({
    required this.members,
    required this.currentUserId,
    required this.onUpdateMemberProfile,
    required this.onRemoveMember,
  });

  final List<FamilyMember> members;
  final String? currentUserId;
  final Future<void> Function(
    FamilyMember member, {
    required String displayName,
    required String familyTag,
  })
  onUpdateMemberProfile;
  final Future<void> Function(FamilyMember member) onRemoveMember;

  @override
  State<_UserManagementPanel> createState() => _UserManagementPanelState();
}

class _UserManagementPanelState extends State<_UserManagementPanel> {
  String? _busyMemberId;

  Future<void> _editMember(FamilyMember member) async {
    final edit = await showDialog<_MemberProfileEdit>(
      context: context,
      builder: (context) => _EditMemberDialog(
        member: member,
        initialTag: _memberTag(context, member),
      ),
    );
    if (edit == null || !mounted) {
      return;
    }

    setState(() => _busyMemberId = member.uid);
    try {
      await widget.onUpdateMemberProfile(
        member,
        displayName: edit.displayName,
        familyTag: edit.familyTag,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.memberUpdated)));
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.couldNotUpdateMember('$error'))),
      );
    } finally {
      if (mounted) {
        setState(() => _busyMemberId = null);
      }
    }
  }

  Future<void> _removeMember(FamilyMember member) async {
    if (member.uid == widget.currentUserId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.cannotRemoveYourself)));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _RemoveMemberDialog(member: member),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busyMemberId = member.uid);
    try {
      await widget.onRemoveMember(member);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.memberRemoved)));
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.couldNotRemoveMember('$error'))),
      );
    } finally {
      if (mounted) {
        setState(() => _busyMemberId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
    final sortedMembers = [...widget.members]
      ..sort((left, right) {
        final roleCompare = _roleRank(
          left.role,
        ).compareTo(_roleRank(right.role));
        if (roleCompare != 0) {
          return roleCompare;
        }
        final statusCompare = _statusRank(
          left.status,
        ).compareTo(_statusRank(right.status));
        if (statusCompare != 0) {
          return statusCompare;
        }
        return left.displayName.toLowerCase().compareTo(
          right.displayName.toLowerCase(),
        );
      });

    return _SectionCard(
      icon: Icons.manage_accounts_rounded,
      title: strings.userManagement,
      subtitle: strings.managePeople,
      child: sortedMembers.isEmpty
          ? Text(
              strings.noMembersYet,
              style: const TextStyle(
                color: Color(0xFF6F6258),
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < sortedMembers.length; i++) ...[
                  _ManagedMemberRow(
                    member: sortedMembers[i],
                    currentUserId: widget.currentUserId,
                    busy: _busyMemberId == sortedMembers[i].uid,
                    onEdit: () => _editMember(sortedMembers[i]),
                    onRemove: () => _removeMember(sortedMembers[i]),
                  ),
                  if (i < sortedMembers.length - 1)
                    const Divider(height: 18, color: Color(0xFFE7D9CC)),
                ],
              ],
            ),
    );
  }

  int _roleRank(FamilyRole role) {
    return switch (role) {
      FamilyRole.parent => 0,
      FamilyRole.relative => 1,
      FamilyRole.childWall => 2,
    };
  }

  int _statusRank(FamilyMemberStatus status) {
    return switch (status) {
      FamilyMemberStatus.approved => 0,
      FamilyMemberStatus.pending => 1,
      FamilyMemberStatus.rejected => 2,
    };
  }
}

class _ManagedMemberRow extends StatelessWidget {
  const _ManagedMemberRow({
    required this.member,
    required this.currentUserId,
    required this.busy,
    required this.onEdit,
    required this.onRemove,
  });

  final FamilyMember member;
  final String? currentUserId;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
    final self = member.uid == currentUserId;
    final tag = _memberTag(context, member);
    final avatarColor = _memberAvatarColor(member);

    final identity = Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: avatarColor,
          foregroundColor: Colors.white,
          child: Text(
            _memberInitials(member.displayName, member.email),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF221B16),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                member.email.isEmpty ? member.uid : member.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6F6258),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SoftChip(
          icon: _roleIcon(member.role),
          label: strings.roleLabel(member.role),
          background: const Color(0xFFFFE2BF),
          foreground: const Color(0xFF221B16),
        ),
        _SoftChip(
          icon: _statusIcon(member.status),
          label: strings.memberStatusLabel(member.status),
          background: _statusBackground(member.status),
          foreground: _statusForeground(member.status),
        ),
        _SoftChip(
          icon: Icons.sell_rounded,
          label: _compactChipLabel(tag),
          background: const Color(0xFFF4E7FF),
          foreground: const Color(0xFF3D2458),
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy)
          const SizedBox.square(
            dimension: 34,
            child: Padding(
              padding: EdgeInsets.all(7),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton.filledTonal(
            tooltip: strings.editMember,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: self ? strings.cannotRemoveYourself : strings.removeMember,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFFFE4E1),
            foregroundColor: const Color(0xFFE02F2F),
          ),
          onPressed: busy || self ? null : onRemove,
          icon: const Icon(Icons.person_remove_rounded),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [identity, const SizedBox(height: 10), chips],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              details,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: details),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }

  IconData _roleIcon(FamilyRole role) {
    return switch (role) {
      FamilyRole.parent => Icons.admin_panel_settings_rounded,
      FamilyRole.relative => Icons.favorite_rounded,
      FamilyRole.childWall => Icons.tablet_mac_rounded,
    };
  }

  IconData _statusIcon(FamilyMemberStatus status) {
    return switch (status) {
      FamilyMemberStatus.pending => Icons.hourglass_top_rounded,
      FamilyMemberStatus.approved => Icons.verified_rounded,
      FamilyMemberStatus.rejected => Icons.block_rounded,
    };
  }

  Color _statusBackground(FamilyMemberStatus status) {
    return switch (status) {
      FamilyMemberStatus.pending => const Color(0xFFFFF2CC),
      FamilyMemberStatus.approved => const Color(0xFFDDF2E8),
      FamilyMemberStatus.rejected => const Color(0xFFFFE4E1),
    };
  }

  Color _statusForeground(FamilyMemberStatus status) {
    return switch (status) {
      FamilyMemberStatus.pending => const Color(0xFF6A4B00),
      FamilyMemberStatus.approved => const Color(0xFF164F46),
      FamilyMemberStatus.rejected => const Color(0xFFE02F2F),
    };
  }
}

class _EditMemberDialog extends StatefulWidget {
  const _EditMemberDialog({required this.member, required this.initialTag});

  final FamilyMember member;
  final String initialTag;

  @override
  State<_EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends State<_EditMemberDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _tagController;

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.displayName);
    _tagController = TextEditingController(text: widget.initialTag);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_canSave) {
      return;
    }
    Navigator.of(context).pop(
      _MemberProfileEdit(
        displayName: _nameController.text.trim(),
        familyTag: _tagController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return AlertDialog(
      title: Text(strings.editMember),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: strings.nickname,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: strings.familyTag,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton.icon(
          onPressed: _canSave ? _save : null,
          icon: const Icon(Icons.check_rounded),
          label: Text(strings.save),
        ),
      ],
    );
  }
}

class _RemoveMemberDialog extends StatelessWidget {
  const _RemoveMemberDialog({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return AlertDialog(
      title: Text(strings.removeMemberQuestion(member.displayName)),
      content: Text(strings.removeMemberBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.cancel),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE02F2F),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.person_remove_rounded),
          label: Text(strings.remove),
        ),
      ],
    );
  }
}

class _MemberProfileEdit {
  const _MemberProfileEdit({
    required this.displayName,
    required this.familyTag,
  });

  final String displayName;
  final String familyTag;
}

String _memberTag(BuildContext context, FamilyMember member) {
  final tag = member.familyTag.trim();
  return tag.isEmpty ? context.t.roleLabel(member.role) : tag;
}

String _memberInitials(String displayName, String email) {
  final source = displayName.trim().isEmpty
      ? email.split('@').first
      : displayName.trim();
  final parts = source
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

Color _memberAvatarColor(FamilyMember member) {
  const palette = [
    0xFFE85D43,
    0xFF197A6E,
    0xFFFFB545,
    0xFF4967B1,
    0xFFB34D8A,
    0xFF2F8C9D,
  ];
  final hash = member.uid.codeUnits.fold<int>(0, (value, unit) => value + unit);
  return Color(palette[hash % palette.length]);
}

String _compactChipLabel(String value) {
  const maxLength = 28;
  if (value.length <= maxLength) {
    return value;
  }
  return '${value.substring(0, maxLength - 3)}...';
}

class _FamilyTimeCard extends StatelessWidget {
  const _FamilyTimeCard({
    required this.active,
    required this.cameraOn,
    required this.call,
    required this.onChanged,
  });

  final bool active;
  final bool cameraOn;
  final CallSession call;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final callLive = call.status == CallStatus.active;
    final strings = context.t;

    return _PanelCard(
      color: active ? const Color(0xFFEAF7EF) : Colors.white,
      borderColor: active ? const Color(0xFFB8DDC7) : const Color(0xFFE7D9CC),
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF0F7A5B)
                      : const Color(0xFFFFE2BF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  active ? Icons.child_care_rounded : Icons.bedtime_rounded,
                  color: active ? Colors.white : const Color(0xFFE85D43),
                  size: 36,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active
                          ? strings.familyTimeOpen
                          : strings.familyTimeClosed,
                      style: const TextStyle(
                        color: Color(0xFF221B16),
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      active ? strings.wallReadyForTaps : strings.wallStaysCalm,
                      style: const TextStyle(
                        color: Color(0xFF66584F),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final switcher = Switch.adaptive(
            value: active,
            activeThumbColor: const Color(0xFF0F7A5B),
            activeTrackColor: const Color(0xFFB8DDC7),
            inactiveThumbColor: const Color(0xFF6C625A),
            inactiveTrackColor: const Color(0xFFE7D9CC),
            onChanged: onChanged,
          );

          final badges = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SoftChip(
                icon: cameraOn
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
                label: cameraOn ? strings.cameraVisible : strings.cameraOff,
                background: cameraOn
                    ? const Color(0xFFE85D43)
                    : const Color(0xFFF1E7DD),
                foreground: cameraOn ? Colors.white : const Color(0xFF66584F),
              ),
              _SoftChip(
                icon: callLive ? Icons.call_rounded : Icons.call_end_rounded,
                label: callLive ? strings.callLive : strings.noCall,
                background: callLive
                    ? const Color(0xFFFFE2BF)
                    : const Color(0xFFF1E7DD),
                foreground: const Color(0xFF221B16),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: badges),
                    switcher,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 18),
              badges,
              const SizedBox(width: 10),
              switcher,
            ],
          );
        },
      ),
    );
  }
}

class _CallApprovalPanel extends StatelessWidget {
  const _CallApprovalPanel({
    required this.requester,
    required this.onApprove,
    required this.onReject,
  });

  final FamilyContact? requester;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
    final name = requester?.displayName ?? strings.family;
    final accent = Color(requester?.accentColorValue ?? 0xFFE85D43);

    return _SectionCard(
      icon: Icons.video_camera_front_rounded,
      title: strings.callApprovalNeeded,
      subtitle: strings.familyWantsToCallChildWall(name),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final identity = Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: accent,
                foregroundColor: Colors.white,
                child: Text(
                  requester?.avatarText ?? 'FH',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF221B16),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      strings.cameraStaysOffUntilApproved,
                      style: const TextStyle(
                        color: Color(0xFF6F6258),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 9,
            runSpacing: 9,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded),
                label: Text(strings.rejectCall),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F7A5B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onApprove,
                icon: const Icon(Icons.check_rounded),
                label: Text(strings.approveCall),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [identity, const SizedBox(height: 14), actions],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _StartCallPanel extends StatelessWidget {
  const _StartCallPanel({
    required this.contacts,
    required this.onStartCallForChild,
  });

  final List<FamilyContact> contacts;
  final ValueChanged<FamilyContact> onStartCallForChild;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return _SectionCard(
      icon: Icons.video_call_rounded,
      title: strings.startCallForChild,
      subtitle: strings.chooseWhoAppears,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 620 ? 2 : 1;
          return GridView.builder(
            itemCount: contacts.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: columns == 1 ? 2.85 : 3.2,
            ),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return _CallContactTile(
                contact: contact,
                fullAction: columns == 1,
                onPressed: () => onStartCallForChild(contact),
              );
            },
          );
        },
      ),
    );
  }
}

class _CallContactTile extends StatelessWidget {
  const _CallContactTile({
    required this.contact,
    required this.fullAction,
    required this.onPressed,
  });

  final FamilyContact contact;
  final bool fullAction;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = Color(contact.accentColorValue);
    final strings = context.t;

    return Material(
      color: Color.alphaBlend(color.withValues(alpha: 0.1), Colors.white),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.26)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final identity = Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  child: Text(
                    contact.avatarText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF221B16),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contact.relationship,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6F6258),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            if (fullAction) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    identity,
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            strings.startCall,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 10),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LiveCallPanel extends StatelessWidget {
  const _LiveCallPanel({
    required this.call,
    required this.cameraOn,
    required this.activeContact,
    required this.onHandoff,
    required this.onEndCall,
  });

  final CallSession call;
  final bool cameraOn;
  final FamilyContact? activeContact;
  final ValueChanged<CallEndpoint> onHandoff;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    final hasCall = call.status == CallStatus.active;
    final accent = Color(activeContact?.accentColorValue ?? 0xFFE85D43);
    final strings = context.t;

    return _SectionCard(
      icon: hasCall ? Icons.spatial_audio_off_rounded : Icons.lock_rounded,
      title: hasCall ? strings.liveCall : strings.privacyReady,
      subtitle: hasCall
          ? strings.callIsOn(
              activeContact?.displayName ?? strings.family,
              call.activeEndpoint,
            )
          : strings.cameraAndMicOff,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasCall
                  ? Color.alphaBlend(
                      accent.withValues(alpha: 0.12),
                      Colors.white,
                    )
                  : const Color(0xFFF6EFE8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasCall
                    ? accent.withValues(alpha: 0.28)
                    : const Color(0xFFE7D9CC),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: hasCall ? accent : const Color(0xFF211913),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    cameraOn
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasCall
                            ? activeContact?.displayName ?? strings.familyIsHere
                            : strings.nothingBroadcasting,
                        style: const TextStyle(
                          color: Color(0xFF221B16),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cameraOn ? strings.cameraMarked : strings.wallPrivate,
                        style: const TextStyle(
                          color: Color(0xFF6F6258),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              OutlinedButton.icon(
                onPressed: hasCall
                    ? () => onHandoff(CallEndpoint.childWall)
                    : null,
                icon: const Icon(Icons.tablet_mac_rounded),
                label: Text(strings.wallCamera),
              ),
              OutlinedButton.icon(
                onPressed: hasCall
                    ? () => onHandoff(CallEndpoint.parentPhone)
                    : null,
                icon: const Icon(Icons.phone_iphone_rounded),
                label: Text(strings.endpointLabel(CallEndpoint.parentPhone)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE02F2F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: hasCall ? onEndCall : null,
                icon: const Icon(Icons.call_end_rounded),
                label: Text(strings.end),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({required this.schedules, required this.contacts});

  final List<ScheduleWindow> schedules;
  final List<FamilyContact> contacts;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return _SectionCard(
      icon: Icons.schedule_rounded,
      title: strings.todayOnWall,
      subtitle: strings.automaticWindows,
      child: Column(
        children: [
          for (var i = 0; i < schedules.length; i++) ...[
            _ScheduleRow(schedule: schedules[i], contacts: contacts),
            if (i < schedules.length - 1)
              const Divider(height: 18, color: Color(0xFFE7D9CC)),
          ],
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.schedule, required this.contacts});

  final ScheduleWindow schedule;
  final List<FamilyContact> contacts;

  @override
  Widget build(BuildContext context) {
    final names = contacts
        .where((contact) => schedule.allowedContactIds.contains(contact.id))
        .map((contact) => contact.relationship)
        .join(', ');

    return Row(
      children: [
        Container(
          width: 84,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE2BF),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            schedule.timeLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF221B16),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schedule.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF221B16),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                names,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6F6258),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.contacts, required this.summary});

  final List<FamilyContact> contacts;
  final FamilyStatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    var maxTaps = 1;
    for (final contact in contacts) {
      final stats =
          summary.byContact[contact.id] ??
          ContactStatsSummary(contactId: contact.id);
      if (stats.taps > maxTaps) {
        maxTaps = stats.taps;
      }
    }

    return _SectionCard(
      icon: Icons.auto_graph_rounded,
      title: strings.todaysLittleChoices,
      subtitle: strings.childKeepsReaching,
      child: Column(
        children: [
          for (var i = 0; i < contacts.length; i++) ...[
            _StatsRow(
              contact: contacts[i],
              stats:
                  summary.byContact[contacts[i].id] ??
                  ContactStatsSummary(contactId: contacts[i].id),
              maxTaps: maxTaps,
              isFavorite: summary.favoriteContactId == contacts[i].id,
            ),
            if (i < contacts.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.contact,
    required this.stats,
    required this.maxTaps,
    required this.isFavorite,
  });

  final FamilyContact contact;
  final ContactStatsSummary stats;
  final int maxTaps;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final color = Color(contact.accentColorValue);
    final fraction = stats.taps == 0 ? 0.05 : stats.taps / maxTaps;
    final strings = context.t;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Text(
            contact.avatarText,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      contact.relationship,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF221B16),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (isFavorite)
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB545),
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: fraction.toDouble(),
                  minHeight: 9,
                  backgroundColor: const Color(0xFFF1E7DD),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 74,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                strings.taps(stats.taps),
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF221B16),
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                strings.calls(stats.completedCalls),
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF6F6258),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DangerZonePanel extends StatefulWidget {
  const _DangerZonePanel({
    required this.familyName,
    required this.onResetFamilySpace,
  });

  final String familyName;
  final Future<void> Function() onResetFamilySpace;

  @override
  State<_DangerZonePanel> createState() => _DangerZonePanelState();
}

class _DangerZonePanelState extends State<_DangerZonePanel> {
  bool _busy = false;

  Future<void> _confirmAndReset() async {
    if (_busy) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ResetFamilyDialog(familyName: widget.familyName),
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _busy = true);
    try {
      await widget.onResetFamilySpace();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.familySpaceReset)));
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.couldNotResetFamily('$error'))),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return _SectionCard(
      icon: Icons.warning_rounded,
      title: strings.dangerZone,
      subtitle: strings.resetCleanStart,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.resetDescription,
                style: const TextStyle(
                  color: Color(0xFF6F6258),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
          final action = FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE02F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _busy ? null : _confirmAndReset,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_forever_rounded),
            label: Text(strings.resetFamily),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 12), action],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 16),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _ResetFamilyDialog extends StatefulWidget {
  const _ResetFamilyDialog({required this.familyName});

  final String familyName;

  @override
  State<_ResetFamilyDialog> createState() => _ResetFamilyDialogState();
}

class _ResetFamilyDialogState extends State<_ResetFamilyDialog> {
  final _controller = TextEditingController();

  bool get _canReset => _controller.text.trim().toUpperCase() == 'RESET';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return AlertDialog(
      title: Text(strings.resetFamilySpace),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.resetFamilyDialog(widget.familyName)),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: strings.typeResetToContinue,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.cancel),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE02F2F),
            foregroundColor: Colors.white,
          ),
          onPressed: _canReset ? () => Navigator.of(context).pop(true) : null,
          icon: const Icon(Icons.delete_forever_rounded),
          label: Text(strings.reset),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE2BF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFFE85D43)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF221B16),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6F6258),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.child,
    this.color = Colors.white,
    this.borderColor = const Color(0xFFE7D9CC),
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyCodeChip extends StatelessWidget {
  const _CopyCodeChip({
    required this.icon,
    required this.label,
    required this.code,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final String code;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Tooltip(
      message: strings.copyCode(label),
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(strings.codeCopied(label))));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground, size: 18),
                const SizedBox(width: 7),
                Text(
                  '$label $code',
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.copy_rounded, color: foreground, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParentBackdrop extends CustomPainter {
  const _ParentBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFFFE2BF);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height * 0.24)
        ..quadraticBezierTo(
          size.width * 0.56,
          size.height * 0.12,
          0,
          size.height * 0.18,
        )
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFD9F0DF);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.78)
        ..quadraticBezierTo(
          size.width * 0.45,
          size.height * 0.89,
          size.width,
          size.height * 0.7,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      paint,
    );

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x22E85D43);

    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.18 + i * 0.12);
      canvas.drawLine(
        Offset(size.width * 0.08, y),
        Offset(size.width * 0.92, y + 18),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
