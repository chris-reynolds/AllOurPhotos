/*
  Created by chris reynolds on 2019-08-09
  
  Purpose: This allows you to change the details of an image including location and caption

*/

//import 'dart:html';

import 'package:all_our_photos_app/flutter_common/ChipController.dart';
import 'package:flutter/material.dart';
import 'package:aopmodel/aop_classes.dart';
import '../widgets/wdgImageFilter.dart' show filterColors;
import '../flutter_common/WidgetSupport.dart';
import 'package:aopcommon/aopcommon.dart';

class MetaEditorWidget extends StatefulWidget {
  const MetaEditorWidget({super.key});

  @override
  MetaEditorWidgetState createState() => MetaEditorWidgetState();
}

class MetaEditorWidgetState extends State<MetaEditorWidget> {
  static const String DATE_FORMAT = 'd/m/yyyy hh:nn:ss';
  var formKey = GlobalKey<FormState>();
  AopSnap? snap;
  Map<String, dynamic> values = {};
  ChipSet _baseChips = ChipSet('');
  ChipSet _currentChips = ChipSet('');

  /* base plus any historic in this Snap */
  WebFile? chipFile;
  late ChipSet selectedChips;
  String? currentLocationText;
  List<String> locationList = ['None'];

  void selectChip(BuildContext context, String caption, bool selected) async {
    if (caption == '+' || caption == '-') {
      String prompt = (caption == '+') ? 'Add new' : 'Remove';
      String newChipText = (await inputBox(context, '$prompt Chip Text')) ?? '';
      newChipText = newChipText.trim();
      if (newChipText.isNotEmpty) {
        if (caption == '-') {
          // delete item
          if (!_baseChips.remove(newChipText))
            showMessage(context, 'Failed to remove $newChipText');
          else
            selectedChips.remove(newChipText);
        } else // if (_baseChips.indexOf(newChipText)<0) {  // add if not already there
        if (!_baseChips.add(newChipText))
          showMessage(context, 'Failed to add $newChipText');
        else
          selectedChips.add(newChipText);
      }
      ChipProvider.save(_baseChips).then((result) {
        if (!result) showMessage(context, 'Failed to save names');
      });
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
    _initLocations();
    ChipProvider.remoteLocation = 'photos/tagList.txt';
    ChipProvider.enableLogging = true;
    ChipProvider.load().then((chips) {
      _baseChips = chips;
      setState(() {});
    });
  }

  void _initLocations() async {
    locationList.addAll(await AopSnap.distinctLocations);
    //   setState(() {});
  }

  String? _checkCaption(value) {
    if (value.length > 0 && value.length < 4)
      return "Caption needs at least 4 characters";
    else {
      values['caption'] = value;
      return null;
    }
  } // of checkCaption

  String? _checkDate(String? value) {
    if (value!.length < 5) value = '01/$value';
    if (value.length < 8) value = '01/$value';
    try {
      values['taken_date'] = parseDMY(value);
      return null;
    } catch (ex) {
      return '$ex';
    }
  } // of checkDate

  void _submit(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      snap!.caption = values['caption'];
      snap!.takenDate = values['taken_date'];
      snap!.tagList = selectedChips.toString();
      snap!.ranking = values['ranking'];
      snap!.location = values['location'];
      try {
        var success = await snap!.save();
        if ((success ?? 0) > 0)
          Navigator.pop(context);
        else
          throw Exception('Failed to save image details');
      } catch (ex) {
        log.error('Failed top save metadata : $ex');
        showMessage(context, '$ex');
      }
    } else
      showMessage(context, 'Something is invalid. Not sure what');
  } // of _submit

  @override
  Widget build(BuildContext context) {
    if (_baseChips.toString() == '') return CircularProgressIndicator();
    if (snap == null) {
      snap = ModalRoute.of(context)!.settings.arguments as AopSnap?;
      values = snap!.toMap();
      // remove time if it does not exist
      values['taken_date'] = formatDate(snap!.takenDate!, format: DATE_FORMAT);
      values['taken_date'] = values['taken_date']?.replaceAll(' 00:00:00', '');
      selectedChips = ChipSet(values['tag_list']);
    } // of initial snap assignment
    _currentChips = _baseChips;
    _currentChips.addAll(selectedChips);
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${snap!.fileName}'),
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
              validator: _checkCaption,
              maxLength: 100,
            ),
            // TODO: decide how to handle location lookup
            /*TypeAheadTextField(
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
                  log.message('location ==== $text');
                }
              }),
            ), */
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                return locationList.where((String location) => location
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()));
              },
              initialValue: TextEditingValue(text: values['location'] ?? ''),
              onSelected: (v) {
                values['location'] = v;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Date Taken'),
              initialValue: values['taken_date'].toString(),
              keyboardType: TextInputType.datetime,
              validator: _checkDate,
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
                    child: Icon(Icons.star,
                        color: filterColors[values['ranking']], size: 40.0),
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
                TextButton.icon(
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
