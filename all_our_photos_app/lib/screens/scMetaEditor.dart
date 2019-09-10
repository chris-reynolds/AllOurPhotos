/*
  Created by chrisreynolds on 2019-08-09
  
  Purpose: This allows you to change the details of an image including location and caption

*/

import 'package:all_our_photos_app/dart_common/WebFile.dart';
import 'package:flutter/material.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import '../shared/aopClasses.dart';
import '../widgets/TypeAheadTextField.dart';
import '../widgets/wdgImageFilter.dart' show filterColors;
import '../dart_common/WidgetSupport.dart';
import '../dart_common/DateUtil.dart';
import '../dart_common/Logger.dart' as Log;
import '../dart_common/WebFile.dart';

class MetaEditorWidget extends StatefulWidget {
  @override
  _MetaEditorWidgetState createState() => _MetaEditorWidgetState();
}

class _MetaEditorWidgetState extends State<MetaEditorWidget> {
  static const String DATE_FORMAT = 'd/m/yyyy hh:nn:ss';
  var formKey = GlobalKey<FormState>();
  GlobalKey<AutoCompleteTextFieldState<String>> locationKey = GlobalKey();
  AopSnap snap;
  Map<String, dynamic> values = {};
  List<String> chips = '+,Annie,Ben,Josie,J+K,E+M,Sunset,Camping,Reynwars,Williams'.split(',');
  WebFile chipFile;
  List<String> selectedChips;
  String currentLocationText;
  List<String> locationList = ['None'];
  TextEditingController locationTextController; // = TextEditingController(text: '');
  final _focusNode = FocusNode();

  void selectChip(BuildContext context,String caption, bool selected) async {
    if (caption == '+') {
      String newChipText = await inputBox(context,'New Chip Text or (-text to delete a tag)');
      if (newChipText != null && newChipText.length >0) {
        if (newChipText.substring(0,1)=='-')  // delete item
          chips.remove(newChipText.substring(1));
        else if (chips.indexOf(newChipText)<0) {  // add if not already there
          chips.add(newChipText);
          selectedChips.add(newChipText);
        }
        chipFile.contents = chips.join(';');
        if (! await saveWebFile(chipFile)){
          showMessage(context, 'Failed to save names');
        }
      }
    }
    bool wasSelected = selectedChips.indexOf(caption) >= 0;
    if (selected != wasSelected) // needs changing
    if (selected)
      selectedChips.add(caption);
    else
      selectedChips.remove(caption);
    setState(() {});
  } // not Chip

  @override
  void initState() {
    super.initState();
    initLocations();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        locationTextController.selection =
            TextSelection(baseOffset: 0, extentOffset: locationTextController.text.length);
      }
    });
    loadWebFile('taglist.txt','+;Annie;Ben;Josie;J+K;E+M;Reynwars').then((thisWebFile){
      chipFile = thisWebFile; // store so we can save changes
      chips = chipFile.contents.split(';');
    });
  }

  void initLocations() async {
    locationList.addAll(await AopSnap.distinctLocations);
    setState(() {});
  }

  String checkCaption(value) {
    if (value.length > 0 && value.length < 10)
      return "Caption needs 10 characters";
    else {
      values['caption'] = value;
      return null;
    }
  } // of checkCaption

  String checkDate(String value) {
    if (value.length < 5) value = '01/$value';
    if (value.length < 8) value = '01/$value';
    try {
      values['taken_date'] = parseDMY(value);
      return null;
    } catch (ex) {
      return '$ex';
    }
  } // of checkDate

  String checkLocation(value) {
    return "Todo checkLocation";
  } // of checkLocation

  void _submit(BuildContext context) async {
    if (formKey.currentState.validate()) {
      snap.caption = values['caption'];
      snap.takenDate = values['taken_date'];
      snap.tagList = selectedChips.join('#');
      snap.ranking = values['ranking'];
      snap.location = values['location'];
      await snap.save();
      Navigator.pop(context);
    }
  } // of _submit

  @override
  Widget build(BuildContext context) {
    if (snap == null) {
      snap = ModalRoute.of(context).settings.arguments as AopSnap;
      values = snap.toMap();
//      values = {
//        'caption': snap.caption,
//        'location': snap.location,
//        'takenDate': formatDate(snap.takenDate,format:'d/m/yyyy hh:nn:ss'),
//        'ranking': snap.ranking
//      };
      // remove time if it does not exist
      values['taken_date'] = formatDate(snap.takenDate, format: DATE_FORMAT);
      values['taken_date'] = values['taken_date']?.replaceAll(' 00:00:00', '');
      selectedChips = values['tag_list']?.split('#');
    } // of initial snap assignment
    locationTextController = TextEditingController(text: values['location']);
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${snap.fileName}'),
      ),
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: <Widget>[

            TypeAheadTextField(
              key: locationKey,
              focusNode: _focusNode,
              decoration: new InputDecoration(labelText: 'Location Lookup', errorText: ''),
              controller: locationTextController,
              //TextEditingController(text: ""),
              suggestions: locationList,
              textChanged: (text) => currentLocationText = text,
              clearOnSubmit: false,
              textSubmitted: (text) => setState(() {
                if (text != "") {
//                  locationTextController.text = text;
                  values['location'] = text;
                  Log.message('location ==== $text');
                }
              }),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Date Taken'),
              initialValue: values['taken_date'],
              keyboardType: TextInputType.datetime,
              validator: checkDate,
              maxLength: 20,
            ),
            FormField(builder: (context) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Ranking',
                  ),
                  Padding(padding: EdgeInsets.only(left: 30)),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        values['ranking'] = (values['ranking']) % 3 + 1;
                      });
                    },
                    child: Icon(Icons.star, color: filterColors[values['ranking']], size: 40.0),
                  ),
                ],
              );
            }),
            Wrap(
              children: chips.map((labelText) {
                return ChoiceChip(
                  label: Text(labelText),
                  selected: selectedChips.indexOf(labelText) >= 0,
                  onSelected: (selected) {
                    selectChip(context,labelText, selected);
                  },
                );
              }).toList(),
            ),
            Padding(padding: EdgeInsets.only(top: 20)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                RaisedButton.icon(
                    icon: Icon(Icons.save),
                    onPressed: () {
                      _submit(context);
                    },
                    label: Text('Save')),
              ],
            ),
          ]), // of column
        ), // of Padding
      ), // of Form
    ); // of scaffold
  } // of build

} // of
