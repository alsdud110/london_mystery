import '../../data/sync/sync_policy.dart';

/// The Firebase project a build talks to. Android flavors pick it: `dev`
/// (com.londonmystery.app.dev) and `prod` (com.londonmystery.app). Each
/// flavor carries its own `google-services.json` (see
/// docs/PHASE3A_FIREBASE_AUTH_PLAN.md).
enum CloudEnvironment {
  dev(projectId: 'london-mystery-dev', androidAppId: '1:332839632440:android:588c5bb067eae260a0f0cd'),
  prod(projectId: 'london-mystery-prod', androidAppId: '1:784365257039:android:145e45d51b61156552053a');

  const CloudEnvironment({required this.projectId, required this.androidAppId});

  /// The project and app this environment must start with. Public
  /// identifiers, not secrets: checked after start, so a build that was
  /// handed the other environment's settings never uses them.
  final String projectId;
  final String androidAppId;

  /// Whether new accounts may be made. Signing up collects an email address;
  /// in Korea a child under 14 needs a legal guardian's consent for that, and
  /// the procedure is not decided yet: only the DEV project takes sign-ups.
  bool get signUpOpen => this == dev;

  /// Whether the account pages are offered at all. PROD's email sign-in is
  /// turned off on the server (2026-10-13) until the consent procedure is
  /// decided, so its builds show no Sign in / My account and open no account
  /// page.
  bool get accountsShown => this == dev;

  /// Whether an account (and its cloud documents) can be deleted from the
  /// app. Needs a trusted server path that deletes both together (see
  /// docs/PHASE3B_ACCOUNT_UI_PLAN.md §6); until it exists, never.
  bool get accountDeletionAvailable => false;

  /// The environment of a build flavor (`appFlavor`), or null (no flavor:
  /// tests, web, desktop; or an unknown one).
  static CloudEnvironment? ofFlavor(String? flavor) => switch (flavor) {
        'dev' => dev,
        'prod' => prod,
        _ => null,
      };
}

/// Why a build does not start Firebase at all.
enum CloudBlock {
  /// No or unknown flavor.
  noEnvironment,

  /// Only Android is set up (iOS later, on a Mac; web and desktop play as
  /// guests only).
  unsupportedPlatform,

  /// A build with operator tools (debug, `LM_PLAYTEST`) was given the
  /// production project: it must never reach it.
  operatorBuildOnProduction,
}

/// Whether and with which project a build may start Firebase.
class CloudDecision {
  const CloudDecision.start(CloudEnvironment this.environment) : block = null;

  const CloudDecision.blocked(CloudBlock this.block) : environment = null;

  final CloudEnvironment? environment;
  final CloudBlock? block;

  bool get allowed => environment != null;

  /// Decides from the build itself (pure, so every case is testable).
  static CloudDecision of({
    required String? flavor,
    required bool androidApp,
    required bool operatorToolsInBuild,
  }) {
    final env = CloudEnvironment.ofFlavor(flavor);
    if (env == null) return const CloudDecision.blocked(CloudBlock.noEnvironment);
    if (!androidApp) return const CloudDecision.blocked(CloudBlock.unsupportedPlatform);
    if (env == CloudEnvironment.prod &&
        !SyncPolicy.buildMayUseLiveCloud(operatorToolsInBuild: operatorToolsInBuild)) {
      return const CloudDecision.blocked(CloudBlock.operatorBuildOnProduction);
    }
    return CloudDecision.start(env);
  }
}
