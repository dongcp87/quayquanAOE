import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  String name;
  SelectUnitType type;
  String documentId;

  Team(this.name, this.type, this.documentId);

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map();
    map["name"] = name;
    map["type"] = type.index;
    map["number"] = int.parse(documentId);
    return map;
  }

  factory Team.fromDocument(DocumentSnapshot doc) {
    int type = doc.get("type") ?? 0;
    String name = doc.get("name") ?? "";
    return Team(name, SelectUnitType.values[type], doc.id);
  }
}

enum SelectUnitType { random, optional, shang }

extension SelectUnitTypeExtension on SelectUnitType {
  String get name {
    switch (this) {
      case SelectUnitType.random:
        return 'Random';
      case SelectUnitType.optional:
        return 'Tự chọn';
      case SelectUnitType.shang:
        return 'Shang(*)';
      default:
        return '';
    }
  }

  int get index {
    switch (this) {
      case SelectUnitType.random:
        return 0;
      case SelectUnitType.optional:
        return 1;
      case SelectUnitType.shang:
        return 2;
      default:
        return null;
    }
  }
}
