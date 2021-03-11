class Unit {
  String name;
  Unit(this.name);

  static List<Unit> all() {
    List<Unit> list = [];
    list.add(Unit("Assyrian"));
    list.add(Unit("Babylonian"));
    list.add(Unit("Carthaginian"));
    list.add(Unit("Choson"));
    list.add(Unit("Egyptian"));
    list.add(Unit("Greek"));
    list.add(Unit("Hittite"));
    list.add(Unit("Macedonian"));
    list.add(Unit("Minoan"));
    list.add(Unit("Palmyran"));
    list.add(Unit("Persian"));
    list.add(Unit("Phoenician"));
    list.add(Unit("Roman"));
    list.add(Unit("Shang"));
    list.add(Unit("Sumerian"));
    list.add(Unit("Yamato"));
    return list;
  }
}
