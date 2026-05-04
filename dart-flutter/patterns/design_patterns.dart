// design_patterns.dart
// Eight classic design patterns in idiomatic Dart.
// Each pattern is self-contained, runnable, and shows the Dart-specific idioms.

import 'dart:async';

// ============================================================================
// 1. SINGLETON — factory constructor + static field
// ============================================================================
//
// Dart's factory constructor can return an existing instance.
// This is idiomatic Dart: no getInstance() static method, just `new` / call syntax.
// Thread-safety: Dart isolates share no memory, so this is safe within one isolate.

class AppLogger {
  // Private static field holds the single instance.
  static final AppLogger _instance = AppLogger._internal();

  // Private named constructor — prevents external instantiation.
  AppLogger._internal();

  // Factory constructor: every `AppLogger()` call returns the same object.
  factory AppLogger() => _instance;

  final List<String> _log = [];

  void info(String msg) {
    _log.add('[INFO]  $msg');
    print('[INFO]  $msg');
  }

  void error(String msg) {
    _log.add('[ERROR] $msg');
    print('[ERROR] $msg');
  }

  List<String> get history => List.unmodifiable(_log);
}

void singletonDemo() {
  print('--- Singleton ---');
  final a = AppLogger();
  final b = AppLogger();
  print('Same instance: ${identical(a, b)}'); // true
  a.info('Application started');
  b.info('This goes to the same logger');
  print('History length: ${a.history.length}'); // 2
}

// ============================================================================
// 2. FACTORY METHOD — factory constructor returning subtypes
// ============================================================================
//
// Dart's factory constructor can return any subtype of the class.
// This enables the Factory Method pattern without a separate static method.

abstract class Notification {
  final String message;
  const Notification(this.message);

  void send();

  // The factory constructor inspects the channel and returns the right subtype.
  factory Notification.create(String channel, String message) =>
      switch (channel) {
        'email' => EmailNotification(message),
        'sms' => SmsNotification(message),
        'push' => PushNotification(message),
        _ => throw ArgumentError('Unknown channel: $channel'),
      };
}

class EmailNotification extends Notification {
  const EmailNotification(super.message);

  @override
  void send() => print('[EMAIL] $message');
}

class SmsNotification extends Notification {
  const SmsNotification(super.message);

  @override
  void send() => print('[SMS]   $message');
}

class PushNotification extends Notification {
  const PushNotification(super.message);

  @override
  void send() => print('[PUSH]  $message');
}

void factoryMethodDemo() {
  print('\n--- Factory Method ---');
  for (final channel in ['email', 'sms', 'push']) {
    Notification.create(channel, 'Hello, $channel user!').send();
  }
}

// ============================================================================
// 3. BUILDER — fluent builder with method chaining
// ============================================================================
//
// Return `this` from each setter to enable method chaining.
// A `build()` method validates and produces the final immutable object.
//
// In Dart, the cascade operator `..` is an alternative for calling multiple
// methods on the same object, but explicit method chaining is clearer for
// builders because it allows type-safe intermediate states.

class HttpRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final String? body;
  final Duration timeout;

  const HttpRequest({
    required this.method,
    required this.url,
    required this.headers,
    this.body,
    required this.timeout,
  });

  @override
  String toString() =>
      '$method ${url.path} headers=${headers.keys.toList()} body=${body != null}';
}

class HttpRequestBuilder {
  String _method = 'GET';
  Uri? _url;
  final Map<String, String> _headers = {};
  String? _body;
  Duration _timeout = const Duration(seconds: 30);

  HttpRequestBuilder method(String method) {
    _method = method.toUpperCase();
    return this; // enables chaining
  }

  HttpRequestBuilder url(String url) {
    _url = Uri.parse(url);
    return this;
  }

  HttpRequestBuilder header(String key, String value) {
    _headers[key] = value;
    return this;
  }

  HttpRequestBuilder jsonBody(String json) {
    _body = json;
    _headers['Content-Type'] = 'application/json';
    return this;
  }

  HttpRequestBuilder timeout(Duration d) {
    _timeout = d;
    return this;
  }

  // build() validates and constructs the final immutable object.
  HttpRequest build() {
    if (_url == null) throw StateError('URL is required');
    return HttpRequest(
      method: _method,
      url: _url!,
      headers: Map.unmodifiable(_headers),
      body: _body,
      timeout: _timeout,
    );
  }
}

void builderDemo() {
  print('\n--- Builder ---');
  final request = HttpRequestBuilder()
      .method('POST')
      .url('https://api.example.com/users')
      .header('Authorization', 'Bearer token123')
      .jsonBody('{"name": "Alice"}')
      .timeout(const Duration(seconds: 10))
      .build();
  print(request);
}

// ============================================================================
// 4. OBSERVER — using Streams instead of manual listener lists
// ============================================================================
//
// Dart's Stream is the idiomatic observer/event system.
// StreamController manages the subject; subscribers call listen().
// Broadcast streams allow multiple listeners.
//
// This is far more powerful than manual listener lists:
//   - Built-in backpressure, error handling, and lifecycle management
//   - Composable via map, where, transform, etc.
//   - async/await compatible

class StockTicker {
  final String symbol;
  // StreamController.broadcast() allows multiple listeners.
  final _controller = StreamController<double>.broadcast();

  StockTicker(this.symbol);

  // Expose only the Stream (not the Sink) to subscribers:
  Stream<double> get prices => _controller.stream;

  // Expose only the Sink (not the Stream) for the data source:
  void update(double price) => _controller.add(price);

  Future<void> close() => _controller.close();
}

void observerDemo() {
  print('\n--- Observer (Streams) ---');
  final ticker = StockTicker('DART');

  // Multiple independent observers:
  final sub1 = ticker.prices.listen(
    (price) => print('  [Investor A] DART = \$$price'),
  );

  final sub2 = ticker.prices
      .where((p) => p > 150) // only care about prices above 150
      .listen((price) => print('  [Alert Bot]  DART broke \$150 → \$$price'));

  // Fire some events:
  ticker.update(148.0);
  ticker.update(152.0);
  ticker.update(149.0);
  ticker.update(155.0);

  sub1.cancel();
  sub2.cancel();
  ticker.close();
}

// ============================================================================
// 5. STRATEGY — function parameters / typedefs
// ============================================================================
//
// In Dart, functions are first-class objects. Pass a function as a parameter
// instead of wrapping it in an interface — much less boilerplate.
//
// Typedefs give the strategy function a name for clarity.

typedef SortStrategy<T> = int Function(T a, T b);
typedef ValidationStrategy<T> = String? Function(T value);

class DataSorter<T> {
  final List<T> _data;
  SortStrategy<T> _strategy;

  DataSorter(List<T> data, this._strategy) : _data = List.of(data);

  // Swap strategy at runtime:
  void setStrategy(SortStrategy<T> strategy) => _strategy = strategy;

  List<T> sorted() => _data..sort(_strategy);
}

class FormField {
  final String value;
  final List<ValidationStrategy<String>> validators;

  const FormField(this.value, this.validators);

  // Runs all validators; returns the first error or null.
  String? validate() {
    for (final v in validators) {
      final error = v(value);
      if (error != null) return error;
    }
    return null;
  }
}

// Reusable strategy functions (point-free style):
String? requireNonEmpty(String v) =>
    v.isEmpty ? 'Field is required' : null;
String? requireEmail(String v) =>
    v.contains('@') ? null : 'Must be a valid email';
ValidationStrategy<String> minLength(int n) =>
    (v) => v.length >= n ? null : 'Must be at least $n characters';

void strategyDemo() {
  print('\n--- Strategy ---');
  final sorter = DataSorter<String>(
    ['banana', 'apple', 'cherry', 'date'],
    (a, b) => a.compareTo(b), // strategy: alphabetical
  );
  print('Alphabetical: ${sorter.sorted()}');

  sorter.setStrategy((a, b) => a.length.compareTo(b.length)); // by length
  print('By length:    ${sorter.sorted()}');

  final emailField = FormField('bad-email', [
    requireNonEmpty,
    requireEmail,
    minLength(5),
  ]);
  print('Validation: ${emailField.validate()}');

  final validField = FormField('user@example.com', [
    requireNonEmpty,
    requireEmail,
    minLength(5),
  ]);
  print('Validation: ${validField.validate()}');
}

// ============================================================================
// 6. REPOSITORY PATTERN — abstract class + concrete implementation
// ============================================================================
//
// The Repository pattern separates domain logic from data access.
// The abstract class defines the contract; concrete classes implement it.
// This makes swapping implementations (in-memory for tests, HTTP for prod)
// trivial.

abstract interface class UserRepository {
  Future<User?> findById(int id);
  Future<List<User>> findAll();
  Future<void> save(User user);
  Future<void> delete(int id);
}

class User {
  final int id;
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});

  @override
  String toString() => 'User($id, $name, $email)';
}

// In-memory implementation (for tests / prototyping):
class InMemoryUserRepository implements UserRepository {
  final Map<int, User> _store = {};

  @override
  Future<User?> findById(int id) async => _store[id];

  @override
  Future<List<User>> findAll() async => _store.values.toList();

  @override
  Future<void> save(User user) async => _store[user.id] = user;

  @override
  Future<void> delete(int id) async => _store.remove(id);
}

// Domain service only depends on the abstract interface — not the concrete impl.
class UserService {
  final UserRepository _repo;
  const UserService(this._repo);

  Future<String> greet(int userId) async {
    final user = await _repo.findById(userId);
    return user != null ? 'Hello, ${user.name}!' : 'User not found';
  }
}

Future<void> repositoryDemo() async {
  print('\n--- Repository ---');
  final repo = InMemoryUserRepository();
  final service = UserService(repo);

  await repo.save(User(id: 1, name: 'Alice', email: 'a@ex.com'));
  await repo.save(User(id: 2, name: 'Bob', email: 'b@ex.com'));

  print(await service.greet(1)); // Hello, Alice!
  print(await service.greet(99)); // User not found

  final all = await repo.findAll();
  print('All users: $all');
}

// ============================================================================
// 7. DECORATOR — wrapping via `implements`
// ============================================================================
//
// Implement the same interface, hold a reference to the wrapped object,
// delegate calls you don't want to modify, intercept the ones you do.
// In Dart, any class can implement any other class's implicit interface.

abstract interface class TextTransformer {
  String transform(String input);
}

class IdentityTransformer implements TextTransformer {
  @override
  String transform(String input) => input;
}

// Each decorator wraps any TextTransformer:
class TrimDecorator implements TextTransformer {
  final TextTransformer _inner;
  const TrimDecorator(this._inner);

  @override
  String transform(String input) => _inner.transform(input.trim());
}

class UpperCaseDecorator implements TextTransformer {
  final TextTransformer _inner;
  const UpperCaseDecorator(this._inner);

  @override
  String transform(String input) => _inner.transform(input).toUpperCase();
}

class PrefixDecorator implements TextTransformer {
  final TextTransformer _inner;
  final String prefix;
  const PrefixDecorator(this._inner, this.prefix);

  @override
  String transform(String input) => '$prefix${_inner.transform(input)}';
}

void decoratorDemo() {
  print('\n--- Decorator ---');
  // Compose decorators at runtime — order matters (outermost applied last).
  final transformer = PrefixDecorator(
    UpperCaseDecorator(
      TrimDecorator(IdentityTransformer()),
    ),
    '[MSG] ',
  );

  print(transformer.transform('  hello world  '));
  // Trim → "hello world" → UPPER → "HELLO WORLD" → prefix → "[MSG] HELLO WORLD"
}

// ============================================================================
// 8. COMMAND PATTERN — encapsulating actions as objects/functions
// ============================================================================
//
// Commands encapsulate a request as an object so it can be:
//   - Queued, logged, deferred
//   - Undone (undo/redo stacks)
//   - Composed into macros
//
// In Dart: use a typedef for the simplest case, or a sealed class for
// commands that carry metadata, support undo, or need serialization.

typedef Command = void Function();

// For undo/redo, we need a richer structure:
abstract interface class UndoableCommand {
  String get description;
  void execute();
  void undo();
}

class TextEditor {
  final StringBuffer _buffer = StringBuffer();
  final List<UndoableCommand> _history = [];

  String get text => _buffer.toString();

  void execute(UndoableCommand cmd) {
    cmd.execute();
    _history.add(cmd);
    print('  execute: ${cmd.description} → "$text"');
  }

  void undo() {
    if (_history.isEmpty) {
      print('  Nothing to undo');
      return;
    }
    final cmd = _history.removeLast();
    cmd.undo();
    print('  undo:    ${cmd.description} → "$text"');
  }
}

class InsertCommand implements UndoableCommand {
  final TextEditor _editor;
  final String _text;

  InsertCommand(this._editor, this._text);

  @override
  String get description => 'insert("$_text")';

  @override
  void execute() => _editor._buffer.write(_text);

  @override
  void undo() {
    final current = _editor._buffer.toString();
    _editor._buffer.clear();
    _editor._buffer.write(current.substring(0, current.length - _text.length));
  }
}

class DeleteLastCommand implements UndoableCommand {
  final TextEditor _editor;
  late String _deleted;

  DeleteLastCommand(this._editor);

  @override
  String get description => 'deleteLast';

  @override
  void execute() {
    final current = _editor._buffer.toString();
    if (current.isNotEmpty) {
      _deleted = current[current.length - 1];
      _editor._buffer.clear();
      _editor._buffer.write(current.substring(0, current.length - 1));
    } else {
      _deleted = '';
    }
  }

  @override
  void undo() => _editor._buffer.write(_deleted);
}

// Simple command queue (fire-and-forget, no undo):
class CommandQueue {
  final _queue = <Command>[];

  void enqueue(Command cmd) => _queue.add(cmd);

  void runAll() {
    while (_queue.isNotEmpty) {
      _queue.removeAt(0)();
    }
  }
}

void commandDemo() {
  print('\n--- Command (undo/redo) ---');
  final editor = TextEditor();
  editor.execute(InsertCommand(editor, 'Hello'));
  editor.execute(InsertCommand(editor, ' World'));
  editor.execute(DeleteLastCommand(editor));
  editor.undo();
  editor.undo();
  editor.undo(); // nothing to undo

  print('\n--- Command (queue) ---');
  final queue = CommandQueue();
  queue.enqueue(() => print('  queued task 1'));
  queue.enqueue(() => print('  queued task 2'));
  queue.enqueue(() => print('  queued task 3'));
  queue.runAll();
}

// ============================================================================
// main
// ============================================================================

Future<void> main() async {
  singletonDemo();
  factoryMethodDemo();
  builderDemo();
  observerDemo();
  strategyDemo();
  await repositoryDemo();
  decoratorDemo();
  commandDemo();
}
