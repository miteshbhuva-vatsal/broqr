/// Marker interface for all domain entities.
/// Implemented as a mixin so entities can mix it in without a class hierarchy.
mixin Entity {}

/// Marker for all data-layer models (JSON-serialisable).
mixin DataModel {}
