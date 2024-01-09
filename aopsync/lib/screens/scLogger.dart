/*
  Created by chrisreynolds on 18/01/21
  
  Purpose: Manage the background log array

*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aopcommon/aopcommon.dart';

class LoggerList extends StatefulWidget {
  const LoggerList({Key? key}) : super(key: key);

  @override
  LoggerListState createState() => LoggerListState();
}

class LoggerListState extends State<LoggerList> {
  Widget appBarTitle = Text(
    "Logger (with filter and clear)",
    style: TextStyle(color: Colors.white),
  );
  Icon actionIcon = Icon(
    Icons.search,
    color: Colors.white,
  );
  final key = GlobalKey<ScaffoldState>();
  final TextEditingController _searchQuery = TextEditingController();
  late List<String> _list;
  late bool _isSearching;
  String _searchText = "";

  LoggerListState() {
    _searchQuery.addListener(() {
      if (_searchQuery.text.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchText = "";
        });
      } else {
        setState(() {
          _isSearching = true;
          _searchText = _searchQuery.text;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _isSearching = false;
    _list = log.logHistory;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: key,
      appBar: buildBar(context),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        children: _isSearching ? _buildSearchList() : _buildList(),
      ),
    );
  }

  List<ChildItem> _buildList() {
    return _list.map((contact) => ChildItem(contact)).toList();
  }

  List<ChildItem> _buildSearchList() {
    if (_searchText.isEmpty) {
      return _list.map((contact) => ChildItem(contact)).toList();
    } else {
      List<String> searchList = <String>[];
      for (int i = 0; i < _list.length; i++) {
        String name = _list.elementAt(i);
        if (name.toLowerCase().contains(_searchText.toLowerCase())) {
          searchList.add(name);
        }
      }
      return searchList.map((contact) => ChildItem(contact)).toList();
    }
  }

  PreferredSizeWidget buildBar(BuildContext context) {
    return AppBar(centerTitle: true, title: appBarTitle, actions: <Widget>[
      IconButton(
        icon: Icon(Icons.delete),
        iconSize: 30,
        onPressed: () {
          log.clear();
          log.save();
          setState(() {
            _list = [];
          });
        },
      ),
      IconButton(
        icon: Icon(Icons.copy),
        iconSize: 30,
        onPressed: () {
          Clipboard.setData(ClipboardData(text: _list.join('\n')));
        },
      ),
      IconButton(
        icon: actionIcon,
        onPressed: () {
          setState(() {
            if (actionIcon.icon == Icons.search) {
              actionIcon = Icon(
                Icons.close,
                color: Colors.white,
              );
              appBarTitle = TextField(
                controller: _searchQuery,
                style: TextStyle(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                    hintText: "Filter...",
                    hintStyle: TextStyle(color: Colors.white)),
              );
              _handleSearchStart();
            } else {
              _handleSearchEnd();
            }
          });
        },
      ),
    ]);
  }

  void _handleSearchStart() {
    setState(() {
      _isSearching = true;
    });
  }

  void _handleSearchEnd() {
    setState(() {
      actionIcon = Icon(
        Icons.search,
        color: Colors.white,
      );
      appBarTitle = Text(
        "Search Sample",
        style: TextStyle(color: Colors.white),
      );
      _isSearching = false;
      _searchQuery.clear();
    });
  }
}

class ChildItem extends StatelessWidget {
  final String name;

  const ChildItem(this.name, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(name));
  }
}
