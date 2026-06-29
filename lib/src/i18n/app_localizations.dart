import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/call_session.dart';
import '../domain/family_membership.dart';
import '../domain/play_session.dart';
import '../webrtc/web_rtc_call_controller.dart';

enum AppLanguage {
  en(Locale('en'), 'English', 'EN'),
  bs(Locale('bs'), 'Bosanski', 'BS'),
  de(Locale('de'), 'Deutsch', 'DE');

  const AppLanguage(this.locale, this.nativeName, this.shortName);

  final Locale locale;
  final String nativeName;
  final String shortName;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (language) => language.locale.languageCode == code,
      orElse: () => AppLanguage.en,
    );
  }
}

class AppLanguageController extends ChangeNotifier {
  static const _storageKey = 'family_hearth_language';

  AppLanguage _language = AppLanguage.en;

  AppLanguage get language => _language;
  Locale get locale => _language.locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final next = AppLanguage.fromCode(prefs.getString(_storageKey));
    if (next == _language) {
      return;
    }
    _language = next;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) {
      return;
    }
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, language.locale.languageCode);
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    super.key,
    required AppLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguageController controllerOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'AppLanguageScope is missing from the widget tree.');
    return scope!.notifier!;
  }

  static AppStrings stringsOf(BuildContext context) {
    return AppStrings(controllerOf(context).language);
  }
}

extension AppLocalizationContext on BuildContext {
  AppStrings get t => AppLanguageScope.stringsOf(this);
  AppLanguageController get languageController =>
      AppLanguageScope.controllerOf(this);
}

class AppStrings {
  const AppStrings(this.appLanguage);

  final AppLanguage appLanguage;

  String _pick(String en, String bs, String de) => switch (appLanguage) {
    AppLanguage.en => en,
    AppLanguage.bs => bs,
    AppLanguage.de => de,
  };

  String get appTitle => 'Family Hearth';
  String get appSubtitle => _pick(
    'Family Connection App',
    'Aplikacija za porodično povezivanje',
    'App für Familienverbindung',
  );
  String get language => _pick('Language', 'Jezik', 'Sprache');
  String get openPreviewMenu => _pick(
    'Open preview menu',
    'Otvori pregledni meni',
    'Vorschaumenü öffnen',
  );
  String get signOut => _pick('Sign out', 'Odjava', 'Abmelden');
  String get cancel => _pick('Cancel', 'Odustani', 'Abbrechen');
  String get close => _pick('Close', 'Zatvori', 'Schließen');
  String get parent => _pick('Parent', 'Roditelj', 'Elternteil');
  String get family => _pick('Family', 'Porodica', 'Familie');
  String get wall => _pick('Wall', 'Zid', 'Wand');
  String get relative => _pick('Family', 'Porodica', 'Familie');
  String get childWall => _pick('Child wall', 'Dječiji zid', 'Kinderwand');

  String roleLabel(FamilyRole role) => switch (role) {
    FamilyRole.parent => parent,
    FamilyRole.relative => family,
    FamilyRole.childWall => wall,
  };

  String memberStatusLabel(FamilyMemberStatus status) => switch (status) {
    FamilyMemberStatus.pending => _pick(
      'Waiting for parent',
      'Čeka roditelja',
      'Wartet auf Elternteil',
    ),
    FamilyMemberStatus.approved => _pick('Approved', 'Odobreno', 'Genehmigt'),
    FamilyMemberStatus.rejected => _pick(
      'Not approved',
      'Nije odobreno',
      'Nicht genehmigt',
    ),
  };

  String endpointLabel(CallEndpoint endpoint) => switch (endpoint) {
    CallEndpoint.childWall => childWall,
    CallEndpoint.parentPhone => _pick(
      'Parent phone',
      'Telefon roditelja',
      'Elterntelefon',
    ),
    CallEndpoint.relativeDevice => family,
  };

  String webRtcPhaseLabel(WebRtcCallPhase phase) => switch (phase) {
    WebRtcCallPhase.idle => _pick('Ready', 'Spremno', 'Bereit'),
    WebRtcCallPhase.openingMedia => _pick(
      'Opening camera',
      'Otvaram kameru',
      'Kamera wird geöffnet',
    ),
    WebRtcCallPhase.creatingPeer => _pick(
      'Preparing call',
      'Pripremam poziv',
      'Anruf wird vorbereitet',
    ),
    WebRtcCallPhase.waitingForPeer => _pick(
      'Waiting for family',
      'Čekam porodicu',
      'Warte auf Familie',
    ),
    WebRtcCallPhase.connecting => _pick('Connecting', 'Povezujem', 'Verbinden'),
    WebRtcCallPhase.connected => _pick('Connected', 'Povezano', 'Verbunden'),
    WebRtcCallPhase.ended => _pick('Ended', 'Završeno', 'Beendet'),
    WebRtcCallPhase.failed => _pick(
      'Needs attention',
      'Treba pažnju',
      'Benötigt Aufmerksamkeit',
    ),
  };

  String get createYourFamilyHearth => _pick(
    'Create your Family Hearth',
    'Kreiraj svoj Family Hearth',
    'Erstelle deinen Family Hearth',
  );
  String get welcomeBack =>
      _pick('Welcome back', 'Dobro došli nazad', 'Willkommen zurück');
  String get createAccountSubtitle => _pick(
    'Start with a parent account, then invite family.',
    'Počni s roditeljskim računom, zatim pozovi porodicu.',
    'Starte mit einem Elternkonto und lade dann Familie ein.',
  );
  String get signInSubtitle => _pick(
    'Sign in to your family space.',
    'Prijavi se u porodični prostor.',
    'Melde dich in deinem Familienbereich an.',
  );
  String get yourName => _pick('Your name', 'Ime', 'Dein Name');
  String get email => _pick('Email', 'Email', 'E-Mail');
  String get password => _pick('Password', 'Lozinka', 'Passwort');
  String get createAccount =>
      _pick('Create account', 'Kreiraj račun', 'Konto erstellen');
  String get signIn => _pick('Sign in', 'Prijava', 'Anmelden');
  String get alreadyHaveAccount => _pick(
    'I already have an account',
    'Već imam račun',
    'Ich habe schon ein Konto',
  );
  String get createNewAccount => _pick(
    'Create a new account',
    'Kreiraj novi račun',
    'Neues Konto erstellen',
  );
  String get emailAlreadyInUse => _pick(
    'That email already has an account.',
    'Taj email već ima račun.',
    'Diese E-Mail hat bereits ein Konto.',
  );
  String get invalidEmail => _pick(
    'That email address looks invalid.',
    'Ta email adresa ne izgleda ispravno.',
    'Diese E-Mail-Adresse sieht ungültig aus.',
  );
  String get weakPassword => _pick(
    'Use a stronger password.',
    'Koristi jaču lozinku.',
    'Nutze ein stärkeres Passwort.',
  );
  String get wrongCredentials => _pick(
    'Email or password is not correct.',
    'Email ili lozinka nisu ispravni.',
    'E-Mail oder Passwort ist nicht korrekt.',
  );
  String get emailPasswordNotEnabled => _pick(
    'Email/password sign-in is not enabled in Firebase yet.',
    'Email/lozinka prijava još nije uključena u Firebaseu.',
    'E-Mail/Passwort-Anmeldung ist in Firebase noch nicht aktiviert.',
  );
  String couldNotSignIn(String detail) => _pick(
    'Could not sign in. $detail',
    'Prijava nije uspjela. $detail',
    'Anmeldung nicht möglich. $detail',
  );
  String couldNotSignInCode(String code) => _pick(
    'Could not sign in ($code).',
    'Prijava nije uspjela ($code).',
    'Anmeldung nicht möglich ($code).',
  );

  String get setupHome =>
      _pick('Set up your home', 'Postavi svoj dom', 'Zuhause einrichten');
  String get createFamily =>
      _pick('Create a family', 'Kreiraj porodicu', 'Familie erstellen');
  String get createFamilySubtitle => _pick(
    'Use this when you are the parent.',
    'Koristi ovo ako si roditelj.',
    'Nutze dies, wenn du ein Elternteil bist.',
  );
  String get familyName => _pick('Family name', 'Ime porodice', 'Familienname');
  String get createHome =>
      _pick('Create home', 'Kreiraj dom', 'Zuhause erstellen');
  String get joinWithInvite => _pick(
    'Join with invite',
    'Pridruži se pozivnicom',
    'Mit Einladung beitreten',
  );
  String get joinWithInviteSubtitle => _pick(
    'For a parent, family member, or wall.',
    'Za roditelja, člana porodice ili zid.',
    'Für Elternteil, Familienmitglied oder Wand.',
  );
  String get inviteCode =>
      _pick('Invite code', 'Kod pozivnice', 'Einladungscode');
  String get pasteInviteCode => _pick(
    'Paste invite code',
    'Zalijepi kod pozivnice',
    'Einladungscode einfügen',
  );
  String get joinHome =>
      _pick('Join home', 'Pridruži se domu', 'Zuhause beitreten');
  String defaultHearthName(String name) =>
      _pick("$name's Hearth", '$name Hearth', '$name Hearth');
  String get signedIn => _pick('Signed in', 'Prijavljen/a', 'Angemeldet');
  String get rulesBlocked => _pick(
    'Firebase rules blocked this action. Deploy the latest rules.',
    'Firebase pravila su blokirala ovu radnju. Postavi najnovija pravila.',
    'Firebase-Regeln haben diese Aktion blockiert. Stelle die neuesten Regeln bereit.',
  );
  String get inviteNotFound => _pick(
    'That invite code was not found.',
    'Taj kod pozivnice nije pronađen.',
    'Dieser Einladungscode wurde nicht gefunden.',
  );
  String couldNotFinishSetup(String detail) => _pick(
    'Could not finish setup. $detail',
    'Postavljanje nije uspjelo. $detail',
    'Einrichtung konnte nicht abgeschlossen werden. $detail',
  );

  String get chooseFamilySpace => _pick(
    'Choose a family space',
    'Izaberi porodični prostor',
    'Familienbereich auswählen',
  );
  String get cloudNeedsAttention => _pick(
    'Cloud needs attention',
    'Cloud treba pažnju',
    'Cloud benötigt Aufmerksamkeit',
  );
  String couldNotLoadFamilyHomes(String detail) => _pick(
    'Could not load your family homes. $detail',
    'Nije moguće učitati tvoje porodične domove. $detail',
    'Deine Familienbereiche konnten nicht geladen werden. $detail',
  );
  String couldNotLoadFamily(String detail) => _pick(
    'Could not load this family. $detail',
    'Nije moguće učitati ovu porodicu. $detail',
    'Diese Familie konnte nicht geladen werden. $detail',
  );

  String get accessNotApproved => _pick(
    'Access not approved',
    'Pristup nije odobren',
    'Zugriff nicht genehmigt',
  );
  String get waitingForParent =>
      _pick('Waiting for parent', 'Čeka roditelja', 'Wartet auf Elternteil');
  String notApprovedBy(String familyName) => _pick(
    '$familyName did not approve this request.',
    '$familyName nije odobrio ovaj zahtjev.',
    '$familyName hat diese Anfrage nicht genehmigt.',
  );
  String opensAfterApproval(String familyName) => _pick(
    '$familyName will open here after a parent approves you.',
    '$familyName će se otvoriti ovdje nakon što te roditelj odobri.',
    '$familyName öffnet sich hier, nachdem ein Elternteil dich genehmigt.',
  );

  String get wallAwake => _pick('Wall awake', 'Zid budan', 'Wand wach');
  String get wallDim => _pick('Wall dim', 'Zid prigušen', 'Wand gedimmt');
  String get cloudReady =>
      _pick('Cloud ready', 'Cloud spreman', 'Cloud bereit');
  String get offline => _pick('Offline', 'Offline', 'Offline');
  String firebaseReady(String? userId) => _pick(
    'Firebase ready${userId == null ? '' : ': $userId'}',
    'Firebase spreman${userId == null ? '' : ': $userId'}',
    'Firebase bereit${userId == null ? '' : ': $userId'}',
  );
  String get cloudServicesOffline => _pick(
    'Cloud services offline: Firebase setup required',
    'Cloud servisi offline: potrebna je Firebase postavka',
    'Cloud-Dienste offline: Firebase-Einrichtung erforderlich',
  );
  String get invite => _pick('Invite', 'Pozivnica', 'Einladung');
  String get familyRequests =>
      _pick('Family requests', 'Porodični zahtjevi', 'Familienanfragen');
  String get approvePeople => _pick(
    'Approve people before they can use this family space.',
    'Odobri ljude prije nego mogu koristiti ovaj porodični prostor.',
    'Genehmige Personen, bevor sie diesen Familienbereich nutzen können.',
  );
  String get reject => _pick('Reject', 'Odbij', 'Ablehnen');
  String get approve => _pick('Approve', 'Odobri', 'Genehmigen');
  String get save => _pick('Save', 'Sačuvaj', 'Speichern');
  String get remove => _pick('Remove', 'Ukloni', 'Entfernen');
  String get userManagement => _pick('People', 'Ljudi', 'Personen');
  String get managePeople => _pick(
    'Manage access, nicknames, and family tags.',
    'Upravljaj pristupom, nadimcima i porodičnim oznakama.',
    'Zugriff, Spitznamen und Familien-Tags verwalten.',
  );
  String get noMembersYet =>
      _pick('No members yet.', 'Još nema članova.', 'Noch keine Mitglieder.');
  String get nickname => _pick('Nickname', 'Nadimak', 'Spitzname');
  String get familyTag =>
      _pick('Family tag', 'Porodična oznaka', 'Familien-Tag');
  String get editMember =>
      _pick('Edit member', 'Uredi člana', 'Mitglied bearbeiten');
  String get removeMember =>
      _pick('Remove member', 'Ukloni člana', 'Mitglied entfernen');
  String get cannotRemoveYourself => _pick(
    'You cannot remove your own parent account here.',
    'Ovdje ne možeš ukloniti svoj roditeljski račun.',
    'Du kannst dein eigenes Elternkonto hier nicht entfernen.',
  );
  String get memberUpdated =>
      _pick('Member updated', 'Član ažuriran', 'Mitglied aktualisiert');
  String couldNotUpdateMember(String detail) => _pick(
    'Could not update member: $detail',
    'Nije moguće ažurirati člana: $detail',
    'Mitglied konnte nicht aktualisiert werden: $detail',
  );
  String get memberRemoved =>
      _pick('Member removed', 'Član uklonjen', 'Mitglied entfernt');
  String couldNotRemoveMember(String detail) => _pick(
    'Could not remove member: $detail',
    'Nije moguće ukloniti člana: $detail',
    'Mitglied konnte nicht entfernt werden: $detail',
  );
  String removeMemberQuestion(String name) =>
      _pick('Remove $name?', 'Ukloniti $name?', '$name entfernen?');
  String get removeMemberBody => _pick(
    'This removes their access and hides them from the child wall. You can invite them again later.',
    'Ovo uklanja njihov pristup i sakriva ih sa dječijeg zida. Možeš ih ponovo pozvati kasnije.',
    'Das entfernt den Zugriff und blendet die Person von der Kinderwand aus. Du kannst sie später wieder einladen.',
  );
  String get familyTimeOpen => _pick(
    'Family time is open',
    'Porodično vrijeme je otvoreno',
    'Familienzeit ist offen',
  );
  String get familyTimeClosed => _pick(
    'Family time is closed',
    'Porodično vrijeme je zatvoreno',
    'Familienzeit ist geschlossen',
  );
  String get wallReadyForTaps => _pick(
    'The wall is ready for child-safe taps.',
    'Zid je spreman za dječije dodire.',
    'Die Wand ist bereit für kindersichere Berührungen.',
  );
  String get wallStaysCalm => _pick(
    'The wall stays calm until you open it.',
    'Zid ostaje miran dok ga ne otvoriš.',
    'Die Wand bleibt ruhig, bis du sie öffnest.',
  );
  String get cameraVisible =>
      _pick('Camera visible', 'Kamera vidljiva', 'Kamera sichtbar');
  String get cameraOff =>
      _pick('Camera off', 'Kamera isključena', 'Kamera aus');
  String get callLive => _pick('Call live', 'Poziv uživo', 'Anruf live');
  String get noCall => _pick('No call', 'Nema poziva', 'Kein Anruf');
  String get startCallForChild => _pick(
    'Start a call for the child',
    'Pokreni poziv za dijete',
    'Anruf für das Kind starten',
  );
  String get chooseWhoAppears => _pick(
    'Choose who appears on the wall.',
    'Izaberi ko se pojavljuje na zidu.',
    'Wähle, wer auf der Wand erscheint.',
  );
  String get startCall => _pick('Start call', 'Pokreni poziv', 'Anruf starten');
  String callPerson(String name) =>
      _pick('Call $name', 'Pozovi $name', '$name anrufen');
  String get liveCall => _pick('Live call', 'Poziv uživo', 'Live-Anruf');
  String get privacyReady =>
      _pick('Privacy ready', 'Privatnost spremna', 'Privatsphäre bereit');
  String callIsOn(String name, CallEndpoint endpoint) => _pick(
    '$name is on ${endpointLabel(endpoint)}.',
    '$name je na ${endpointLabel(endpoint)}.',
    '$name ist auf ${endpointLabel(endpoint)}.',
  );
  String get cameraAndMicOff => _pick(
    'Camera and microphone stay off until a call starts.',
    'Kamera i mikrofon ostaju isključeni dok poziv ne počne.',
    'Kamera und Mikrofon bleiben aus, bis ein Anruf startet.',
  );
  String get familyIsHere =>
      _pick('Family is here', 'Porodica je tu', 'Familie ist da');
  String get nothingBroadcasting => _pick(
    'Nothing is broadcasting',
    'Ništa se ne prenosi',
    'Es wird nichts übertragen',
  );
  String get cameraMarked => _pick(
    'Camera is clearly marked on the wall.',
    'Kamera je jasno označena na zidu.',
    'Die Kamera ist auf der Wand klar markiert.',
  );
  String get wallPrivate => _pick(
    'The wall is private right now.',
    'Zid je sada privatan.',
    'Die Wand ist gerade privat.',
  );
  String get wallCamera => _pick('Wall camera', 'Kamera zida', 'Wandkamera');
  String get end => _pick('End', 'Završi', 'Beenden');
  String get todayOnWall =>
      _pick('Today on the wall', 'Danas na zidu', 'Heute auf der Wand');
  String get automaticWindows => _pick(
    'Automatic windows for family time.',
    'Automatski termini za porodično vrijeme.',
    'Automatische Zeitfenster für Familienzeit.',
  );
  String get todaysLittleChoices => _pick(
    "Today's little choices",
    'Današnji mali izbori',
    'Die kleinen Entscheidungen heute',
  );
  String get childKeepsReaching => _pick(
    'Who the child keeps reaching for.',
    'Koga dijete najčešće bira.',
    'Nach wem das Kind immer wieder greift.',
  );
  String taps(int count) =>
      _pick('$count taps', '$count dodira', '$count Tipps');
  String calls(int count) =>
      _pick('$count calls', '$count poziva', '$count Anrufe');
  String get dangerZone => _pick('Danger zone', 'Opasna zona', 'Gefahrenzone');
  String get resetCleanStart => _pick(
    'Reset this family space for a clean start.',
    'Resetuj ovaj porodični prostor za novi početak.',
    'Diesen Familienbereich für einen Neustart zurücksetzen.',
  );
  String get resetDescription => _pick(
    'Removes all other members, wall contacts, schedules, calls, and stats. Keeps this parent account and rotates invite codes.',
    'Uklanja sve ostale članove, kontakte na zidu, rasporede, pozive i statistiku. Zadržava ovaj roditeljski račun i mijenja kodove pozivnica.',
    'Entfernt alle anderen Mitglieder, Wandkontakte, Zeitpläne, Anrufe und Statistiken. Dieses Elternkonto bleibt erhalten und Einladungscodes werden erneuert.',
  );
  String get resetFamily =>
      _pick('Reset family', 'Resetuj porodicu', 'Familie zurücksetzen');
  String get familySpaceReset => _pick(
    'Family space reset',
    'Porodični prostor resetovan',
    'Familienbereich zurückgesetzt',
  );
  String couldNotResetFamily(String detail) => _pick(
    'Could not reset family space: $detail',
    'Nije moguće resetovati porodični prostor: $detail',
    'Familienbereich konnte nicht zurückgesetzt werden: $detail',
  );
  String get resetFamilySpace => _pick(
    'Reset family space?',
    'Resetovati porodični prostor?',
    'Familienbereich zurücksetzen?',
  );
  String resetFamilyDialog(String familyName) => _pick(
    'This clears $familyName, removes everyone except you, and creates new invite codes.',
    'Ovo briše $familyName, uklanja sve osim tebe i kreira nove kodove pozivnica.',
    'Dies leert $familyName, entfernt alle außer dir und erstellt neue Einladungscodes.',
  );
  String get typeResetToContinue => _pick(
    'Type RESET to continue',
    'Upiši RESET za nastavak',
    'RESET eingeben, um fortzufahren',
  );
  String get reset => _pick('Reset', 'Resetuj', 'Zurücksetzen');
  String copyCode(String label) =>
      _pick('Copy $label code', 'Kopiraj $label kod', '$label-Code kopieren');
  String codeCopied(String label) =>
      _pick('$label code copied', '$label kod kopiran', '$label-Code kopiert');

  String get familyHearthReady => _pick(
    'Family Hearth is ready',
    'Family Hearth je spreman',
    'Family Hearth ist bereit',
  );
  String get callChildWall =>
      _pick('Call child wall', 'Pozovi dječiji zid', 'Kinderwand anrufen');
  String get callRequestSent => _pick(
    'Call request sent',
    'Zahtjev za poziv poslan',
    'Anrufanfrage gesendet',
  );
  String get callApprovalNeeded => _pick(
    'Call approval needed',
    'Potrebno odobrenje poziva',
    'Anrufgenehmigung nötig',
  );
  String familyWantsToCallChildWall(String name) => _pick(
    '$name wants to call the child wall.',
    '$name želi pozvati dječiji zid.',
    '$name möchte die Kinderwand anrufen.',
  );
  String get cameraStaysOffUntilApproved => _pick(
    'Camera and microphone stay off until you approve.',
    'Kamera i mikrofon ostaju isključeni dok ne odobriš.',
    'Kamera und Mikrofon bleiben aus, bis du genehmigst.',
  );
  String get approveCall =>
      _pick('Approve call', 'Odobri poziv', 'Anruf genehmigen');
  String get rejectCall =>
      _pick('Reject call', 'Odbij poziv', 'Anruf ablehnen');
  String get wallOpenForFamilyCalls => _pick(
    'Family time is open. You can call the child wall now.',
    'Porodično vrijeme je otvoreno. Sada možeš pozvati dječiji zid.',
    'Familienzeit ist offen. Du kannst die Kinderwand jetzt anrufen.',
  );
  String get wallClosedForFamilyCalls => _pick(
    'Family time is closed by the parents right now.',
    'Roditelji su trenutno zatvorili porodično vrijeme.',
    'Die Familienzeit ist gerade von den Eltern geschlossen.',
  );
  String get anotherFamilyCallLive => _pick(
    'Another family call is already live.',
    'Drugi porodični poziv je već uživo.',
    'Ein anderer Familienanruf läuft bereits.',
  );
  String get anotherCallWaitingForParent => _pick(
    'Another call request is waiting for a parent.',
    'Drugi zahtjev za poziv čeka roditelja.',
    'Eine andere Anrufanfrage wartet auf ein Elternteil.',
  );
  String get waitingForParentCallApproval => _pick(
    'Waiting for a parent to approve. The camera is still off.',
    'Čeka se da roditelj odobri. Kamera je još isključena.',
    'Warte auf Genehmigung eines Elternteils. Die Kamera ist noch aus.',
  );
  String connectedWith(String name) =>
      _pick('Connected with $name', 'Povezano s $name', 'Verbunden mit $name');
  String get callSimpleFocused => _pick(
    'The call stays simple and focused.',
    'Poziv ostaje jednostavan i fokusiran.',
    'Der Anruf bleibt einfach und fokussiert.',
  );
  String get incomingControlsComing => _pick(
    'Incoming accept and reject controls come next.',
    'Sljedeće dolaze kontrole za prihvatanje i odbijanje poziva.',
    'Als Nächstes kommen Annehmen- und Ablehnen-Steuerungen.',
  );

  String get playroom => _pick('Playroom', 'Igraonica', 'Spielzimmer');
  String get clearPlay => _pick('Clear play', 'Očisti igru', 'Spiel leeren');
  String get playroomReady => _pick(
    'Send a little moment to the wall.',
    'Pošalji mali trenutak na zid.',
    'Schicke einen kleinen Moment an die Wand.',
  );
  String playActivityLabel(PlayActivity activity) => switch (activity) {
    PlayActivity.babyBeats => _pick('Boom', 'Bum', 'Bumm'),
    PlayActivity.peekaboo => _pick('Peekaboo', 'Kuku', 'Kuckuck'),
    PlayActivity.bubbles => _pick('Bubbles', 'Balončići', 'Blasen'),
    PlayActivity.clapAlong => _pick('Move', 'Pokret', 'Bewegen'),
    PlayActivity.animalSounds => _pick('Animals', 'Životinje', 'Tiere'),
  };
  String playTargetLabel(String key) => switch (key) {
    'boom' => _pick('Boom', 'Bum', 'Bumm'),
    'ding' => _pick('Ding', 'Ding', 'Ding'),
    'whoosh' => _pick('Whoosh', 'Fiju', 'Wusch'),
    'peekaboo' => _pick('Peekaboo', 'Kuku', 'Kuckuck'),
    'hello' => _pick('Hello', 'Ćao', 'Hallo'),
    'smile' => _pick('Smile', 'Osmijeh', 'Lächeln'),
    'bubbles' => _pick('Bubbles', 'Balončići', 'Blasen'),
    'stars' => _pick('Stars', 'Zvjezdice', 'Sterne'),
    'rainbow' => _pick('Rainbow', 'Duga', 'Regenbogen'),
    'clap' => _pick('Clap', 'Pljesak', 'Klatschen'),
    'wave' => _pick('Wave', 'Mahni', 'Winken'),
    'dance' => _pick('Dance', 'Ples', 'Tanzen'),
    'dog' => _pick('Dog', 'Cuko', 'Hund'),
    'cat' => _pick('Cat', 'Maca', 'Katze'),
    'cow' => _pick('Cow', 'Krava', 'Kuh'),
    _ => key,
  };
  String playWallMoment(PlayActivity activity, String target) =>
      switch (activity) {
        PlayActivity.babyBeats => '$target!',
        PlayActivity.peekaboo => '$target!',
        PlayActivity.bubbles => '$target!',
        PlayActivity.clapAlong => '$target!',
        PlayActivity.animalSounds => '$target!',
      };
  String get playWallTapHint =>
      _pick('Tap anywhere', 'Dodirni bilo gdje', 'Irgendwo tippen');
  String get playWallBabyJoined => _pick('Again!', 'Još!', 'Nochmal!');
  String get playWaitingForChild => _pick(
    'Waiting for a tiny tap.',
    'Čekam mali dodir.',
    'Warte auf einen kleinen Tipp.',
  );
  String get playChildResponded =>
      _pick('Baby touched it.', 'Beba je dodirnula.', 'Baby hat getippt.');

  String get hangUp => _pick('Hang up', 'Prekini', 'Auflegen');
  String get firebaseSignalingOffline => _pick(
    'Firebase signaling is not connected yet',
    'Firebase signalizacija još nije povezana',
    'Firebase-Signalisierung ist noch nicht verbunden',
  );
  String get firebaseSignalingHelp => _pick(
    'Add Firebase config and auth, then this screen will exchange WebRTC offer, answer, and ICE candidates through Firestore.',
    'Dodaj Firebase konfiguraciju i autentifikaciju, zatim će ovaj ekran razmjenjivati WebRTC offer, answer i ICE kandidate kroz Firestore.',
    'Füge Firebase-Konfiguration und Authentifizierung hinzu; danach tauscht dieser Bildschirm WebRTC Offer, Answer und ICE-Kandidaten über Firestore aus.',
  );
}
