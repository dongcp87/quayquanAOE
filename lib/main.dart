import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:aoe_gmo/API/firestoreUtis.dart';
import 'package:aoe_gmo/API/random_org.dart';
import 'package:aoe_gmo/Model/team.dart';
import 'package:aoe_gmo/Model/unit.dart';
import 'package:aoe_gmo/Model/version.dart';
import 'package:aoe_gmo/webjs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
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

  final resultController = TextEditingController();

  bool isClickRandom = false;

  void getData() async {
    team = await firestoreUtils.getTeams();

    responseString = await firestoreUtils.getResult();
    checkAccessToken = await firestoreUtils.checkAccessToken();
    textController.text = await getAccessToken();
    accessTokenOk = await firestoreUtils.checkToken(textController.text);
    resultController.text = await firestoreUtils.getRoundResult();
    loadResult();
    setState(() {
      isClickRandom = false;
      isLoading = false;
    });
  }

  void getUsers() async {
    usersName = await firestoreUtils.getUsers();
  }

  void getRandom() async {
    isClickRandom = true;
    team.forEach((element) {
      usersName.add(element.name);
    });
    usersName = usersName.toSet().toList();
    FocusManager.instance.primaryFocus?.unfocus();
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
    getUsers();
    getData();
    allUnit = Unit.all();
    resultStream =
        FirebaseFirestore.instance.collection("result").doc("data").snapshots();
    resultStream.listen((event) {
      if (isClickRandom) {
        isClickRandom = false;
      } else {
        getData();
      }
    });
    settingStream =
        FirebaseFirestore.instance.collection("setting").snapshots();
    settingStream.listen((event) {
      getData();
    });

    super.initState();
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
                  "Bảng quân",
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              )
            ],
          ),
        ],
      ),
      body: ModalProgressHUD(
        inAsyncCall: isLoading,
        child: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: mainView(),
        ),
      ),
      // floatingActionButton: allowEdit()
      //     ? FloatingActionButton(
      //         onPressed: () {
      //           addNewMemberDialog();
      //         },
      //         child: Icon(Icons.person_add_alt_1_rounded),
      //       )
      //     : null, // This trailing comma makes auto-formatting nicer for build methods.
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
          roundResultDisplay(),
          roundResultInput(),
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

  void addNewMemberDialog() {
    String memberName;

    bool isAllowAdd() {
      if (memberName != null && memberName.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("Nhập tên"),
            content: TextField(
              onChanged: (var string) {
                memberName = string;
                setState(() {});
              },
            ),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              TextButton(
                child: Text('Add'),
                onPressed: isAllowAdd()
                    ? () {
                        firestoreUtils.addNewMember(memberName);
                        Navigator.of(context).pop();
                      }
                    : null,
              ),
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
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
        Padding(
          padding: EdgeInsets.all(20),
          child: OutlinedButton(
            onPressed: responseString == null
                ? null
                : () {
                    screenshotController
                        .capture(delay: Duration(milliseconds: 0))
                        .then((Uint8List image) async {
                      // saveAs(image, "QuayQuan#$serialNumber");
                      if (kIsWeb) {
                        copyImgToClipBoard(image);
                      }
                      Toast.show(
                        "Đã copy vào clipboard",
                        context,
                        duration: 2,
                        gravity: Toast.CENTER,
                      );
                    }).catchError((onError) {
                      print(onError);
                    });
                  },
            child: Icon(Icons.camera_alt_outlined),
          ),
        ),
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
            Container(
              width: 100,
              child: Autocomplete(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  team[index].name = textEditingValue.text;
                  if (textEditingValue.text == '') {
                    return Iterable<String>.empty();
                  }
                  var list = usersName.where((String option) {
                    return option
                        .toLowerCase()
                        .startsWith(textEditingValue.text.toLowerCase());
                  });
                  list = list.toSet().toList();
                  return list;
                },
                onSelected: (String selection) {
                  team[index].name = selection;
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted) {
                  fieldTextEditingController..text = team[index].name;
                  return TextField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    // enabled: allowEdit(),
                  );
                },
                optionsViewBuilder: (BuildContext context,
                    AutocompleteOnSelected<String> onSelected,
                    Iterable<String> options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                        child: Container(
                      width: 200,
                      height: 300,
                      color: Colors.blue,
                      child: ListView.builder(
                        padding: EdgeInsets.all(10.0),
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final option = options.elementAt(index);

                          return ListTile(
                            title: Text(
                              option,
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              onSelected(option);
                            },
                          );
                        },
                      ),
                    )),
                  );
                },
              ),
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
        Screenshot(
          controller: screenshotController,
          child: Container(
            color: Colors.white,
            width: _screenWidth,
            height: cellHeight * 6,
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
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
                            fontSize: 13,
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

  // void saveAs(List<int> bytes, String fileName) {
  //   final blob = html.Blob([bytes]);
  //   final url = html.Url.createObjectUrlFromBlob(blob);
  //   final anchor = html.document.createElement('a') as html.AnchorElement
  //     ..href = url
  //     ..style.display = 'none'
  //     ..download = '$fileName.png';
  //   html.document.body.children.add(anchor);

  //   // download
  //   anchor.click();

  //   // cleanup
  //   html.document.body.children.remove(anchor);
  //   html.Url.revokeObjectUrl(url);
  // }

  Widget roundResultDisplay() {
    return Row(
      children: [
        Spacer(),
        Container(
          alignment: Alignment.center,
          color: Colors.black,
          width: 400,
          height: 30,
          child: Text(
            resultController.text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Spacer(),
      ],
    );
  }

  Widget roundResultInput() {
    return Row(
      children: [
        Spacer(),
        Container(
          alignment: Alignment.centerLeft,
          width: 400,
          height: 50,
          child: TextField(
            controller: resultController,
            decoration: InputDecoration(
              hintText: "Nhập kết quả",
              suffixIcon: IconButton(
                onPressed: allowEdit()
                    ? () {
                        resultController.text =
                            "C1: 0-0 | C2: 0-0 | C3: 0-0 | C4: 0-0 | C5: 0-0";
                        firestoreUtils
                            .saveRoundResult(resultController.text ?? "");
                        setState(() {});
                      }
                    : null,
                icon: Icon(Icons.replay),
              ),
            ),
            onChanged: (text) {
              firestoreUtils.saveRoundResult(text ?? "");
              setState(() {});
            },
            enabled: allowEdit(),
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