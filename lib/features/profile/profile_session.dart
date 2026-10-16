import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../data/models/profile.dart';
import '../../data/repositories/profile_store.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';

/// Runs the game for one detective at a time. Each profile gets a container
/// of its own, so switching drops everything of the one before: its case,
/// season and wallet state, the router and its pages, and the passes given
/// for one visit (game master, parent report, operator access).
///
/// There is no screen that switches yet (one guest per device); account
/// profiles will use [ProfileSessionHostState.switchTo].
class ProfileSessionHost extends StatefulWidget {
  const ProfileSessionHost({
    super.key,
    required this.session,
    required this.overrides,
    required this.child,
    this.signedInUid = _nobody,
    this.onSessionStarted,
  });

  /// The profile to start with (from [ProfileStore.bootstrap]).
  final ProfileSession session;

  /// Given to every session's container (shared preferences, content).
  final List<Override> overrides;
  final Widget child;

  /// The signed-in user's id now (null: none). An account's profile opens
  /// only for that account (see [DetectiveProfile.mayOpen]).
  final String? Function() signedInUid;

  static String? _nobody() => null;

  /// Told each time a profile's session starts (the first one included),
  /// with its container (e.g. for the cloud sync to follow it).
  final void Function(ProviderContainer container)? onSessionStarted;

  static ProfileSessionHostState of(BuildContext context) =>
      context.findAncestorStateOfType<ProfileSessionHostState>()!;

  @override
  State<ProfileSessionHost> createState() => ProfileSessionHostState();
}

class ProfileSessionHostState extends State<ProfileSessionHost> {
  late ProfileSession _session = widget.session;
  late ProviderContainer _container = _create(_session);

  @override
  void initState() {
    super.initState();
    widget.onSessionStarted?.call(_container);
  }

  ProviderContainer _create(ProfileSession session) =>
      ProviderContainer(overrides: [...widget.overrides, profileSessionProvider.overrideWithValue(session)]);

  ProfileSession get session => _session;

  /// The running session's container (for tests).
  ProviderContainer get container => _container;

  /// Plays [profileId] from now on. The play time of the profile being left
  /// is saved first; its container is thrown away once the new one is on
  /// screen.
  ///
  /// Refused (StateError) for an account's profile while that account is not
  /// signed in: another account's data never opens.
  Future<void> switchTo(String profileId) async {
    if (profileId == _session.profileId) return;
    final old = _container;
    final store = old.read(profileStoreProvider);
    final DetectiveProfile next = store.profile(profileId) ?? (throw ArgumentError.value(profileId, 'profileId'));
    if (!next.mayOpen(widget.signedInUid())) throw StateError('this profile belongs to an account that is not signed in');
    old.read(gameControllerProvider.notifier).pausePlayClock();
    await store.setActive(profileId);
    if (!mounted) return;
    setState(() {
      _session = ProfileSession(profile: next);
      _container = _create(_session);
    });
    widget.onSessionStarted?.call(_container);
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  /// After the user signs out (or another user signs in): a profile that may
  /// no longer be opened is closed and the guest plays. Its saves stay on the
  /// device, locked until its account signs in again.
  Future<void> enforceAccess() async {
    if (_session.profile.mayOpen(widget.signedInUid())) return;
    final guest = _container.read(profileStoreProvider).guest;
    if (guest != null) await switchTo(guest.id);
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(
        key: ValueKey(_session.profileId),
        container: _container,
        child: widget.child,
      );
}
