import 'package:flutter/material.dart';
import '../dart_common/Logger.dart' as Log;
import '../dart_common/Geocoding.dart';
import '../shared/aopClasses.dart';

class SearchList extends StatefulWidget {
  SearchList({ Key key }) : super(key: key);

  @override
  _SearchListState createState() => new _SearchListState();

}

class _SearchListState extends State<SearchList> {
  Widget appBarTitle = new Text(
    "Search Sample", style: new TextStyle(color: Colors.white),);
  Icon actionIcon = new Icon(Icons.search, color: Colors.white,);
  final key = new GlobalKey<ScaffoldState>();
  final TextEditingController _searchQuery = new TextEditingController();
  List<String> _list;
  bool _isSearching;
  String _searchText = "";

  _SearchListState() {
    _searchQuery.addListener(() {
      if (_searchQuery.text.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchText = "";
        });
      }
      else {
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
    _list = Log.logHistory;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: key,
      appBar: buildBar(context),
      body: new ListView(
        padding: new EdgeInsets.symmetric(vertical: 8.0),
        children: _isSearching ? _buildSearchList() : _buildList(),
      ),
    );
  }

  List<ChildItem> _buildList() {
    return _list.map((contact) => new ChildItem(contact)).toList();
  }

  List<ChildItem> _buildSearchList() {
    if (_searchText.isEmpty) {
      return _list.map((contact) => new ChildItem(contact))
          .toList();
    }
    else {
      List<String> _searchList = List();
      for (int i = 0; i < _list.length; i++) {
        String name = _list.elementAt(i);
        if (name.toLowerCase().contains(_searchText.toLowerCase())) {
          _searchList.add(name);
        }
      }
      return _searchList.map((contact) => new ChildItem(contact))
          .toList();
    }
  }

  Widget buildBar(BuildContext context) {
    return new AppBar(
        centerTitle: true,
        title: appBarTitle,
        actions: <Widget>[
          new IconButton(icon: Icon(Icons.delete),
            iconSize: 30,
            onPressed: () {
            Log.logHistory = [];
              setState(() {
                _list = [];
              });
            },),
          new IconButton(icon: Icon(Icons.map),
            iconSize: 30,
            onPressed: handleLocationCompletion,),
          new IconButton(icon: actionIcon, onPressed: () {
            setState(() {
              if (this.actionIcon.icon == Icons.search) {
                this.actionIcon = new Icon(Icons.close, color: Colors.white,);
                this.appBarTitle = new TextField(
                  controller: _searchQuery,
                  style: new TextStyle(
                    color: Colors.white,

                  ),
                  decoration: new InputDecoration(
                      prefixIcon: new Icon(Icons.search, color: Colors.white),
                      hintText: "Search...",
                      hintStyle: new TextStyle(color: Colors.white)
                  ),
                );
                _handleSearchStart();
              }
              else {
                _handleSearchEnd();
              }
            });
          },),
        ]
    );
  }

  void handleLocationCompletion() async {
    List<AopSnap> snapList = await snapProvider.getSome(
        'location is null and latitude is not null');
    GeocodingSession geo = GeocodingSession();
    int sofar = 0;
    // todo populate the cache
    dynamic r = await AopSnap.existingLocations;
    for (dynamic row in r.rows)
      geo.setLocation(row[1], row[2], row[0]);
    Log.message('${snapList.length} snaps to code');
    for (AopSnap snap in snapList) {
      String location = await geo.getLocation(snap.longitude, snap.latitude);
      if (location != null) {
        if (location.length > 100)
          location = location.substring(location.length - 100);
        snap.location = location;
        await snap.save();
        if (++sofar % 20 == 0) {
          Log.message('$sofar');
          setState(() {});
        }
      }
    } // of for loop
    Log.message('Locations complete');
    setState(() {});
  } // of handleLocationCompletion

  void _handleSearchStart() {
    setState(() {
      _isSearching = true;
    });
  }

  void _handleSearchEnd() {
    setState(() {
      this.actionIcon = new Icon(Icons.search, color: Colors.white,);
      this.appBarTitle =
      new Text("Search Sample", style: new TextStyle(color: Colors.white),);
      _isSearching = false;
      _searchQuery.clear();
    });
  }

}

class ChildItem extends StatelessWidget {
  final String name;

  ChildItem(this.name);

  @override
  Widget build(BuildContext context) {
    return new ListTile(title: new Text(this.name));
  }

}




