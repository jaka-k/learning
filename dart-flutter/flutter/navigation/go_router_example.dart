// NOT RUNNABLE STANDALONE — Flutter learning reference file.
// Requires a Flutter project with go_router dependency in pubspec.yaml:
//   dependencies:
//     go_router: ^14.0.0   # check pub.dev for latest
//
// This file covers go_router comprehensively with heavy inline comments.

// ============================================================
// PACKAGE OVERVIEW
// ============================================================
//
// go_router is the Flutter-team-maintained routing package built on top of
// Navigator 2.0. It handles the RouterDelegate / RouteInformationParser
// boilerplate for you and exposes a clean, declarative route table.
//
// Key capabilities:
//   • Path templates:  /user/:id
//   • Query params:    /search?q=flutter
//   • Redirects:       per-route or global (great for auth guards)
//   • ShellRoute:      shared UI shell (e.g., bottom nav bar) across routes
//   • Named routes:    navigate by name instead of path string
//   • Deep links:      works on web, Android, iOS out of the box
//   • Error page:      single errorBuilder for all 404s

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ============================================================
// AUTH STATE (simple mock — replace with your real state)
// ============================================================
//
// In a real app this would be a ChangeNotifier / Riverpod provider / BLoC.
// go_router's refreshListenable hooks into a Listenable so the router
// re-evaluates redirects whenever auth state changes.

class AuthState extends ChangeNotifier {
  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  void logIn() {
    _loggedIn = true;
    notifyListeners(); // go_router listens to this and re-runs redirect
  }

  void logOut() {
    _loggedIn = false;
    notifyListeners();
  }
}

// Create a singleton for this example. In production: use a DI framework.
final authState = AuthState();

// ============================================================
// ROUTE NAMES — use constants to avoid typo bugs
// ============================================================
//
// Named routes let you navigate by name rather than hard-coding path strings.
// This is safer: if you rename /profile to /user, you only change one place.

class Routes {
  static const home = 'home';
  static const login = 'login';
  static const profile = 'profile';
  static const settings = 'settings';
  static const notFound = 'not-found';
}

// ============================================================
// GOROUTER SETUP
// ============================================================
//
// GoRouter is typically created once and stored at app level. Keep it outside
// build() so it is not recreated on every rebuild.

final GoRouter router = GoRouter(
  // initialLocation — the path shown when the app first starts (or when no
  // deep link is provided). Defaults to '/'.
  initialLocation: '/',

  // debugLogDiagnostics — prints every navigation event to the console.
  // Very helpful during development; disable for production.
  debugLogDiagnostics: true,

  // refreshListenable — GoRouter will call redirect() every time this
  // Listenable fires. Wire it to your auth state so the router automatically
  // re-evaluates the guard when the user logs in/out.
  refreshListenable: authState,

  // ----------------------------------------------------------------
  // GLOBAL REDIRECT — auth guard
  // ----------------------------------------------------------------
  // redirect is called before every navigation, including the initial route.
  // Return null to allow the navigation. Return a path string to redirect.
  //
  // state.matchedLocation is the path actually being navigated to.
  // state.uri.toString() is the full URI (path + query string).
  redirect: (BuildContext context, GoRouterState state) {
    final loggedIn = authState.loggedIn;
    final goingToLogin = state.matchedLocation == '/login';

    // If the user is not logged in and is NOT going to the login page,
    // redirect to login. Preserve the intended destination so we can
    // redirect back after login.
    if (!loggedIn && !goingToLogin) {
      // Encode the originally requested path as a query parameter so the
      // login page can redirect back after a successful login.
      final from = Uri.encodeComponent(state.uri.toString());
      return '/login?from=$from';
    }

    // If the user is already logged in and tries to go to /login,
    // redirect to home to avoid showing the login screen again.
    if (loggedIn && goingToLogin) return '/';

    // null means "allow this navigation — no redirect needed"
    return null;
  },

  // errorBuilder — shown for any route that cannot be matched (404) or when
  // a builder throws. This is the single place to handle all routing errors.
  errorBuilder: (context, state) {
    // state.error contains the exception (typically a GoException).
    // state.uri is the URL that could not be resolved.
    return NotFoundPage(uri: state.uri.toString());
  },

  // ----------------------------------------------------------------
  // ROUTES LIST — the entire route table
  // ----------------------------------------------------------------
  routes: [

    // ----------------------------------------------------------
    // GoRoute — the basic building block
    // ----------------------------------------------------------
    GoRoute(
      // path is a URL template. Segments starting with : are parameters.
      path: '/login',
      name: Routes.login,
      builder: (context, state) {
        // state.uri.queryParameters gives you the parsed query params map.
        final from = state.uri.queryParameters['from'];
        return LoginPage(redirectTo: from);
      },
    ),

    // ----------------------------------------------------------
    // ShellRoute — persistent UI shell (bottom nav bar, drawer, etc.)
    // ----------------------------------------------------------
    // ShellRoute wraps a set of child routes in a common scaffold.
    // The child routes are rendered inside the shell — navigating between
    // them does NOT rebuild the shell widget (great for bottom nav bars).
    //
    // IMPORTANT: ShellRoute uses a SEPARATE Navigator for its children.
    // This means:
    //   • Back button pops within the shell's navigator first.
    //   • The shell itself stays alive (StatefulShellRoute variant can also
    //     keep each tab's state alive — see below).

    ShellRoute(
      builder: (context, state, child) {
        // `child` is the currently active child route's widget.
        // Wrap it in your persistent shell UI.
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: Routes.home,
          builder: (context, state) => const HomePage(),

          // ----------------------------------------------------------
          // NESTED ROUTES — child routes under a parent
          // ----------------------------------------------------------
          // A child route's full path is parent + child: '/profile/:id'
          // The parent page stays in the navigator stack below.
          routes: [
            GoRoute(
              // Relative path — the leading slash is OMITTED for children.
              // Full resolved path: /profile/:id
              path: 'profile/:id',
              name: Routes.profile,
              builder: (context, state) {
                // PATH PARAMETERS — access via state.pathParameters
                // The key matches the :id template token.
                final id = state.pathParameters['id']!;

                // QUERY PARAMETERS — access via state.uri.queryParameters
                // e.g., /profile/42?tab=posts → tab == 'posts'
                final tab = state.uri.queryParameters['tab'] ?? 'overview';

                return ProfilePage(userId: id, initialTab: tab);
              },

              // Per-route redirect — runs AFTER the global redirect.
              // Use for route-specific guards (e.g., admin-only pages).
              redirect: (context, state) {
                // Example: only allow access to profiles with numeric IDs.
                final id = state.pathParameters['id']!;
                if (int.tryParse(id) == null) {
                  // Not a valid numeric ID — redirect to home.
                  return '/';
                }
                return null; // allow
              },
            ),
          ],
        ),

        GoRoute(
          path: '/settings',
          name: Routes.settings,
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);

// ============================================================
// MaterialApp.router — plug GoRouter into the app
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'go_router Demo',
      // routerConfig is the single-argument shorthand for MaterialApp.router.
      // It accepts GoRouter directly (which implements RouterConfig).
      routerConfig: router,
    );
  }
}

// ============================================================
// NAVIGATION METHODS — context.go vs context.push vs context.replace
// ============================================================
//
// context.go('/path')
//   • REPLACES the entire navigator stack with the new route.
//   • Back button has nowhere to go (unless the route has ancestor routes
//     derived from the path hierarchy).
//   • Use for tab switches and main-flow navigation where you don't want
//     the previous page in the back stack.
//   • Corresponds to "navigate to" semantics.
//
// context.push('/path')
//   • PUSHES on top of the current stack (like Navigator.push).
//   • Back button returns to the previous page.
//   • Use for drill-down navigation (list → detail).
//
// context.replace('/path')
//   • Replaces the TOP entry of the current stack with the new route.
//   • The page below is unchanged.
//   • Use when you want to swap the current page without affecting the
//     back-stack depth (e.g., after a successful form submission, replace
//     the form page with a success page so back doesn't re-show the form).
//
// context.goNamed('routeName', pathParameters: {'id': '42'})
//   • Same as go() but uses the route's `name:` parameter.
//   • pathParameters fills in :tokens in the path template.
//   • queryParameters are appended as ?key=value.
//
// context.pushNamed('routeName', pathParameters: {}, extra: myObject)
//   • extra lets you pass arbitrary Dart objects that are NOT serialized
//     to the URL. Useful for complex objects (e.g., an already-fetched model).
//   • CAVEAT: extra does NOT survive app restarts / URL copy-paste on web.
//     Use path/query params for anything that must be deep-linkable.
//
// context.pop()       — pops the top route (same as Navigator.pop)
// context.pop(result) — pops and returns a value to the caller

// ============================================================
// READING PARAMS IN BUILDERS — GoRouterState
// ============================================================
//
// GoRouterState is provided to every builder and redirect callback.
// Most useful fields:
//   state.uri              — full Uri of the current location
//   state.matchedLocation  — the portion of the path matched so far
//   state.pathParameters   — Map<String, String> of :param values
//   state.uri.queryParameters — Map<String, String> of ?key=value pairs
//   state.extra            — the `extra` object passed via push/go
//   state.error            — set in errorBuilder when routing fails
//   state.name             — the matched route's `name:` if set

// ============================================================
// GETTING GOROUTER STATE INSIDE A WIDGET (not in builder)
// ============================================================
//
// Use GoRouterState.of(context) to read the current route state anywhere in
// the tree BELOW a GoRoute's page widget.

class ProfilePage extends StatelessWidget {
  final String userId;
  final String initialTab;
  const ProfilePage({super.key, required this.userId, required this.initialTab});

  @override
  Widget build(BuildContext context) {
    // You can also read state here if you didn't pass it via constructor:
    // final state = GoRouterState.of(context);
    // final id = state.pathParameters['id']!;

    return Scaffold(
      appBar: AppBar(title: Text('Profile: $userId')),
      body: Column(
        children: [
          Text('Tab: $initialTab'),
          ElevatedButton(
            onPressed: () {
              // context.pop with a result value — the caller receives 'done'
              // if they used await context.push('/profile/$userId').
              context.pop('done');
            },
            child: const Text('Back with result'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CONTEXT.PUSH WITH ASYNC RESULT
// ============================================================

Future<void> navigateAndGetResult(BuildContext context) async {
  // push returns a Future that completes when the pushed route is popped.
  // The type parameter matches what pop() passes back.
  final result = await context.push<String>('/profile/42');

  // result is null if the user used the back button without passing a value.
  if (result == 'done') {
    // handle result
  }
}

// ============================================================
// STATEFULSHELLROUTE — keep each tab's state alive
// ============================================================
//
// Regular ShellRoute rebuilds the child when you switch tabs.
// StatefulShellRoute keeps a separate navigator (and therefore state) per
// branch, so switching tabs does NOT lose scroll position or loaded data.
//
// Each branch corresponds to one tab in your bottom nav.

final GoRouter routerWithStatefulShell = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      // builder receives the shell navigator and the current branch index.
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (c, s) => const HomePage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/settings', builder: (c, s) => const SettingsPage()),
          ],
        ),
      ],
    ),
  ],
);

// ============================================================
// DEEP LINK HANDLING
// ============================================================
//
// On mobile, register your URI scheme / App Links in the platform config:
//   Android: AndroidManifest.xml intent-filter with your scheme
//   iOS: Info.plist CFBundleURLTypes or Associated Domains
//
// go_router automatically picks up the initial URI from the platform via
// PlatformRouteInformationProvider (the default). No extra code needed in
// the router itself — just make sure your route table can parse the path.
//
// For testing deep links on the CLI:
//   Android:  adb shell am start -a android.intent.action.VIEW \
//               -d "myapp://example.com/profile/42" com.example.myapp
//   iOS:      xcrun simctl openurl booted "myapp://profile/42"

// ============================================================
// PLACEHOLDER WIDGETS (enough to make the router code above sensible)
// ============================================================

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // go() replaces the stack — correct for tab switching.
              context.goNamed(Routes.home);
            case 1:
              context.goNamed(Routes.settings);
          }
        },
      ),
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell, // renders the active branch
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          // goBranch switches tabs without rebuilding the branch's subtree.
          navigationShell.goBranch(
            index,
            // initialLocation: true resets the branch to its root path
            // when the user taps the already-active tab (common UX pattern).
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  final String? redirectTo;
  const LoginPage({super.key, this.redirectTo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            authState.logIn();
            // After login, navigate to the originally requested URL (if any)
            // or fall back to home. go() replaces the login page.
            if (redirectTo != null) {
              context.go(Uri.decodeComponent(redirectTo!));
            } else {
              context.go('/');
            }
          },
          child: const Text('Log in'),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Profile 42 (push — back button works)'),
            onTap: () => context.pushNamed(
              Routes.profile,
              pathParameters: {'id': '42'},
              queryParameters: {'tab': 'posts'}, // → /profile/42?tab=posts
            ),
          ),
          ListTile(
            title: const Text('Settings (go — replaces stack)'),
            onTap: () => context.goNamed(Routes.settings),
          ),
          ListTile(
            title: const Text('Pass an object via extra (not URL-safe)'),
            onTap: () {
              // extra can be any Dart object. It is NOT in the URL.
              context.push('/profile/42', extra: {'prefetched': true});
            },
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            authState.logOut();
            // refreshListenable fires → redirect() runs → sends to /login
          },
          child: const Text('Log out'),
        ),
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  final String uri;
  const NotFoundPage({super.key, required this.uri});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('404 — Not found: $uri')),
    );
  }
}
