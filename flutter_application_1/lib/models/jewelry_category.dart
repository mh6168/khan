enum JewelryCategory {
  rings,
  necklaces,
  bracelets,
  earrings,
  pendants,
  watches,
}

extension JewelryCategoryLabel on JewelryCategory {
  String get label => switch (this) {
    JewelryCategory.rings => 'Rings',
    JewelryCategory.necklaces => 'Necklaces',
    JewelryCategory.bracelets => 'Bracelets',
    JewelryCategory.earrings => 'Earrings',
    JewelryCategory.pendants => 'Pendants',
    JewelryCategory.watches => 'Watches',
  };
}
