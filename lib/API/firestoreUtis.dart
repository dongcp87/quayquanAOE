import 'package:aoe_gmo/Model/team.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUtils {
  Future<List<Team>> getTeams() async {
    List<Team> team = [];
    final teamData = await FirebaseFirestore.instance
        .collection("team")
        .get(GetOptions(source: Source.server));
    teamData.docs.forEach((element) {
      final t = Team.fromDocument(element);
      team.add(t);
    });
    return team;
  }

  Future<List<String>> getUsers() async {
    List<String> usersName = [];
    final users = await FirebaseFirestore.instance
        .collection("users")
        .orderBy("name")
        .get(GetOptions(source: Source.server));
    users.docs.forEach((element) {
      usersName.add(element.data()["name"]);
    });
    usersName.add("");
    return usersName;
  }

  void saveTeam(List<Team> team) {
    team.forEach((element) {
      FirebaseFirestore.instance
          .collection("team")
          .doc(element.documentId)
          .set(element.toMap());
    });
  }

  Future<String> getResult() async {
    String result;
    final data = await FirebaseFirestore.instance
        .collection("result")
        .doc("data")
        .get(GetOptions(source: Source.server));
    if (data != null) {
      result = data["data"];
    }

    return result;
  }

  void saveResult(String result) {
    FirebaseFirestore.instance
        .collection("result")
        .doc("data")
        .set({"data": result});
  }

  Future<bool> checkAccessToken() async {
    bool result;
    final data = await FirebaseFirestore.instance
        .collection("setting")
        .doc("checkAccessToken")
        .get(GetOptions(source: Source.server));
    if (data != null) {
      result = data["check"];
    }
    return result;
  }

  Future<bool> checkToken(String token) async {
    bool result = false;
    final data = await FirebaseFirestore.instance
        .collection("setting")
        .doc("accessToken")
        .get(GetOptions(source: Source.server));
    data.data().keys.forEach((element) {
      if (data.data()[element] == token) {
        result = true;
      }
    });
    return result;
  }

  void saveSession(String token) {
    FirebaseFirestore.instance
        .collection("session")
        .doc("data")
        .set({"data": token});
  }

  void saveHistory(
      List<Team> team, String result, String number, String token) {
    Map<String, dynamic> history = Map();
    team.forEach((element) {
      history[element.documentId] = element.name;
      history[element.documentId + "type"] = element.type.index;
    });
    history["number"] = number;
    history["result"] = result;
    history["token"] = token;
    FirebaseFirestore.instance.collection("history").doc(number).set(history);
  }

  void saveRoundResult(String result) {
    FirebaseFirestore.instance
        .collection("roundResult")
        .doc("data")
        .set({"data": result});
  }

  Future<String> getRoundResult() async {
    String result;
    final data = await FirebaseFirestore.instance
        .collection("roundResult")
        .doc("data")
        .get(GetOptions(source: Source.server));
    if (data != null) {
      result = data["data"];
    }
    return result;
  }
}
