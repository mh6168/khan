enum JewelryCategory {
  rings,
  necklaces,
  bracelets,
  earrings,
  pendants,
  watches,
}

extension JewelryCategoryPresentation on JewelryCategory {
  String get imageAsset => switch (this) {
    JewelryCategory.rings => 'assets/images/category_rings.jpg',
    JewelryCategory.necklaces => 'assets/images/category_necklaces.jpg',
    JewelryCategory.bracelets => 'assets/images/category_bracelets.jpg',
    JewelryCategory.earrings => 'assets/images/category_earrings.jpg',
    JewelryCategory.pendants => 'assets/images/category_pendants.jpg',
    JewelryCategory.watches => 'assets/images/category_watches.jpg',
  };
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
