/*
Created by chris reynolds on 2019-05-09

Purpose: This file provides some utilities to make Flutter less verbose

*/

import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';

// import 'package:flutter_form_builder/flutter_form_builder.dart';

class UIPreferences {
  static String mode = 'Unset';
  static double iconSize = 20;
  static double iconBorder = 2;
  static double textSize = 20;
  static int maxGridColumns = 5;
  static int defaultGridColumns = 2;
  static bool isSmallScreen = false;
  static bool isMediumScreen = false;
  static bool isLargeScreen = false;
  static Color monthDone = Colors.blue;
  static Color monthToDo = Colors.amber;
  static Color monthEmpty = Color(0xFFE0E0E0);
  static get borderedIcon => iconSize + 2 * iconBorder;
  static void setContext(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    isSmallScreen = false;
    isMediumScreen = false;
    isLargeScreen = false;
    if (width < 600) {
      mode = 'Phone';
      iconSize = 20;
      textSize = 12;
      maxGridColumns = 3;
      defaultGridColumns = 1;
      isSmallScreen = true;
    } else if (width <= 1200) {
      mode = 'Tablet';
      iconSize = 36;
      textSize = 20;
      maxGridColumns = 5;
      defaultGridColumns = 2;
      isMediumScreen = true;
    } else {
      mode = 'Desktop';
      iconSize = 40;
      textSize = 24;
      maxGridColumns = 6;
      defaultGridColumns = 3;
      isLargeScreen = true;
    }
    log.message('width=$width mode=$mode **************************');
  } // of setWidth
} // ofr UIPreferences

class MyIconButton extends SizedBox {
  MyIconButton(IconData icondata,
      {void Function()? onPressed, Color? color, bool enabled = true})
      : super(
          width: UIPreferences.borderedIcon,
          height: UIPreferences.borderedIcon,
          child: InkWell(
              onTap: enabled ? onPressed : null,
              enableFeedback: enabled,
              child: enabled
                  ? ((color == null)
                      ? Icon(
                          icondata,
                          size: UIPreferences.iconSize,
                        )
                      : Icon(
                          icondata,
                          color: color,
                          size: UIPreferences.iconSize,
                        ))
                  : Icon(icondata,
                      size: UIPreferences.iconSize, color: Colors.black12)),
        );
}

Text myText(String data) =>
    Text(data, style: TextStyle(fontSize: UIPreferences.textSize));

class AssetWidget extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  const AssetWidget(this.name,
      {super.key, this.size = 50, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageIcon(AssetImage('assets/$name'),
        size: size, color: color //Theme.of(context).colorScheme.secondary,
        );
  } // of build
} // of AssetWidget

BottomNavigationBarItem bottomButton(String keyText, IconData valueIcon) =>
    BottomNavigationBarItem(icon: Icon(valueIcon), label: keyText);

IconButton navIconButton(
        BuildContext context, String routeName, IconData valueIcon) =>
    IconButton(
        icon: Icon(valueIcon),
        tooltip: routeName,
        onPressed: () async {
          Navigator.pushNamed(context, routeName);
        });

/// WSValidator typedef is used to inject validators into a form definition
typedef WsValidator = String Function(dynamic value);

class WsFieldDef {
  late List<String> bits;
  WsFieldDef(String fieldDef) {
    bits = ('$fieldDef:::::').split(':');
    if (bits[1] == '')
      bits[1] = bits[0]; // copy key from prompt text if missing
  }
  String get fieldName => bits[1];
  String get prompt => bits[0];
} // of WsFieldDef

class WsFieldSet {
  final Map<String, Container> _widgetMap = {};
  WsFieldSet(List<String> defStrings,
      {Map<String, dynamic> values = const {}, double? spacer}) {
    for (var thisDef in defStrings) {
      WsFieldDef thisFieldDef = WsFieldDef(thisDef);
      _widgetMap[thisFieldDef.fieldName] = wsTextField(thisFieldDef.prompt,
          key: thisFieldDef.fieldName,
          spacer: spacer,
          initValue: values[thisFieldDef.fieldName]);
    }
  }
  List<Container> get widgets => _widgetMap.values.toList();
  Map<String, dynamic> get values {
    Map<String, dynamic> result = {};
    _widgetMap.forEach((fieldName, widget) {
      if (widget.child is TextFormField)
        result[fieldName] = (widget.child as TextFormField).controller!.text;
    }); // of forEach
    return result;
  }
} //end of WsfieldSet

Container wsTextField(String promptText,
    {required String key, double? spacer, dynamic initValue}) {
  return Container(
      key: Key(key),
      padding: EdgeInsets.fromLTRB(0, spacer ?? 12, 0, 0),
      child: TextFormField(
        key: Key(key), maxLines: 1,
        controller: TextEditingController(text: initValue),
        decoration: InputDecoration(
          labelText: promptText,
          contentPadding: EdgeInsets.fromLTRB(0, spacer ?? 12, 0, 0),
          filled: true,
        ),
//        initialValue: initValue,
        obscureText: (promptText.toLowerCase().contains('password')),
      ));
} // of wsText

Widget wsMakeField(String fieldDef, {required Map values, double? spacer}) {
  List<String> bits = ('$fieldDef:::::').split(':');
  if (bits[1] == '') bits[1] = bits[0]; // copy key from prompt text if missing
  dynamic initValue = values[bits[1]] ?? '';
  return wsTextField(bits[0],
      key: bits[1], spacer: spacer, initValue: initValue);
} // of wsFieldList

// } // wsFormValues

WsValidator? makeValidator(String vets) {
  return null; // TO-DO: setup validators. Mainly required, min length, regex
} // make validator

Future<bool?> confirmYesNo1(BuildContext context, String question) async {
/*it shows a popup with few options which you can select, for option we
        created enums which we can use with switch statement, in this first switch
        will wait for the user to select the option which it can use with switch cases*/
  return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('$question?'),
          children: <Widget>[
            SimpleDialogOption(
              child: Text('Yes'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            SimpleDialogOption(
              child: Text('No'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      } // of builder
      ); // of showDialog
}

Future<String?> inputBox(BuildContext context, String question) async {
/*it shows a popup with few options which you can select, for option we
        created enums which we can use with switch statement, in this first switch
        will wait for the user to select the option which it can use with switch cases*/
  return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        String newText = '';
        return SimpleDialog(
          title: Text('$question?'),
          contentPadding: EdgeInsets.all(12),
          children: <Widget>[
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                newText = text;
              },
              onEditingComplete: () {
                Navigator.pop(context, newText);
              },
            ),
          ],
        );
      } // of builder
      ); // of inputBox
}

Future<bool?> confirmYesNo(BuildContext context, String question,
    {String description = ''}) async {
  TextStyle? myStyle = Theme.of(context).textTheme.bodyLarge;
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(question),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              for (String line in description.split('\n')) Text(line),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton.icon(
            icon: Icon(
              Icons.check,
              color: myStyle!.color,
            ),
            label: Text(
              'Yes',
              style: myStyle,
            ),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
          TextButton.icon(
            icon: Icon(
              Icons.close,
              color: myStyle.color,
            ),
            label: Text('No', style: myStyle),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
        ],
      );
    },
  );
} // OF ConfirmYesNo

Future<bool?> showMessage(BuildContext context, String message,
    {String? title}) async {
  TextStyle? myStyle = Theme.of(context).textTheme.bodyLarge;
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title ?? "--"),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              for (String line in message.split('\n')) Text(line),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton.icon(
            icon: Icon(
              Icons.close,
              color: myStyle!.color,
            ),
            label: Text('OK', style: myStyle),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
        ],
      );
    },
  );
} // OF showMessage

Future<T?> showSelectDialog<T>(BuildContext context, String title,
    String entityType, List<dynamic> items, Function descriptor) async {
//  String _selectedOption;
  return showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(title),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                // Navigator.of(context).pop();
              },
              child: Center(
                child: DropdownButton<String>(
                    hint: Text("Select the new $entityType"),
                    value: null,
                    items: items.map((val) {
                      return DropdownMenuItem<String>(
                        value: descriptor(val),
                        child: Text(descriptor(val)),
                      );
                    }).toList(),
                    onChanged: (newVal) {
                      for (dynamic item in items)
                        if (descriptor(item) == newVal)
                          Navigator.pop(context, item);
//                      _selectedOption = newVal;
                    }),
              ),
            ),
          ],
        );
      });
} // of showSelectDialog

void showSnackBar(String message, BuildContext context) {
  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
} // of showSnackBar

FutureBuilder<List<Object>> aFutureBuilder({
  Key? key,
  required Future<List<Object>>? future,
  List<Object>? initialData,
  required Widget Function(BuildContext, AsyncSnapshot<List<Object>>) builder,
}) {
  return FutureBuilder(
    future: future,
    initialData: initialData,
    builder: (context, snapshot) {
      switch (snapshot.connectionState) {
        case ConnectionState.waiting:
          return Center(child: CircularProgressIndicator());
        case ConnectionState.done:
          if (snapshot.hasError)
            return Center(child: Text('${snapshot.error}'));
          if (!snapshot.hasData) return Center(child: Text('todo has no data'));
          // we are finally done with good data
          return builder(context, snapshot);
        default:
          return Text('State: ${snapshot.connectionState}');
      }
    },
  );
} // aFutureBuilder
