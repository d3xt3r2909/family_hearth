import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/auth_repository.dart';
import '../data/family_repository.dart';
import '../domain/family_membership.dart';
import '../domain/family_profile.dart';
import '../domain/family_session.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/family_setup_screen.dart';
import '../features/auth/pending_approval_screen.dart';
import '../features/shared/family_hearth_mark.dart';
import '../features/shared/language_menu.dart';
import '../i18n/app_localizations.dart';
import '../firebase/firebase_bootstrap.dart';
import 'home_shell.dart';

class FamilyHearthApp extends StatefulWidget {
  const FamilyHearthApp({super.key, this.bootstrapFuture});

  final Future<FirebaseBootstrapResult>? bootstrapFuture;

  @override
  State<FamilyHearthApp> createState() => _FamilyHearthAppState();
}

class _FamilyHearthAppState extends State<FamilyHearthApp> {
  final _languageController = AppLanguageController();

  @override
  void initState() {
    super.initState();
    _languageController.load();
  }

  @override
  void dispose() {
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _languageController,
      builder: (context, _) {
        return AppLanguageScope(
          controller: _languageController,
          child: MaterialApp(
            title: 'Family Hearth',
            debugShowCheckedModeBanner: false,
            locale: _languageController.locale,
            supportedLocales: AppLanguage.values
                .map((language) => language.locale)
                .toList(growable: false),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            theme: _buildTheme(),
            home: _StartupGate(bootstrapFuture: widget.bootstrapFuture),
          ),
        );
      },
    );
  }

  ThemeData _buildTheme() {
    const seed = Color(0xFFE85D43);
    final scheme = ColorScheme.fromSeed(seedColor: seed);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: const Color(0xFFE85D43),
        secondary: const Color(0xFF197A6E),
        tertiary: const Color(0xFFFFB545),
        surface: const Color(0xFFFFFBF7),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFBF7),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: const Color(0xFFFFD9CE),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({this.bootstrapFuture});

  final Future<FirebaseBootstrapResult>? bootstrapFuture;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late final Future<FirebaseBootstrapResult> _bootstrapFuture =
      widget.bootstrapFuture ?? FirebaseBootstrap().start();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseBootstrapResult>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _WarmStartupScreen();
        }

        final firebaseStatus = snapshot.data!;
        if (!firebaseStatus.isReady) {
          return HomeShell(firebaseStatus: firebaseStatus);
        }

        return _AuthGate(firebaseStatus: firebaseStatus);
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({required this.firebaseStatus});

  final FirebaseBootstrapResult firebaseStatus;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _authRepository = AuthRepository();
  final _familyRepository = FirestoreFamilyRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authRepository.authStateChanges(),
      initialData: _authRepository.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null || user.isAnonymous) {
          return AuthScreen(authRepository: _authRepository);
        }

        return _FamilySessionGate(
          firebaseStatus: widget.firebaseStatus,
          user: user,
          authRepository: _authRepository,
          familyRepository: _familyRepository,
        );
      },
    );
  }
}

class _FamilySessionGate extends StatefulWidget {
  const _FamilySessionGate({
    required this.firebaseStatus,
    required this.user,
    required this.authRepository,
    required this.familyRepository,
  });

  final FirebaseBootstrapResult firebaseStatus;
  final User user;
  final AuthRepository authRepository;
  final FamilyRepository familyRepository;

  @override
  State<_FamilySessionGate> createState() => _FamilySessionGateState();
}

class _FamilySessionGateState extends State<_FamilySessionGate> {
  String? _selectedFamilyId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FamilyMembership>>(
      stream: widget.familyRepository.watchUserFamilies(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _CloudIssueScreen(
            message: context.t.couldNotLoadFamilyHomes('${snapshot.error}'),
            onSignOut: widget.authRepository.signOut,
          );
        }

        if (!snapshot.hasData) {
          return const _WarmStartupScreen();
        }

        final memberships = snapshot.data!;
        if (memberships.isEmpty) {
          return FamilySetupScreen(
            user: widget.user,
            authRepository: widget.authRepository,
            familyRepository: widget.familyRepository,
          );
        }

        final selectedMembership = _selectMembership(memberships);

        if (memberships.length > 1 && _selectedFamilyId == null) {
          return _FamilyChooserScreen(
            user: widget.user,
            memberships: memberships,
            onSelected: (membership) =>
                setState(() => _selectedFamilyId = membership.familyId),
            onSignOut: widget.authRepository.signOut,
          );
        }

        if (selectedMembership.status != FamilyMemberStatus.approved) {
          return PendingApprovalScreen(
            membership: selectedMembership,
            onSignOut: widget.authRepository.signOut,
          );
        }

        return StreamBuilder<FamilyProfile?>(
          stream: widget.familyRepository.watchFamilyProfile(
            selectedMembership.familyId,
          ),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _CloudIssueScreen(
                message: context.t.couldNotLoadFamily(
                  '${profileSnapshot.error}',
                ),
                onSignOut: widget.authRepository.signOut,
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              return const _WarmStartupScreen();
            }

            return HomeShell(
              firebaseStatus: widget.firebaseStatus,
              session: FamilySession(
                uid: widget.user.uid,
                email: widget.user.email ?? '',
                displayName: widget.user.displayName ?? '',
                membership: selectedMembership,
                profile: profile,
              ),
              onSignOut: widget.authRepository.signOut,
            );
          },
        );
      },
    );
  }

  FamilyMembership _selectMembership(List<FamilyMembership> memberships) {
    final requestedFamilyId = Uri.base.queryParameters['family'];
    final selectedFamilyId = _selectedFamilyId ?? requestedFamilyId;
    if (selectedFamilyId != null) {
      for (final membership in memberships) {
        if (membership.familyId == selectedFamilyId) {
          return membership;
        }
      }
    }
    return memberships.first;
  }
}

class _FamilyChooserScreen extends StatelessWidget {
  const _FamilyChooserScreen({
    required this.user,
    required this.memberships,
    required this.onSelected,
    required this.onSignOut,
  });

  final User user;
  final List<FamilyMembership> memberships;
  final ValueChanged<FamilyMembership> onSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFFFF7EC)),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(top: 14, right: 18, child: LanguageMenu()),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Color(0xFFE7D9CC)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FamilyHearthLockup(
                              markSize: 70,
                              subtitle: strings.chooseFamilySpace,
                            ),
                            const SizedBox(height: 18),
                            for (final membership in memberships) ...[
                              ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                tileColor: const Color(0xFFFFFBF7),
                                leading: const Icon(Icons.home_rounded),
                                title: Text(
                                  membership.familyName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                isThreeLine: true,
                                subtitle: Text(
                                  '${strings.roleLabel(membership.role)} · ${strings.memberStatusLabel(membership.status)}',
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                ),
                                onTap: () => onSelected(membership),
                              ),
                              const SizedBox(height: 10),
                            ],
                            TextButton.icon(
                              onPressed: onSignOut,
                              icon: const Icon(Icons.logout_rounded),
                              label: Text(user.email ?? strings.signOut),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloudIssueScreen extends StatelessWidget {
  const _CloudIssueScreen({required this.message, required this.onSignOut});

  final String message;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFFFF7EC)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFFE7D9CC)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 54,
                        color: Color(0xFFE85D43),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.cloudNeedsAttention,
                        style: TextStyle(
                          color: Color(0xFF221B16),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6F6258),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: onSignOut,
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(strings.signOut),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WarmStartupScreen extends StatelessWidget {
  const _WarmStartupScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = context.t;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF7EC), Color(0xFFFFE2BF), Color(0xFFD9F0DF)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FamilyHearthMark(
                size: 116,
                backgroundColor: Color(0xFFFFC56B),
              ),
              const SizedBox(height: 18),
              Text(
                strings.appTitle,
                style: TextStyle(
                  color: Color(0xFF221B16),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox.square(
                dimension: 34,
                child: CircularProgressIndicator(color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
