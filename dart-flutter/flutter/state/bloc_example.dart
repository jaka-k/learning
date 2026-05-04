// =============================================================================
// BLOC PATTERN — STATE MANAGEMENT
// =============================================================================
// NOTE: This file is NOT runnable standalone. It requires a Flutter project
// with the BLoC package. Add to pubspec.yaml:
//   dependencies:
//     flutter_bloc: ^8.1.5
//     bloc: ^8.1.4
//   dev_dependencies:
//     bloc_test: ^9.1.7
//
// BLoC = Business Logic Component. It enforces a strict unidirectional data flow:
//   UI dispatches Events → BLoC processes events → BLoC emits States → UI rebuilds
//
// This strict separation makes the business logic completely testable without Flutter.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// =============================================================================
// PART 1: Cubit — The Simpler BLoC
// =============================================================================

// Cubit is a simplified version of BLoC. Instead of Events, you call methods
// directly on the Cubit. Methods call `emit(newState)` to trigger rebuilds.
//
// When to use Cubit vs BLoC:
//   Use Cubit when:
//     - Simple state: counters, toggles, loading flags
//     - You don't need to trace events through logs (no audit trail needed)
//     - The team prefers less boilerplate
//   Use BLoC when:
//     - Complex event processing (same event type handled differently in different states)
//     - You need event history/logging for debugging or analytics
//     - Multiple events can be dispatched in rapid succession (BLoC supports debouncing)
//     - Team prefers explicit event-driven architecture

class CounterCubit extends Cubit<int> {
  // super() takes the initial state
  CounterCubit() : super(0);

  // Methods emit new states directly — no Event class needed
  void increment() => emit(state + 1);
  // `state` is the current state value (provided by Cubit<T>)
  // `emit(newState)` triggers a rebuild in all BlocBuilder listeners

  void decrement() {
    if (state > 0) emit(state - 1);
    // Guard: don't go below 0
  }

  void reset() => emit(0);

  // Cubit can also do async work:
  Future<void> loadFromStorage() async {
    emit(0); // Reset/loading state
    await Future.delayed(const Duration(milliseconds: 300));
    emit(42); // Loaded value
  }
}

// =============================================================================
// PART 2: BLoC States — Sealed Classes for Exhaustive Handling
// =============================================================================

// States should be modeled as a SEALED CLASS HIERARCHY when there are
// multiple distinct states. Sealed classes (Dart 3+) enable exhaustive
// pattern matching — the compiler ensures you've handled every case.
//
// For simple cases (like the Counter), a single type (int) is fine.
// For complex flows like login, define distinct state classes.

// Base state — sealed means all subclasses must be in the same library file
sealed class LoginState {
  const LoginState();
}

// Initial state — nothing has happened yet
final class LoginInitial extends LoginState {
  const LoginInitial();
}

// Loading state — an async operation is in progress
// May carry data from before the loading started (useful for "refresh while showing old data")
final class LoginLoading extends LoginState {
  const LoginLoading();
}

// Success state — carries the result data
final class LoginSuccess extends LoginState {
  final String userName;
  final String token;

  const LoginSuccess({required this.userName, required this.token});

  // Equality and hashCode: important for BlocBuilder's buildWhen comparisons
  @override
  bool operator ==(Object other) =>
    other is LoginSuccess &&
    other.userName == userName &&
    other.token == token;

  @override
  int get hashCode => Object.hash(userName, token);
}

// Error state — carries error information
final class LoginError extends LoginState {
  final String message;
  final LoginErrorType type;

  const LoginError({required this.message, required this.type});
}

enum LoginErrorType { invalidCredentials, networkError, serverError, unknown }

// =============================================================================
// PART 3: BLoC Events — Explicit Input Commands
// =============================================================================

// Events are the inputs to a BLoC. They represent things that happen:
//   - User actions: button taps, form submissions
//   - System events: timer fired, network changed
//   - Navigation: screen appeared, screen disappeared
//
// Like states, events are typically a sealed class hierarchy.

sealed class LoginEvent {
  const LoginEvent();
}

// Event triggered when user submits the login form
final class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});
}

// Event triggered when user taps "Forgot password"
final class ForgotPasswordRequested extends LoginEvent {
  final String email;

  const ForgotPasswordRequested({required this.email});
}

// Event triggered to reset the form (e.g., user navigates back and returns)
final class LoginReset extends LoginEvent {
  const LoginReset();
}

// =============================================================================
// PART 4: The BLoC Class — Connecting Events to States
// =============================================================================

// A simulated authentication service (would be injected in real code)
class AuthService {
  Future<({String userName, String token})> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email == 'test@test.com' && password == 'password') {
      return (userName: 'Test User', token: 'abc123');
    }
    if (email.isEmpty || password.isEmpty) {
      throw AuthException(LoginErrorType.invalidCredentials, 'Fields are required');
    }
    throw AuthException(LoginErrorType.invalidCredentials, 'Invalid credentials');
  }

  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

class AuthException implements Exception {
  final LoginErrorType type;
  final String message;
  AuthException(this.type, this.message);
}

// THE BLOC CLASS
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthService _authService;

  LoginBloc({required AuthService authService})
    : _authService = authService,
      super(const LoginInitial()) { // Initial state passed to super()

    // Register event handlers in the constructor using `on<EventType>()`.
    // Each event type gets exactly ONE handler.
    // Handlers are called in the order events arrive (by default).
    on<LoginSubmitted>(_onLoginSubmitted);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<LoginReset>(_onLoginReset);

    // Advanced: transformer parameter controls concurrency.
    // Default: sequential (events are queued and processed one at a time).
    // `transformer: concurrent()` — process all events concurrently
    // `transformer: droppable()` — drop new events while one is processing
    // `transformer: restartable()` — cancel previous when new arrives (great for search)
    // These come from the `bloc_concurrency` package.
  }

  // Event handler: receives the event and an Emitter<State>.
  // `emit` is the emitter — call it to produce new states.
  // Handler is async: you can await inside it.
  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    // Emit loading state immediately to show spinner
    emit(const LoginLoading());

    try {
      final result = await _authService.login(
        email: event.email,
        password: event.password,
      );
      // Emit success state with the result data
      emit(LoginSuccess(userName: result.userName, token: result.token));
    } on AuthException catch (e) {
      // Emit error state with specific error type and message
      emit(LoginError(message: e.message, type: e.type));
    } catch (e) {
      // Catch-all for unexpected errors
      emit(LoginError(
        message: 'An unexpected error occurred',
        type: LoginErrorType.unknown,
      ));
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<LoginState> emit,
  ) async {
    // For forgot password, we don't change the main login state
    // (side effect handled via BlocListener on a separate state field,
    // or via a separate Cubit/BLoC for the forgot-password flow)
    await _authService.sendPasswordReset(event.email);
    // In this simplified example we do nothing with the result here.
    // In a real app, you'd have a dedicated state for this.
  }

  void _onLoginReset(
    LoginReset event,
    Emitter<LoginState> emit,
  ) {
    // Synchronous handler — no async needed
    emit(const LoginInitial());
  }

  // BLoC also has lifecycle hooks:
  @override
  void onChange(Change<LoginState> change) {
    super.onChange(change);
    // Called whenever state changes. change.currentState, change.nextState
    debugPrint('LoginBloc state change: ${change.currentState.runtimeType} → ${change.nextState.runtimeType}');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    // Called when an unhandled exception occurs in an event handler
    debugPrint('LoginBloc error: $error');
  }
}

// =============================================================================
// PART 5: BlocProvider — Placing the BLoC in the Widget Tree
// =============================================================================

// BlocProvider creates and provides a BLoC to its subtree.
// It calls `close()` on the BLoC when it's removed from the tree.
// (BLoC's `close()` is equivalent to State's `dispose()` — clean up resources.)

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // `create` receives the context and returns the BLoC instance.
      // Dependencies (like AuthService) are typically obtained from another
      // provider or passed in. RepositoryProvider is a common pattern for services.
      create: (context) => LoginBloc(authService: AuthService()),
      // `lazy: true` is the default — BLoC is created when first accessed,
      // not when BlocProvider is built.
      child: const LoginView(),
    );
  }
}

// If you already HAVE a BLoC and want to provide it (not create it):
// BlocProvider.value(
//   value: existingBloc,
//   child: SomeWidget(),
// )
// Use this for passing a BLoC to a new route (navigation).

// =============================================================================
// PART 6: BlocBuilder — Rebuilding UI Based on State
// =============================================================================

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ---------------------------------------------------------------------------
            // BlocListener — for SIDE EFFECTS, not UI
            // ---------------------------------------------------------------------------
            // BlocListener calls its `listener` callback whenever state changes.
            // It does NOT build any UI — its only purpose is side effects:
            //   - Navigation (go to home screen on success)
            //   - Showing SnackBars
            //   - Showing Dialogs
            //   - Analytics events
            //
            // Do NOT use BlocBuilder for these — BlocBuilder returns a Widget
            // and is for building UI, not triggering actions.
            BlocListener<LoginBloc, LoginState>(
              // `listenWhen` is optional — filter which state changes trigger the listener.
              // Here: only listen when transitioning FROM non-error TO error,
              // or to success. Without this, listener fires on every state change.
              listenWhen: (previous, current) =>
                current is LoginSuccess || current is LoginError,
              listener: (context, state) {
                if (state is LoginSuccess) {
                  // Navigate to home screen — side effect, not UI
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Welcome, ${state.userName}!')),
                  );
                  // Navigator.of(context).pushReplacementNamed('/home');
                } else if (state is LoginError) {
                  // Show error snackbar — side effect, not UI
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const SizedBox.shrink(), // Listener has no UI — empty child
            ),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------------------------------------------------------------------------
            // BlocBuilder — rebuilding UI based on state
            // ---------------------------------------------------------------------------
            // BlocBuilder<BlocType, StateType> rebuilds its `builder` whenever
            // the BLoC emits a new state.
            //
            // `buildWhen` is optional. Return false to SKIP rebuilding.
            // Useful when some state changes shouldn't affect this particular widget.
            BlocBuilder<LoginBloc, LoginState>(
              buildWhen: (previous, current) {
                // Only rebuild the button when loading state changes.
                // If we go from Error → Error with different message, the button
                // doesn't need to change — skip the rebuild.
                if (previous is LoginLoading && current is LoginLoading) return false;
                return true;
              },
              builder: (context, state) {
                // State is the CURRENT LoginState. Use pattern matching (Dart 3+).
                final isLoading = state is LoginLoading;

                return Column(
                  children: [
                    // Show error message inline (alternative to SnackBar)
                    if (state is LoginError)
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.red.shade100,
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // Disable button while loading
                        onPressed: isLoading ? null : () => _submitLogin(context),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Login'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitLogin(BuildContext context) {
    // Dispatch an event to the BLoC.
    // `context.read<LoginBloc>()` — reads the BLoC without registering a rebuild.
    // In callbacks, always use `read`, never `watch`.
    // `.add(event)` — adds the event to the BLoC's event queue.
    context.read<LoginBloc>().add(
      LoginSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }
}

// =============================================================================
// PART 7: BlocConsumer — BlocBuilder + BlocListener Combined
// =============================================================================

// BlocConsumer is syntactic sugar for nesting a BlocListener inside a BlocBuilder.
// Use it when the same state change requires BOTH a UI update AND a side effect.
//
// In practice, it's often cleaner to separate concerns (separate BlocBuilder
// and BlocListener). But for simple cases, BlocConsumer reduces nesting.

class LoginButtonWithConsumer extends StatelessWidget {
  const LoginButtonWithConsumer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      // listenWhen: optional filter for when to call listener
      listenWhen: (previous, current) => current is LoginSuccess,
      // listener: side effects
      listener: (context, state) {
        if (state is LoginSuccess) {
          // Navigate away on success
          debugPrint('Navigating to home...');
        }
      },
      // buildWhen: optional filter for when to rebuild
      buildWhen: (previous, current) =>
        current is LoginLoading || current is LoginInitial || current is LoginError,
      // builder: the UI
      builder: (context, state) {
        return ElevatedButton(
          onPressed: state is LoginLoading ? null : () {},
          child: state is LoginLoading
              ? const CircularProgressIndicator()
              : const Text('Login'),
        );
      },
    );
  }
}

// =============================================================================
// PART 8: MultiBlocProvider and RepositoryProvider
// =============================================================================

// For multiple BLoCs at the root of the app:
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(); // Or use GetIt/DI container

    return MultiRepositoryProvider(
      // RepositoryProvider provides non-BLoC dependencies (services, repositories).
      // Equivalent to Provider from the Provider package.
      // These are accessible via context.read<AuthService>() in BLoC create callbacks.
      providers: [
        RepositoryProvider<AuthService>(create: (_) => authService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LoginBloc>(
            create: (context) => LoginBloc(
              // Read the repository from context (provided above)
              authService: context.read<AuthService>(),
            ),
          ),
          BlocProvider<CounterCubit>(
            create: (_) => CounterCubit(),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
  }
}

// =============================================================================
// PART 9: Testing BLoC (without Flutter)
// =============================================================================
// BLoC's greatest strength: business logic is fully testable without widgets.
//
// Using the `bloc_test` package:
//
// void main() {
//   group('LoginBloc', () {
//     late AuthService authService;
//     late LoginBloc bloc;
//
//     setUp(() {
//       authService = MockAuthService(); // e.g., mocktail or mockito mock
//       bloc = LoginBloc(authService: authService);
//     });
//
//     tearDown(() => bloc.close()); // Always close the BLoC after tests
//
//     test('initial state is LoginInitial', () {
//       expect(bloc.state, isA<LoginInitial>());
//     });
//
//     blocTest<LoginBloc, LoginState>(
//       'emits [LoginLoading, LoginSuccess] on valid credentials',
//       build: () {
//         when(() => authService.login(email: any(named: 'email'), password: any(named: 'password')))
//           .thenAnswer((_) async => (userName: 'Test User', token: 'abc123'));
//         return bloc;
//       },
//       act: (bloc) => bloc.add(LoginSubmitted(email: 'test@test.com', password: 'password')),
//       expect: () => [
//         isA<LoginLoading>(),                          // First emission
//         isA<LoginSuccess>().having((s) => s.userName, 'userName', 'Test User'),
//       ],
//     );
//
//     blocTest<LoginBloc, LoginState>(
//       'emits [LoginLoading, LoginError] on bad credentials',
//       build: () {
//         when(() => authService.login(...))
//           .thenThrow(AuthException(LoginErrorType.invalidCredentials, 'Invalid'));
//         return bloc;
//       },
//       act: (bloc) => bloc.add(LoginSubmitted(email: 'bad@bad.com', password: 'wrong')),
//       expect: () => [
//         isA<LoginLoading>(),
//         isA<LoginError>().having((s) => s.type, 'type', LoginErrorType.invalidCredentials),
//       ],
//     );
//   });
// }

// =============================================================================
// SUMMARY: BLoC Architecture Decisions
// =============================================================================
//
// CUBIT vs BLOC:
//   Cubit  → Simple state, method calls, less boilerplate
//   BLoC   → Complex event processing, audit trail, advanced transformers
//
// STATE DESIGN:
//   Use sealed classes for compile-time exhaustive handling
//   Implement == and hashCode on states (or use Equatable/freezed)
//   Keep states immutable
//
// EVENT DESIGN:
//   One event per user/system action
//   Events carry only the data needed for that action
//   Events are immutable
//
// WIDGET INTERACTIONS:
//   BlocBuilder  → UI rebuilds. Return different widgets per state.
//   BlocListener → Side effects only. Navigation, SnackBars, dialogs.
//   BlocConsumer → Both, combined.
//   context.read<MyBloc>().add(event) → Dispatch events from callbacks.
//
// GOLDEN RULE: If it changes the UI → BlocBuilder.
//              If it has a side effect (navigation, toast) → BlocListener.
