import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:aoe_gmo/API/firestoreUtis.dart';
import 'package:aoe_gmo/API/random_org.dart';
import 'package:aoe_gmo/Model/team.dart';
import 'package:aoe_gmo/Model/unit.dart';
import 'package:aoe_gmo/Model/version.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quay quân',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'QUAY QUÂN AOE'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> usersName = [];
  List<Team> team = [];
  List<int> data = [];
  String responseString;

  List<Unit> allUnit = [];

  List<String> unitRandom = [];

  FirestoreUtils firestoreUtils = FirestoreUtils();
  ScreenshotController screenshotController = ScreenshotController();
  // Uint8List _imageFile;

  var serialNumber;
  var dateLocal;

  var randomData;
  var signature;

  bool checkAccessToken = true;

  bool isLoading = true;

  bool isRequestRandomOrg = false;

  bool accessTokenOk = false;

  final textController = TextEditingController();

  Stream<DocumentSnapshot> resultStream;
  Stream<QuerySnapshot> settingStream;

  bool shouldSaveHistory = false;

  void getData() async {
    usersName = await firestoreUtils.getUsers();
    team = await firestoreUtils.getTeams();
    responseString = await firestoreUtils.getResult();
    checkAccessToken = await firestoreUtils.checkAccessToken();
    textController.text = await getAccessToken();
    accessTokenOk = await firestoreUtils.checkToken(textController.text);
    loadResult();
    setState(() {
      isLoading = false;
    });
  }

  void getRandom() async {
    isRequestRandomOrg = true;
    var response = await RandomOrgAPI().getRandom();
    if (response.statusCode == 200) {
      shouldSaveHistory = true;
      responseString = response.body;
      firestoreUtils.saveTeam(team);
      firestoreUtils.saveResult(responseString);
      firestoreUtils.saveSession(textController.text ?? "");
      loadResult();
      setState(() {});
    }
    isRequestRandomOrg = false;
  }

  void loadResult() {
    if (responseString != null) {
      final responseJson = json.decode(responseString);
      data = responseJson["result"]["random"]["data"].cast<int>();
      serialNumber = responseJson["result"]["random"]["serialNumber"];
      var completionTime = responseJson["result"]["random"]["completionTime"];
      randomData = responseJson["result"]["random"];
      signature = Uri.encodeQueryComponent(
          responseJson["result"]["signature"].toString());
      DateTime dateTime = DateTime.parse(completionTime);
      dateLocal = dateTime.toLocal();
      unitRandom = [];
      data.forEach((element) {
        var name = allUnit[element - 1].name;
        unitRandom.add(name);
      });
      if (shouldSaveHistory) {
        firestoreUtils.saveHistory(team, responseString,
            serialNumber.toString(), textController.text ?? "");
        shouldSaveHistory = false;
      }
    }
  }

  void resetData() {
    setState(() {
      responseString = null;
      unitRandom = [];
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
    allUnit = Unit.all();
    resultStream =
        FirebaseFirestore.instance.collection("result").doc("data").snapshots();
    resultStream.listen((event) {
      getData();
    });
    settingStream =
        FirebaseFirestore.instance.collection("setting").snapshots();
    settingStream.listen((event) {
      getData();
    });
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title + " (v$version)"),
        actions: [
          ButtonBar(
            children: [
              OutlinedButton(
                onPressed: () {
                  showAccessTokenDialog();
                },
                child: Text(
                  "Access Token",
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  showUnitTable();
                },
                child: Text(
                  "BẢNG QUÂN",
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              )
            ],
          ),
        ],
      ),
      body: ModalProgressHUD(
        inAsyncCall: isLoading,
        child: mainView(),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget mainView() {
    if (isLoading) {
      return Container();
    } else {
      return ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          teamGrid(),
          pickButton(),
          unitGrid(),
          utilButton(),
        ],
      );
    }
  }

  Widget pickButton() {
    return Row(
      children: [
        Spacer(),
        Padding(
            padding: EdgeInsets.all(20),
            child: OutlinedButton(
              onPressed: pickUnit(),
              child: Text(
                "QUAY",
                style: TextStyle(fontSize: 20),
              ),
            )),
        Spacer(),
      ],
    );
  }

  VoidCallback pickUnit() {
    if (isRequestRandomOrg) {
      return null;
    }
    if (!checkAccessToken) {
      return () {
        resetData();
        getRandom();
      };
    } else {
      if (accessTokenOk) {
        return () {
          resetData();
          getRandom();
        };
      }
    }
    return null;
  }

  bool allowEdit() {
    if (!checkAccessToken) {
      return true;
    } else {
      if (accessTokenOk) {
        return true;
      }
    }
    return false;
  }

  void verifySignature() async {
    var base64 =
        Base64Encoder().convert(Utf8Encoder().convert(json.encode(randomData)));
    var url =
        "https://api.random.org/signatures/form?format=json&random=$base64&signature=$signature";
    if (await canLaunch(url)) await launch(url);
  }

  void showAccessTokenDialog() {
    getAccessToken();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Text("Nhập Access Token"),
          content: TextField(
            controller: textController,
            obscureText: true,
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            TextButton(
              child: Text('OK'),
              onPressed: () {
                saveAccessToken();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void saveAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("accessToken", textController.text ?? "");
    accessTokenOk = await firestoreUtils.checkToken(textController.text ?? "");
    Navigator.of(context).pop();
    setState(() {});
  }

  Future<String> getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    textController.text = prefs.getString("accessToken") ?? "";
    return textController.text ?? "";
  }

  void showUnitTable() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Text("Bảng quân"),
          content: Image.asset(
            "bangquan.png",
            width: 300,
            height: 500,
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget utilButton() {
    return Row(
      children: [
        Spacer(),
        // Padding(
        //   padding: EdgeInsets.all(20),
        //   child: OutlinedButton(
        //     onPressed: () {
        //       _imageFile = null;
        //       screenshotController
        //           .capture(delay: Duration(milliseconds: 10))
        //           .then((Uint8List image) async {
        //         _imageFile = image;
        //         showDialog(
        //           context: context,
        //           builder: (context) => Scaffold(
        //             appBar: AppBar(
        //               title: Text("CAPURED SCREENSHOT"),
        //             ),
        //             body: Center(
        //                 child: Column(
        //               children: [
        //                 _imageFile != null
        //                     ? Image.memory(_imageFile)
        //                     : Container(),
        //               ],
        //             )),
        //           ),
        //         );
        //       }).catchError((onError) {
        //         print(onError);
        //       });
        //     },
        //     child: Text("CHỤP"),
        //   ),
        // ),
        Padding(
          padding: EdgeInsets.all(20),
          child: OutlinedButton(
            onPressed: responseString == null
                ? null
                : () {
                    verifySignature();
                  },
            child: Row(
              children: [
                Text(
                  "VERIFY RANDOM.ORG",
                  style: TextStyle(fontSize: 10),
                ),
                Icon(Icons.open_in_new),
              ],
            ),
          ),
        ),
        Spacer(),
      ],
    );
  }

  Widget teamGrid() {
    var _crossAxisSpacing = 0;
    var _screenWidth = MediaQuery.of(context).size.width;
    var _crossAxisCount = 2;
    var _width = (_screenWidth - ((_crossAxisCount - 1) * _crossAxisSpacing)) /
        _crossAxisCount;
    var cellHeight = 60;
    var _aspectRatio = _width / cellHeight;
    return GridView.builder(
      itemCount: team.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _crossAxisCount,
          childAspectRatio: _aspectRatio,
          mainAxisSpacing: 20,
          crossAxisSpacing: 30),
      itemBuilder: (BuildContext context, int index) {
        var align = MainAxisAlignment.start;
        if (index % 2 == 0) {
          align = MainAxisAlignment.end;
        }
        return Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: align,
          children: [
            DropdownButton<String>(
              value: team[index].name ?? "",
              icon: Icon(Icons.more_vert_sharp),
              iconSize: 16,
              elevation: 8,
              style: TextStyle(color: Colors.blueAccent),
              onChanged: allowEdit()
                  ? (String newValue) {
                      setState(() {
                        team[index].name = newValue;
                        resetData();
                      });
                    }
                  : null,
              items: usersName.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(width: 10),
            DropdownButton<String>(
              value: team[index].type.name ?? SelectUnitType.random.name,
              icon: Icon(Icons.more_vert_sharp),
              iconSize: 16,
              elevation: 8,
              style: TextStyle(color: Colors.deepPurple),
              onChanged: allowEdit()
                  ? (String newValue) {
                      setState(() {
                        if (newValue == SelectUnitType.optional.name) {
                          team[index].type = SelectUnitType.optional;
                        } else if (newValue == SelectUnitType.shang.name) {
                          team[index].type = SelectUnitType.shang;
                        } else {
                          team[index].type = SelectUnitType.random;
                        }
                      });
                    }
                  : null,
              items: SelectUnitType.values
                  .map<DropdownMenuItem<String>>((SelectUnitType value) {
                return DropdownMenuItem<String>(
                  value: value.name,
                  child: Text(value.name),
                );
              }).toList(),
            )
          ],
        );
      },
    );
  }

  Widget unitGrid() {
    var _crossAxisSpacing = 0;
    var _screenWidth = min(MediaQuery.of(context).size.width, 400);
    var _crossAxisCount = 2;
    var _width = (_screenWidth - ((_crossAxisCount - 1) * _crossAxisSpacing)) /
        _crossAxisCount;
    var cellHeight = 25.0;
    var _aspectRatio = _width / cellHeight;
    var itemCount = 0;
    const addCell = 4;
    if (unitRandom.length > 0) {
      itemCount = unitRandom.length + addCell;
    }
    return Row(
      children: [
        Spacer(),
        Container(
          width: _screenWidth,
          height: cellHeight * 6,
          child: Screenshot(
            controller: screenshotController,
            child: GridView.builder(
              itemCount: itemCount,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount,
                childAspectRatio: _aspectRatio,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
              ),
              itemBuilder: (BuildContext context, int index) {
                var nameColor = Colors.red;
                if (index % 2 != 0) {
                  nameColor = Colors.blue;
                }

                if (index == 0) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "#$serialNumber",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  );
                } else if (index == 1) {
                  return Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        dateLocal.toString(),
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ));
                } else if (index == 2) {
                  return Container(
                    padding: EdgeInsets.only(left: 5),
                    alignment: Alignment.centerLeft,
                    color: nameColor,
                    child: Text(
                      "TEAM 1",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  );
                } else if (index == 3) {
                  return Container(
                    padding: EdgeInsets.only(left: 5),
                    alignment: Alignment.centerLeft,
                    color: nameColor,
                    child: Text(
                      "TEAM 2",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  );
                }
                var name = team[index - addCell].name ?? "";
                var unit = "";
                if (name.isNotEmpty) {
                  var type =
                      team[index - addCell].type ?? SelectUnitType.random;
                  if (type != SelectUnitType.random) {
                    unit = type.name;
                  } else {
                    unit = unitRandom[index - addCell];
                  }
                }
                return Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 5),
                      alignment: Alignment.centerLeft,
                      width: 100,
                      color: nameColor,
                      child: Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(left: 10),
                        color: Colors.white,
                        child: Text(
                          unit,
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Spacer(),
      ],
    );
  }
}

class VerifySignaturePage extends StatefulWidget {
  VerifySignaturePage({Key key, this.title, this.response}) : super(key: key);

  final String title;
  final String response;

  @override
  VerifySignatureState createState() => VerifySignatureState();
}

class VerifySignatureState extends State<VerifySignaturePage> {
  String body;
  String result;
  void verifySignature() async {
    var response = await RandomOrgAPI().verifySignature(body);
    result = response.body;
    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    var resultJson = jsonDecode(widget.response);
    Map<String, dynamic> map = Map();
    map["random"] = resultJson["result"]["random"];
    map["signature"] = resultJson["result"]["signature"];
    var string = {
      "jsonrpc": "2.0",
      "method": "verifySignature",
      "params": map,
      "id": 1
    };
    body = json.encode(string);
    verifySignature();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          SelectableText("https://api.random.org/json-rpc/2/invoke"),
          SelectableText(body),
          SelectableText(result ?? ""),
          // OutlinedButton(
          //   onPressed: () {
          //     verifySignature();
          //   },
          //   child: Text("VERIFY RANDOM.ORG"),
          // ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  String getPrettyJSONString(jsonObject) {
    var encoder = new JsonEncoder.withIndent("     ");
    return encoder.convert(jsonObject);
  }
}
