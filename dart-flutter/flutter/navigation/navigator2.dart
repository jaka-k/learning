// NOT RUNNABLE STANDALONE — Flutter learning reference file.
// Requires a Flutter project with MaterialApp/Router setup.
// This file covers Navigator 2.0 (the Router API) with heavy inline comments.

// ============================================================
// WHY NAVIGATOR 2.0 EXISTS
// ============================================================
//
// Navigator 1.0 (push/pop) was designed for mobile apps where the OS controls
// the back button and there are no deep links to reason about. It falls apart
// when you need:
//
//   1. Deep linking — a user taps a push notification and lands on
//      /profile/42/settings. Navigator 1.0 had no standard way to parse a
//      URL and produce the correct stack of routes.
//
//   2. Web URL sync — the browser's address bar must reflect the current page.
//      With Navigator 1.0, the URL never changes; the browser back button
//      therefore cannot work correctly.
//
//   3. Full back-button control — on Android and Web you may want to intercept
//      the back button and do custom logic (e.g., confirm before leaving a form)
//      rather than always popping the top route.
//
//   4. Declarative route stack — describe *what* the stack should look like
//      rather than issuing imperative push/pop commands. This fits Flutter's
//      reactive model much better.
//
// Navigator 2.0 was introduced in Flutter 1.22 (2020) to solve all four.
// It is deliberately low-level; most teams use go_router (see go_router_example.dart)
// or auto_route on top of it.

// ============================================================
// THE THREE MAIN PIECES
// ============================================================
//
//  ┌─────────────────────────────────────────────────────────┐
//  │  Router widget                                          │
//  │  - Sits where you would normally put MaterialApp's      │
//  │    `home:` argument (or replaces MaterialApp entirely   │
//  │    if you use MaterialApp.router).                      │
//  │  - Holds references to:                                 │
//  │      • RouterDelegate         (what to display)         │
//  │      • RouteInformationParser (URL ↔ app-state)         │
//  │      • BackButtonDispatcher   (hardware back key)       │
//  └─────────────────────────────────────────────────────────┘
//
//  RouterDelegate<T>
//  - T is your app's "configuration" type — a plain Dart object that describes
//    which page(s) should be visible (e.g., a custom AppRoutePath class).
//  - The framework calls setNewRoutePath(T config) when the URL changes
//    (e.g., user types a URL in the browser, or an OS deep-link fires).
//  - The framework calls build() to get a Navigator widget whose `pages:` list
//    is derived from the current configuration.
//  - currentConfiguration getter is polled to push the current state back
//    into the URL bar.
//
//  RouteInformationParser<T>
//  - Converts between RouteInformation (basically a URL string + state blob)
//    and your configuration type T.
//  - parseRouteInformation()  →  URL → T
//  - restoreRouteInformation() → T → URL   (optional but needed for web)

import 'package:flutter/material.dart';

// ============================================================
// STEP 1 — Define your route configuration type
// ============================================================
//
// This is a plain Dart class that captures everything needed to reconstruct
// the page stack. Keep it immutable; treat it like a value object.

class AppRoutePath {
  final String? userId;  // null → show home page
  final bool isUnknown;  // true → show 404 page

  const AppRoutePath.home()
      : userId = null,
        isUnknown = false;

  const AppRoutePath.profile(this.userId) : isUnknown = false;

  const AppRoutePath.unknown()
      : userId = null,
        isUnknown = true;

  bool get isHomePage => userId == null && !isUnknown;
  bool get isProfilePage => userId != null;
}

// ============================================================
// STEP 2 — RouteInformationParser
// ============================================================
//
// Think of this as the "URL codec" for your router.
// It is stateless — do not store mutable state here.

class AppRouteInformationParser
    extends RouteInformationParser<AppRoutePath> {

  // parseRouteInformation is called by the framework when:
  //   • The app first starts (initial URL from the OS / browser)
  //   • The browser's address bar changes (web only)
  //   • A platform deep-link fires (mobile)
  //
  // RouteInformation.uri contains the URI. The older .location string
  // property is deprecated; prefer .uri.
  @override
  Future<AppRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final uri = routeInformation.uri;

    // "/" → home
    if (uri.pathSegments.isEmpty) return const AppRoutePath.home();

    // "/profile/:id"
    if (uri.pathSegments.length == 2 &&
        uri.pathSegments[0] == 'profile') {
      final id = uri.pathSegments[1];
      // Validate the id; return unknown if malformed.
      if (id.isEmpty) return const AppRoutePath.unknown();
      return AppRoutePath.profile(id);
    }

    return const AppRoutePath.unknown();
  }

  // restoreRouteInformation is the inverse: given a configuration, produce
  // the RouteInformation (URL) that the browser bar should show.
  // If you skip this, the URL bar never updates (fine for pure mobile).
  @override
  RouteInformation? restoreRouteInformation(AppRoutePath configuration) {
    if (configuration.isUnknown) {
      return RouteInformation(uri: Uri.parse('/404'));
    }
    if (configuration.isHomePage) {
      return RouteInformation(uri: Uri.parse('/'));
    }
    if (configuration.isProfilePage) {
      return RouteInformation(
          uri: Uri.parse('/profile/${configuration.userId}'));
    }
    return null;
  }
}

// ============================================================
// STEP 3 — RouterDelegate
// ============================================================
//
// This is the brain. It:
//   • Stores the current route path (mutable state).
//   • Builds the Navigator widget with the correct pages list.
//   • Reacts to setNewRoutePath() calls from the system.
//
// ChangeNotifier mixin is required — the framework listens to it and rebuilds
// the Router when notifyListeners() is called.

class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {

  // PopNavigatorRouterDelegateMixin requires a GlobalKey<NavigatorState>.
  // The mixin's default popRoute() implementation uses this key to call
  // Navigator.maybePop(). Provide it here.
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Internal state: the current "path" the app is showing.
  AppRoutePath _currentPath = const AppRoutePath.home();

  // currentConfiguration is polled by the framework to get the URL for the
  // address bar. It is called after every build.
  @override
  AppRoutePath get currentConfiguration => _currentPath;

  // ---- Public navigation methods (imperative API surface) ----

  void goHome() {
    _currentPath = const AppRoutePath.home();
    notifyListeners(); // triggers rebuild + URL update
  }

  void goProfile(String userId) {
    _currentPath = AppRoutePath.profile(userId);
    notifyListeners();
  }

  // ---- Framework-called methods ----

  // setNewRoutePath is called when the system provides a new URL:
  //   • Browser navigation (forward/back, typed URL)
  //   • OS deep-link
  //   • Programmatic Router.of(context).routeInformationProvider.value = ...
  //
  // IMPORTANT: this is async. Heavy async work (e.g., checking auth) can be
  // done here. Until the future completes, the Router shows the previous state.
  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    _currentPath = configuration;
    // No need to call notifyListeners() here; the framework handles the rebuild.
  }

  // build() returns a Navigator whose `pages:` list is derived from the
  // current configuration. THIS IS THE HEART OF NAVIGATOR 2.0.
  //
  // The `pages:` parameter is the *declarative* route stack. The Navigator
  // diffs the old list against the new list and animates accordingly.
  // Each Page must have a stable `key` so the diff works correctly.
  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        // The home page is always in the stack (it's the root).
        const MaterialPage(
          key: ValueKey('home-page'),
          child: HomePage(),
        ),

        // Profile page is pushed ON TOP of home when the path says so.
        if (_currentPath.isProfilePage)
          MaterialPage(
            // IMPORTANT: Use a key that includes the dynamic data so Flutter
            // can tell apart /profile/1 from /profile/2. Without this, the
            // Navigator might reuse the same page instance and skip the
            // transition animation.
            key: ValueKey('profile-${_currentPath.userId}'),
            child: ProfilePage(userId: _currentPath.userId!),
          ),

        // 404 page — note it replaces the stack (no home underneath).
        // We model this by only showing it and NOT including home.
        // Adjust to your UX needs.
        if (_currentPath.isUnknown)
          const MaterialPage(
            key: ValueKey('unknown-page'),
            child: UnknownPage(),
          ),
      ],

      // onDidRemovePage is the Navigator 2.0 replacement for onPopPage (which
      // was deprecated in Flutter 3.22). It is called when a page is removed
      // from the stack, e.g., the user taps the system back button.
      //
      // You MUST update your state here; otherwise, the Navigator will
      // re-insert the page on the next build (creating an infinite loop).
      onDidRemovePage: (Page<dynamic> page) {
        // When the profile page is popped, go back to home.
        if (page.key == ValueKey('profile-${_currentPath.userId}')) {
          goHome();
        }
      },
    );
  }
}

// ============================================================
// PAGE API
// ============================================================
//
// A Page<T> is an immutable description of a route. It is NOT a widget; it is
// the *recipe* for creating a Route. The Navigator creates and manages the
// actual Route objects internally.
//
// Built-in pages:
//   • MaterialPage     — uses MaterialPageRoute (slide-up on Android/iOS)
//   • CupertinoPage    — uses CupertinoPageRoute (iOS-style slide from right)
//
// Custom Page subclass — use when you need a custom transition or want to
// carry extra metadata on the route.

class FadeInPage<T> extends Page<T> {
  final Widget child;

  const FadeInPage({
    required this.child,
    required super.key,
    super.name,       // optional: human-readable name for debugging
    super.arguments,  // optional: arbitrary data attached to the route
  });

  // createRoute() is called by the Navigator when it actually needs to show
  // this page. Return a PageRoute whose buildPage() uses this page's child.
  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this, // IMPORTANT: pass `this` as settings so the route
                      // is linked to this Page. Without it, the Navigator
                      // cannot match pages to routes during diffing.
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

// ============================================================
// BACKBUTTONDISPATCHER
// ============================================================
//
// BackButtonDispatcher routes the hardware/browser back button press to the
// correct router when you have nested routers.
//
// For a single top-level Router, the framework automatically wires up
// RootBackButtonDispatcher. You only need to think about this when:
//   • You have nested Router widgets (e.g., bottom nav tabs each with their
//     own Router). The inner routers should use ChildBackButtonDispatcher.
//   • You want to intercept the back button globally.
//
// Example of a nested setup:

class NestedRouterDemo extends StatefulWidget {
  const NestedRouterDemo({super.key});
  @override
  State<NestedRouterDemo> createState() => _NestedRouterDemoState();
}

class _NestedRouterDemoState extends State<NestedRouterDemo> {
  final BackButtonDispatcher _backButtonDispatcher =
      ChildBackButtonDispatcher(Router.of(
          // This context must be inside a Router; typically you obtain
          // the parent dispatcher via Router.of(context).backButtonDispatcher.
          // Shown here for illustration.
          // ignore: invalid_use_of_protected_member
          null as BuildContext)); // placeholder — not compilable as-is

  @override
  void initState() {
    super.initState();
    // You must "take priority" for the back button; otherwise the parent
    // Router handles it.
    _backButtonDispatcher.takePriority();
  }

  @override
  void dispose() {
    // Release priority when the inner router is gone.
    _backButtonDispatcher.forget();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(); // placeholder
  }
}

// ============================================================
// IMPERATIVE API STILL WORKS INSIDE ROUTER
// ============================================================
//
// Inside any widget that's a descendant of the Navigator built by your
// RouterDelegate, the old Navigator.of(context).push(...) / .pop() still works.
//
// This is useful for:
//   • Modal dialogs (showDialog uses Navigator.push internally)
//   • Bottom sheets
//   • Quick sub-flows that don't need URL representation
//
// CAVEAT: Imperative pushes do NOT update the URL bar and are NOT reflected in
// currentConfiguration. If the user refreshes the browser, the imperatively
// pushed routes disappear. Use the declarative Pages API for anything that
// should survive a refresh.

void imperativeExample(BuildContext context) {
  // Still works! Opens a dialog on top of whatever the declarative stack shows.
  showDialog<void>(
    context: context,
    builder: (_) => const AlertDialog(title: Text('Hello from imperative API')),
  );

  // Or a named route defined with the Navigator's `onGenerateRoute`:
  Navigator.of(context).pushNamed('/some-modal');
}

// ============================================================
// WIRING IT ALL TOGETHER — MaterialApp.router
// ============================================================
//
// MaterialApp.router is the standard way to use Navigator 2.0. It creates
// the Router widget and also gives you Material theming, localizations, etc.

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Keep delegate alive — do NOT create it inside build(). The delegate holds
  // mutable state; recreating it on every build would lose navigation state.
  final _routerDelegate = AppRouterDelegate();
  final _routeInformationParser = AppRouteInformationParser();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Navigator 2.0 Demo',

      // routerDelegate — provides the Navigator / page stack.
      routerDelegate: _routerDelegate,

      // routeInformationParser — translates URLs ↔ configuration.
      // On mobile, you can omit this (no URL bar), but it's needed for web
      // and for OS deep-link support on mobile.
      routeInformationParser: _routeInformationParser,

      // routeInformationProvider — optional. The default is
      // PlatformRouteInformationProvider which reads the initial route from
      // the platform and listens for deep links. You can supply a custom one
      // for testing (e.g., provide a fixed initial URL).

      debugShowCheckedModeBanner: false,
    );
  }
}

// ============================================================
// PLACEHOLDER SCREENS (to make the delegate code above self-contained)
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate declaratively by calling the delegate directly.
            // In real apps you'd access the delegate via a Provider or
            // InheritedWidget rather than casting.
            final delegate = Router.of(context).routerDelegate
                as AppRouterDelegate;
            delegate.goProfile('user-42');
          },
          child: const Text('Go to Profile 42'),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile: $userId')),
      body: Center(child: Text('User ID: $userId')),
    );
  }
}

class UnknownPage extends StatelessWidget {
  const UnknownPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('404 — Page not found')),
    );
  }
}

// ============================================================
// WHY NAVIGATOR 2.0 IS COMPLEX AND WHEN TO USE go_router
// ============================================================
//
// Navigator 2.0's complexity comes from:
//
//   1. Boilerplate — even a simple 3-route app needs 2 custom classes
//      (RouterDelegate + RouteInformationParser) with several methods.
//
//   2. Manual diffing — you must ensure page keys are stable and that
//      onPopPage / onDidRemovePage correctly mirrors your state updates;
//      otherwise you get infinite build loops or missing transitions.
//
//   3. Nested routing requires ChildBackButtonDispatcher wiring.
//
//   4. Query parameters, redirects, and guards are all DIY.
//
// go_router (pub.dev/packages/go_router, by the Flutter team) is an
// officially recommended wrapper that gives you:
//   • Declarative route table with path templates ("/user/:id")
//   • Query parameters parsed automatically
//   • redirect callbacks for auth guards
//   • ShellRoute for persistent bottom nav bars
//   • context.go() / context.push() imperative helpers
//   • Named routes
//   • Deep-link and web URL sync out of the box
//
// Use raw Navigator 2.0 only if:
//   • You are building a routing package yourself.
//   • You need fine-grained control that no existing package exposes.
//   • You want zero dependencies.
//
// For everything else: use go_router. See go_router_example.dart.
