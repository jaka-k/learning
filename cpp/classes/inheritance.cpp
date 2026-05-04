// ============================================================
// Inheritance, Virtual Dispatch, and Polymorphism
// ============================================================

#include <iostream>
#include <memory>
#include <vector>
#include <typeinfo>

// ---- Virtual functions and vtable -------------------------------------------
// `virtual` puts the function in the vtable — a per-class array of function
// pointers. Each object has a hidden vptr pointing to its class's vtable.
// Virtual dispatch: one extra pointer dereference at call time.

struct Shape {
    // Pure virtual: subclasses MUST override; Shape is abstract
    virtual double area() const = 0;
    virtual double perimeter() const = 0;

    // Non-pure virtual with default implementation
    virtual void describe() const {
        std::cout << "Shape: area=" << area() << " perimeter=" << perimeter() << "\n";
    }

    // Virtual destructor: REQUIRED when deleting through a base pointer.
    // Without it, `delete base_ptr` calls only ~Shape, leaking derived resources.
    virtual ~Shape() = default;
};

struct Circle : Shape {
    double r;
    explicit Circle(double r) : r(r) {}
    double area() const override { return 3.14159 * r * r; }
    double perimeter() const override { return 2 * 3.14159 * r; }
};

struct Rectangle : Shape {
    double w, h;
    Rectangle(double w, double h) : w(w), h(h) {}
    double area() const override { return w * h; }
    double perimeter() const override { return 2 * (w + h); }
};

// `final` prevents further overriding or inheritance
struct Square final : Rectangle {
    explicit Square(double s) : Rectangle(s, s) {}
    void describe() const override {
        std::cout << "Square side=" << w << " area=" << area() << "\n";
    }
};
// class SpecialSquare : Square {};  // compile error: Square is final

void virtualDispatch() {
    std::vector<std::unique_ptr<Shape>> shapes;
    shapes.push_back(std::make_unique<Circle>(5));
    shapes.push_back(std::make_unique<Rectangle>(3, 4));
    shapes.push_back(std::make_unique<Square>(2));

    for (auto& s : shapes) s->describe();  // vtable lookup at runtime
}

// ---- Covariant return types -------------------------------------------------
// Overriding function can return a pointer/reference to a derived type.

struct Base { virtual Base* clone() const { return new Base(*this); } virtual ~Base() = default; };
struct Derived : Base { Derived* clone() const override { return new Derived(*this); } };  // covariant

// ---- Access control in inheritance ------------------------------------------
// public    inheritance: public/protected stay the same
// protected inheritance: public becomes protected
// private   inheritance: public/protected become private (implementation detail)

struct Engine { void start() { std::cout << "engine on\n"; } };

// private inheritance = "is-implemented-in-terms-of", not "is-a"
struct Car : private Engine {
    void drive() { start(); }   // can use Engine's members internally
};
// Car c; c.start();  // compile error: start() is private in Car

// ---- dynamic_cast and RTTI --------------------------------------------------
// dynamic_cast performs a safe downcast checked at runtime.
// Returns nullptr (for pointers) or throws std::bad_cast (for references) on failure.
// Requires at least one virtual function in the hierarchy (polymorphic type).

void dynamicCastExample() {
    std::unique_ptr<Shape> s = std::make_unique<Circle>(3);

    // Downcast: Shape* → Circle*
    if (auto* c = dynamic_cast<Circle*>(s.get())) {
        std::cout << "Circle radius=" << c->r << "\n";
    }
    if (auto* r = dynamic_cast<Rectangle*>(s.get())) {
        std::cout << "Rectangle\n";  // not printed
    } else {
        std::cout << "not a Rectangle\n";
    }

    // typeid: returns std::type_info at runtime
    std::cout << "typeid=" << typeid(*s).name() << "\n";
}

// ---- Non-virtual interface (NVI) idiom --------------------------------------
// Public non-virtual calls a private virtual — base controls pre/post actions.

struct Logger {
    void log(const std::string& msg) {
        preLog();
        doLog(msg);   // virtual dispatch to the override
        postLog();
    }
    virtual ~Logger() = default;

private:
    virtual void doLog(const std::string& msg) = 0;
    virtual void preLog()  {}
    virtual void postLog() {}
};

struct ConsoleLogger : Logger {
private:
    void doLog(const std::string& msg) override {
        std::cout << "[console] " << msg << "\n";
    }
};

// ---- Multiple inheritance and diamond problem --------------------------------
// Virtual base classes ensure only one subobject of the base exists.

struct Animal { virtual ~Animal() = default; virtual void speak() = 0; };
struct FlyingThing { virtual void fly() { std::cout << "flying\n"; } virtual ~FlyingThing() = default; };

struct Bird : Animal, FlyingThing {
    void speak() override { std::cout << "tweet\n"; }
};

// Diamond: if both Dog and Cat inherit from Animal without virtual,
// a DogCat would have two Animal subobjects. `virtual` collapses to one.
struct Canine  : virtual Animal { void speak() override { std::cout << "woof\n"; } };
struct Feline  : virtual Animal { void speak() override { std::cout << "meow\n"; } };
// struct ChimericPet : Canine, Feline {};  // ambiguous speak() — must override

int main() {
    std::cout << "=== virtual dispatch ===\n"; virtualDispatch();
    std::cout << "=== dynamic_cast ===\n";     dynamicCastExample();
    std::cout << "=== NVI ===\n";
    ConsoleLogger logger;
    logger.log("hello");
    std::cout << "=== multiple inheritance ===\n";
    Bird b;
    b.speak();
    b.fly();
    std::cout << "=== private inheritance ===\n";
    Car car;
    car.drive();
}
