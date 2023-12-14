import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import 'package:aopmodel/aop_classes.dart';

class SearchList extends StatefulWidget {
  const SearchList({Key? key}) : super(key: key);

  @override
  SearchListState createState() => SearchListState();
}

class SearchListState extends State<SearchList> {
  Widget appBarTitle = Text(
    "Search Sample",
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

  SearchListState() {
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
      appBar: buildBar(context) as PreferredSizeWidget?,
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
      List<String> searchList = [];
      for (int i = 0; i < _list.length; i++) {
        String name = _list.elementAt(i);
        if (name.toLowerCase().contains(_searchText.toLowerCase())) {
          searchList.add(name);
        }
      }
      return searchList.map((contact) => ChildItem(contact)).toList();
    }
  }

  Widget buildBar(BuildContext context) {
    return AppBar(centerTitle: true, title: appBarTitle, actions: <Widget>[
      IconButton(
        icon: Icon(Icons.delete),
        iconSize: 30,
        onPressed: () {
          log.clear();
          setState(() {
            _list = [];
          });
        },
      ),
      IconButton(
        icon: Icon(Icons.map),
        iconSize: 30,
        onPressed: handleLocationCompletion,
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
                    hintText: "Search...",
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

  void handleLocationCompletion() async {
    List<AopSnap> snapList =
        await snapProvider.getSome('location is null and latitude is not null');
    GeocodingSession geo = GeocodingSession();
    int sofar = 0;
    // todo populate the cache
    dynamic r = await AopSnap.existingLocations;
    for (dynamic row in r.rows) geo.setLocation(row[1], row[2], row[0]);
    log.message('${snapList.length} snaps to code');
    for (AopSnap snap in snapList) {
      String location =
          await geo.getLocation(snap.longitude!, snap.latitude!) ?? '';
      if (location.length > 100)
        location = location.substring(location.length - 100);
      snap.location = location;
      await snap.save();
      if (++sofar % 20 == 0) {
        log.message('$sofar');
        setState(() {});
      }
    } // of for loop
    log.message('Locations complete');
    setState(() {});
  } // of handleLocationCompletion

  void handleLocationFix() async {
    List<AopSnap> snapList = await snapProvider
        .getSome("import_source like '%ipad%' and latitude is not null");
    GeocodingSession geo = GeocodingSession();
    // todo populate the cache
    dynamic r = await AopSnap.existingLocations;
    for (dynamic row in r.rows) geo.setLocation(row[1], row[2], row[0]);
    log.message('${snapList.length} snaps to code');
//    for (AopSnap snap in snapList) {
//      Map(String,dynamic) exifData = await
//      String location = await geo.getLocation(snap.longitude, snap.latitude);
//      if (location != null) {
//        if (location.length > 100)
//          location = location.substring(location.length - 100);
//        snap.location = location;
//        await snap.save();
//        if (++sofar % 20 == 0) {
//          log.message('$sofar');
//          setState(() {});
//        }
//      }
//    } // of for loop
    log.message('Locations complete');
    setState(() {});
  } // of handleLocationCompletion

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

  const ChildItem(this.name);

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(name));
  }
}
