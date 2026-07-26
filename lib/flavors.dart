enum Flavor {
  prod,
  exp,
}

class F {
  static late final Flavor appFlavor;

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.prod:
        return 'Illish';
      case Flavor.exp:
        return 'Illish Dev';
    }
  }

}
