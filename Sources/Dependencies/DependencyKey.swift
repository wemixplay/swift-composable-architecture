import XCTestDynamicOverlay

/// A key for accessing dependencies.
///
/// Similar to SwiftUI's `EnvironmentKey` protocol, which is used to extend `EnvironmentValues` with
/// custom dependencies, `DependencyKey` can be used to extend ``DependencyValues``.
///
/// `DependencyKey` has one main requirement, ``liveValue``, which must return a default value for
/// use in your live application.
///
/// `DependencyKey` inherits two overridable requirements from ``TestDependencyKey``:
/// ``TestDependencyKey/testValue``, which should return a default value for the purpose of
/// testing, and ``TestDependencyKey/previewValue-416hu``, which can return a default value suitable
/// for Xcode previews. When left unimplemented, these endpoints will return the ``liveValue``,
/// instead.
///
/// If you plan on separating your interface from your live implementation, conform to
/// ``TestDependencyKey`` in your interface module, and extend this conformance to `DependencyKey`
/// in your implementation module.
public protocol DependencyKey: TestDependencyKey {
  associatedtype Value = Self

  /// The live value for the dependency key.
  static var liveValue: Value { get }

  // NB: https://github.com/apple/swift/issues/61077
  // TODO: copy-paste docs?
  static var previewValue: Value { get }
  static var testValue: Value { get }
}

/// A key for accessing test dependencies.
///
/// This protocol lives one layer below ``DependencyKey`` and allows you to separate a dependency's
/// interface from its live implementation.
///
/// `DependencyKey` has one main requirement, ``testValue``, which must return a default value for
/// the purposes of testing, and one optional requirement, ``previewValue-416hu``, which can return
/// a default value suitable for Xcode previews, or the ``testValue``, if left unimplemented.
///
/// See ``DependencyKey`` to define a static, default value for the live application.
public protocol TestDependencyKey {
  /// The associated type representing the type of the dependency key's value.
  associatedtype Value = Self

  // NB: This associated type should be constrained to `Sendable` when this bug is fixed:
  //     https://github.com/apple/swift/issues/60649

  /// The preview value for the dependency key.
  ///
  /// This value is automatically installed into stores running in Xcode previews, as well as
  /// reducer hierarchies that set their dependency environment to `preview`:
  ///
  /// ```swift
  /// MyFeature()
  ///   .dependency(\.environment, .preview)
  /// ```
  static var previewValue: Value { get }

  /// The test value for the dependency key.
  ///
  /// This value is automatically installed into test stores and reducer hierarchies that set their
  /// dependency environment to `test`:
  ///
  /// ```swift
  /// MyFeature()
  ///   .dependency(\.environment, .test)
  /// ```
  static var testValue: Value { get }
}

extension DependencyKey {
  /// A default implementation that provides the ``liveValue`` to Xcode previews.
  public static var previewValue: Value { Self.liveValue }

  /// A default implementation that provides the ``liveValue`` to tests.
  public static var testValue: Value {
    let dependencyName = DependencyValues.currentDependencyName
      .map { "@Dependency(\\.\($0))" }
      ?? "A dependency"
    let dependencyDescription: String
    if Self.self == Value.self {
      dependencyDescription = """
          Dependency:
            \(typeName(Value.self))
        """
    } else {
      dependencyDescription = """
          Key:
            \(typeName(Self.self))
          Value:
            \(typeName(Value.self))
        """
    }

    XCTFail("""
      \(dependencyName) has no test implementation, but was accessed from a test context:

      \(dependencyDescription)

      Dependencies registered with the library are not allowed to use their live implementations \
      when run in a 'TestStore'.

      To fix, make sure that \(typeName(Self.self)) provides an implementation of 'testValue' \
      in its conformance to the 'DependencyKey' protocol.
      """)
    return Self.previewValue
  }
}

extension TestDependencyKey {
  /// A default implementation that provides the ``testValue`` to Xcode previews.
  public static var previewValue: Value { Self.testValue }
}