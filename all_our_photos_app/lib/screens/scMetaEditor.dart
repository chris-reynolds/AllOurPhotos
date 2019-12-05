/*
  Created by chrisreynolds on 2019-08-09
  
  Purpose: This allows you to change the details of an image including location and caption

*/

import 'package:all_our_photos_app/dart_common/WebFile.dart';
import 'package:all_our_photos_app/flutter_common/ChipController.dart';
import 'package:flutter/material.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import '../shared/aopClasses.dart';
import '../widgets/TypeAheadTextField.dart';
import '../widgets/wdgImageFilter.dart' show filterColors;
import '../flutter_common/WidgetSupport.dart';
import '../flutter_common/ChipController.dart';
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
  ChipSet _baseChips;
  ChipSet _currentChips;

  /* base plus any historic in this Snap */
  WebFile chipFile;
  ChipSet selectedChips;
  String currentLocationText;
  List<String> locationList = ['None'];
  TextEditingController locationTextController; // = TextEditingController(text: '');
  final _focusNode = FocusNode();

  void selectChip(BuildContext context, String caption, bool selected) async {
    if (caption == '+' || caption == '-') {
      String prompt = (caption == '+') ? 'Add new' : 'Remove';
      String newChipText = await inputBox(context, '$prompt Chip Text');
      if (newChipText != null && newChipText.length > 0) {
        if (caption == '-') {
          // delete item
          _baseChips.remove(newChipText);
          _currentChips.remove(newChipText);
        } else // if (_baseChips.indexOf(newChipText)<0) {  // add if not already there
          _baseChips.add(newChipText);
        selectedChips.add(newChipText);
      }
      if (!await ChipController.save(_baseChips)) {
        showMessage(context, 'Failed to save names');
      }
    }
    bool wasSelected = selectedChips.contains(caption);
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
    ChipController.remoteLocation = 'tagList.txt';
    ChipController.enableLogging = true;
    ChipController.load().then((chips) {
      _baseChips = chips;
      setState(() {});
    });
  }

  void initLocations() async {
    locationList.addAll(await AopSnap.distinctLocations);
    //   setState(() {});
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
      snap.tagList = selectedChips.toString();
      snap.ranking = values['ranking'];
      snap.location = values['location'];
      await snap.save();
      Navigator.pop(context);
    }
  } // of _submit

  @override
  Widget build(BuildContext context) {
    if (_baseChips == null)
      return CircularProgressIndicator();
    if (snap == null) {
      snap = ModalRoute.of(context).settings.arguments as AopSnap;
      values = snap.toMap();
      // remove time if it does not exist
      values['taken_date'] = formatDate(snap.takenDate, format: DATE_FORMAT);
      values['taken_date'] = values['taken_date']?.replaceAll(' 00:00:00', '');
      selectedChips = ChipSet(values['tag_list']);
    } // of initial snap assignment
    _currentChips = _baseChips;
    _currentChips?.addAll(selectedChips);
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
            TextFormField(
              decoration: InputDecoration(labelText: 'caption'),
              initialValue: values['caption'],
              keyboardType: TextInputType.text,
              validator: checkCaption,
              maxLength: 100,
            ),
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
              initialValue: values['taken_date'].toString(),
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
              children: _currentChips.chips.map((labelText) {
                return ChoiceChip(
                  label: Text(labelText),
                  selected: selectedChips.contains(labelText),
                  onSelected: (selected) {
                    selectChip(context, labelText, selected);
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
