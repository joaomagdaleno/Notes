# Bolt's Journal: Critical Flutter Performance Learnings

## 2024-05-23 - The No-Op `const` Optimization

**Learning:** Dart's `const` constructors create canonicalized, compile-time constants. This means `const Uuid()` already provides a single, reused instance of the `Uuid` object throughout the application. Creating a `final` instance variable to hold this `const` object (e.g., `final _uuid = const Uuid();`) is a redundant micro-optimization that provides zero performance benefit over calling `const Uuid().v4()` directly. The object allocation is identical in both scenarios.

**Action:** Before attempting to "optimize" object creation, always verify if the object's constructor is `const`. If it is, the Dart compiler is already performing the optimization. Focus instead on objects created with non-`const` constructors inside `build` methods or frequently called functions.