enum UserRole {
  broker,
  investor,
  owner,
  builder;

  String get label => switch (this) {
        broker   => 'Broker',
        investor => 'Investor',
        owner    => 'Owner',
        builder  => 'Builder',
      };

  String get emoji => switch (this) {
        broker   => '🏢',
        investor => '💰',
        owner    => '🏠',
        builder  => '🏗️',
      };

  String get description => switch (this) {
        broker   => 'Licensed real estate broker',
        investor => 'Property investor / buyer',
        owner    => 'Direct property owner',
        builder  => 'Developer / construction firm',
      };

  static UserRole? fromString(String? v) =>
      UserRole.values.where((e) => e.name == v).firstOrNull;
}
