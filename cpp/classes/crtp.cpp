// ============================================================
// CRTP — Curiously Recurring Template Pattern
// ============================================================
// CRTP achieves static polymorphism: the base class calls derived methods
// without a vtable. No virtual dispatch overhead; all resolved at compile time.
// Pattern: `class Derived : Base<Derived> { ... };`

#include <iostream>
#include <string>
#include <chrono>
#include <cmath>

// ---- Static polymorphism via CRTP -------------------------------------------
// Base<Derived> can call Derived::impl() without virtual dispatch.
// Use case: policy/mixin where you want zero-cost abstraction.

template<typename Derived>
struct Shape {
    // Calls the derived implementation via static downcast — no vtable
    double area() const {
        return static_cast<const Derived*>(this)->areaImpl();
    }
    double perimeter() const {
        return static_cast<const Derived*>(this)->perimeterImpl();
    }
    void describe() const {
        std::cout << "area=" << area() << " perimeter=" << perimeter() << "\n";
    }
};

struct Circle : Shape<Circle> {
    double r;
    explicit Circle(double r) : r(r) {}
    double areaImpl() const { return 3.14159 * r * r; }
    double perimeterImpl() const { return 2 * 3.14159 * r; }
};

struct Square : Shape<Square> {
    double s;
    explicit Square(double s) : s(s) {}
    double areaImpl() const { return s * s; }
    double perimeterImpl() const { return 4 * s; }
};

// Static dispatch: compiler generates a separate describe() for each Shape type
void staticDispatch() {
    Circle c(5); c.describe();
    Square s(3); s.describe();
}

// ---- CRTP Mixin — adding behavior without virtual ----------------------------
// A mixin adds a set of methods to a class by inheriting from a CRTP base.
// Unlike multiple inheritance with virtuals, cost is zero.

template<typename Derived>
struct Printable {
    void print() const {
        static_cast<const Derived*>(this)->printImpl();
    }
    void println() const { print(); std::cout << "\n"; }
};

template<typename Derived>
struct Comparable {
    bool operator<=(const Derived& o) const {
        auto& self = static_cast<const Derived&>(*this);
        return !(o < self);
    }
    bool operator>(const Derived& o) const {
        auto& self = static_cast<const Derived&>(*this);
        return o < self;
    }
    bool operator>=(const Derived& o) const {
        auto& self = static_cast<const Derived&>(*this);
        return !(self < o);
    }
    // Derived only needs to define operator< and operator==
};

struct Point : Printable<Point>, Comparable<Point> {
    double x, y;
    Point(double x, double y) : x(x), y(y) {}

    void printImpl() const { std::cout << "(" << x << ", " << y << ")"; }

    double magnitude() const { return std::sqrt(x*x + y*y); }
    bool operator<(const Point& o) const { return magnitude() < o.magnitude(); }
    bool operator==(const Point& o) const { return x == o.x && y == o.y; }
};

void mixinExample() {
    Point p1(3, 4), p2(1, 1);
    p1.println();
    std::cout << "p1 > p2: " << (p1 > p2) << "\n";
    std::cout << "p1 <= p2: " << (p1 <= p2) << "\n";
}

// ---- CRTP for code instrumentation (without virtual) ------------------------

template<typename Derived>
struct Timed {
    template<typename... Args>
    auto timedCall(const char* name, Args&&... args) {
        auto start = std::chrono::high_resolution_clock::now();
        if constexpr (std::is_void_v<decltype(static_cast<Derived*>(this)->call(std::forward<Args>(args)...))>) {
            static_cast<Derived*>(this)->call(std::forward<Args>(args)...);
            auto end = std::chrono::high_resolution_clock::now();
            std::cout << name << " took "
                      << std::chrono::duration_cast<std::chrono::microseconds>(end - start).count()
                      << "us\n";
        } else {
            auto result = static_cast<Derived*>(this)->call(std::forward<Args>(args)...);
            auto end = std::chrono::high_resolution_clock::now();
            std::cout << name << " took "
                      << std::chrono::duration_cast<std::chrono::microseconds>(end - start).count()
                      << "us\n";
            return result;
        }
    }
};

// ---- CRTP vs virtual comparison ---------------------------------------------
//
// Virtual:
//   + Runtime polymorphism: store Shapes in a vector<unique_ptr<Shape>>
//   - vtable lookup: ~1ns extra per call + prevents inlining
//   - One pointer per object (vptr overhead)
//
// CRTP:
//   + Zero overhead: inlined at compile time
//   + No heap allocation for the object
//   - No runtime polymorphism (can't mix Circle and Square in one container)
//   - Code bloat: each instantiation generates code
//
// When to prefer CRTP:
//   - Tight inner loops where virtual call overhead matters
//   - Mixins that add reusable behavior (Printable, Comparable, etc.)
//   - Policy-based design (selecting algorithms at compile time)

// ---- CRTP for counters / tracking -------------------------------------------

template<typename Derived>
struct InstanceCounter {
    static inline int count = 0;
    InstanceCounter()  { ++count; }
    ~InstanceCounter() { --count; }
};

struct Foo : InstanceCounter<Foo> {};
struct Bar : InstanceCounter<Bar> {};

void counterExample() {
    Foo f1, f2;
    Bar b1;
    std::cout << "Foo count=" << InstanceCounter<Foo>::count << "\n"; // 2
    std::cout << "Bar count=" << InstanceCounter<Bar>::count << "\n"; // 1
    {
        Foo f3;
        std::cout << "Foo count=" << InstanceCounter<Foo>::count << "\n"; // 3
    }
    std::cout << "Foo count=" << InstanceCounter<Foo>::count << "\n"; // 2
}

int main() {
    std::cout << "=== static polymorphism ===\n"; staticDispatch();
    std::cout << "=== mixin ===\n";               mixinExample();
    std::cout << "=== instance counter ===\n";    counterExample();
}
