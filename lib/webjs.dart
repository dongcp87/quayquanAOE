@JS()
library main;

import 'package:js/js.dart';

@JS('copyImgToClipBoard')
external void copyImgToClipBoard(dynamic png);

@JS('webAlert')
external void alert(dynamic text);
