/// A shared phantom tag for tests that only need `Property<Tag, Base>` to
/// compile — i.e., the Tag identity does not matter to what's being tested.
///
/// Named `Phantom` rather than `Tag` to avoid collision with Swift Testing's
/// `Testing.Tag` (used by the `.tags(...)` suite trait).
///
/// Tests that need Tag-differentiated extensions (e.g., on `Property where
/// Tag == Foo, Base == Bar`) still declare their own tag types for that
/// purpose.
public enum Phantom {}
