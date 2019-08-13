/*
  Created by chrisreynolds on 2019-08-09
  
  Purpose: This allows you to change the details of an image including location and caption

*/

import '../shared/aopClasses.dart';
import 'package:flutter/material.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import '../widgets/wdgImageFilter.dart' show filterColors;
import '../dart_common/DateUtil.dart';
import '../dart_common/Logger.dart' as Log;

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
  List<String> selectedChips;
  String currentLocationText;
  List<String> locationList = ['None'];
  TextEditingController locationTextController; // = TextEditingController(text: '');

  void selectChip(String caption, bool selected) async {
    if (caption == '+') {
      chips.add('fred');
      selectedChips.add('fred');
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
    if (value.length < 5) value = '1/$value';
    if (value.length < 8) value = '1/$value';
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
            TextFormField(
              decoration: InputDecoration(labelText: 'Caption'),
              initialValue: values['caption'],
              validator: checkCaption,
              onSaved: (input) => values['caption'] = input,
              maxLength: 60,
            ),
            TypeAheadTextField(
              key: locationKey,
              decoration: new InputDecoration(labelText: 'Location Lookup', errorText: ''),
              controller: locationTextController,
              //TextEditingController(text: ""),
              suggestions: locationList,
              textChanged: (text) => currentLocationText = text,
              clearOnSubmit: false,
              textSubmitted: (text) =>
                  setState(() {
                if (text != "") {
//                  locationTextController.text = text;
                  values['location'] = text;
                  Log.message('location ==== $text');
                }
              }),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Location'),
              controller: locationTextController,
//              validator: checkLocation,
              onSaved: (input) => values['location'] = input,
              maxLength: 199,
              onEditingComplete: () {},
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
                    selectChip(labelText, selected);
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

class TypeAheadTextField extends AutoCompleteTextField<String> {
  final StringCallback textChanged, textSubmitted;
  final int minLength;
  final ValueSetter<bool> onFocusChanged;
  final TextEditingController controller;
  final FocusNode focusNode;

  TypeAheadTextField(
      {TextStyle style,
      InputDecoration decoration: const InputDecoration(),
      this.onFocusChanged,
      this.textChanged,
      this.textSubmitted,
      this.minLength = 1,
      this.controller,
      this.focusNode,
      TextInputType keyboardType: TextInputType.text,
      @required GlobalKey<AutoCompleteTextFieldState<String>> key,
      @required List<String> suggestions,
      int suggestionsAmount: 5,
      bool submitOnSuggestionTap: true,
      bool clearOnSubmit: false,
      TextInputAction textInputAction: TextInputAction.done,
      TextCapitalization textCapitalization: TextCapitalization.sentences})
      : super(
            style: style,
            decoration: decoration,
            textChanged: textChanged,
            textSubmitted: textSubmitted,
            itemSubmitted: textSubmitted,
            keyboardType: keyboardType,
            key: key,
            suggestions: suggestions,
            itemBuilder: null,
            itemSorter: null,
            itemFilter: null,
            suggestionsAmount: suggestionsAmount,
            submitOnSuggestionTap: submitOnSuggestionTap,
            clearOnSubmit: clearOnSubmit,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization);

  @override
  State<StatefulWidget> createState() => new AutoCompleteTextFieldState<String>(
          suggestions, textChanged, textSubmitted, onFocusChanged, itemSubmitted, (context, item) {
        return new Padding(padding: EdgeInsets.all(8.0), child: new Text(item));
      }, (a, b) {
        return a.compareTo(b);
      }, (item, query) {
        return item.toLowerCase().contains(query.toLowerCase());
      }, suggestionsAmount, submitOnSuggestionTap, clearOnSubmit, minLength, [], textCapitalization,
          decoration, style, keyboardType, textInputAction, controller, focusNode);
}
