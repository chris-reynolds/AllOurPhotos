/*
  Created by chrisreynolds on 2019-08-20
  
  Purpose: this is to provide us with a standard widget for typeahead

*/
import 'package:flutter/material.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';


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

  bool subStringMatcher(String item,String query) => item.toLowerCase().contains(query.toLowerCase());

  Widget tileBuild(context,item) {
    return new Padding(padding: EdgeInsets.all(8.0), child: new Text(item));
  } //  tileBuild

  @override
  State<StatefulWidget> createState() => new AutoCompleteTextFieldState<String>(
      suggestions, textChanged, textSubmitted, onFocusChanged, itemSubmitted, tileBuild, (a, b) {
    return a.compareTo(b);
  }, subStringMatcher, suggestionsAmount, submitOnSuggestionTap, clearOnSubmit, minLength, [], textCapitalization,
      decoration, style, keyboardType, textInputAction, controller, focusNode);
}


