enum PropertyType {
  bhk1,
  bhk2,
  bhk3,
  bhk4,
  studio,
  villa,
  plot,
  land,
  rowHouse,
  penthouse,
  shopOffice,
  warehouse;

  String get label => switch (this) {
        bhk1 => '1 BHK',
        bhk2 => '2 BHK',
        bhk3 => '3 BHK',
        bhk4 => '4 BHK+',
        studio => 'Studio',
        villa => 'Villa',
        plot => 'Plot',
        land => 'Land',
        rowHouse => 'Row House',
        penthouse => 'Penthouse',
        shopOffice => 'Shop/Office',
        warehouse => 'Warehouse',
      };

  String get emoji => switch (this) {
        bhk1 => '🏠',
        bhk2 => '🏠',
        bhk3 => '🏡',
        bhk4 => '🏘️',
        studio => '🛋️',
        villa => '🏰',
        plot => '📐',
        land => '🌿',
        rowHouse => '🏘️',
        penthouse => '🌆',
        shopOffice => '🏪',
        warehouse => '🏭',
      };

  String get firestoreKey => name;

  static PropertyType? fromString(String? value) {
    if (value == null) return null;
    return PropertyType.values.where((e) => e.name == value).firstOrNull;
  }
}
