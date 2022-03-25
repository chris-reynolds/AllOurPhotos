import 'package:flutter/material.dart';
import '../shared/aopClasses.dart';
import '../dart_common/Logger.dart' as Log;
import '../dart_common/DateUtil.dart';
import 'scSimpleDlg.dart';

class AlbumList extends StatefulWidget {
  AlbumList({Key key}) : super(key: key);

  @override
  _AlbumListState createState() => new _AlbumListState();
}

class _AlbumListState extends State<AlbumList> {
  Widget appBarTitle = new Text(
    "Search Albums",
    style: new TextStyle(color: Colors.white),
  );
  Icon actionIcon = new Icon(
    Icons.search,
    color: Colors.white,
  );
  final key = new GlobalKey<ScaffoldState>();
  final TextEditingController _searchQuery = new TextEditingController();
  var _scrollController = ScrollController();
  List<AopAlbum> _list = [];
  bool _isSearching;
  String _searchText = "";

  _AlbumListState() {
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
    refreshList();
  }

  void refreshList() {
    AopAlbum.all().then((newList) {
      setState(() {
        _list = newList;
        //_scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        Log.message('${_list.length} albums loaded');
      });
    });
  } // of refreshList

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: key,
      appBar: buildBar(context),
      body: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(8.0),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _isSearching ? _buildAlbumList() : _buildList(),
          ),
        ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add), onPressed: () => handleAddAlbum(context)),
    );
  }

  List<ChildItem> _buildList() {
    return _list.map((album) => new ChildItem(album)).toList();
  }

  List<ChildItem> _buildAlbumList() {
    if (_searchText.isEmpty) {
      return _list.map((album) => new ChildItem(album)).toList();
    } else {
      List<AopAlbum> _searchList = List();
      for (int i = 0; i < _list.length; i++) {
        String name = _list.elementAt(i).name;
        if (name.toLowerCase().contains(_searchText.toLowerCase())) {
          _searchList.add(_list.elementAt(i));
        }
      }
      return _searchList.map((contact) => new ChildItem(contact)).toList();
    }
  }

  Widget buildBar(BuildContext context) {
    return new AppBar(centerTitle: true, title: appBarTitle, actions: <Widget>[
      new IconButton(
        icon: actionIcon,
        onPressed: () {
          setState(() {
            if (this.actionIcon.icon == Icons.search) {
              this.actionIcon = new Icon(
                Icons.close,
                color: Colors.white,
              );
              this.appBarTitle = new TextField(
                controller: _searchQuery,
                style: new TextStyle(
                  color: Colors.white,
                ),
                decoration: new InputDecoration(
                    prefixIcon: new Icon(Icons.search, color: Colors.white),
                    hintText: "Search...",
                    hintStyle: new TextStyle(color: Colors.white)),
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
      this.actionIcon = new Icon(
        Icons.search,
        color: Colors.white,
      );
      this.appBarTitle = new Text(
        "Search Albums",
        style: new TextStyle(color: Colors.white),
      );
      _isSearching = false;
      _searchQuery.clear();
    });
  }

  void handleAddAlbum(BuildContext context) async {
    String name = '${formatDate(DateTime.now(), format: 'yyyy')} Unknown';
    String errorMessage = '';
    bool done = false;
    while (!done) {
      name = await showDialog(
          context: context,
          builder: (BuildContext context) => DgSimple('Album name',name, errorMessage: errorMessage));
      if (name == null  || name == EXIT_CODE) return;
      Log.message('new name is: $name');
      AopAlbum newAlbum = AopAlbum();
      newAlbum.name = name;
      await newAlbum.validate();

      if (newAlbum.isValid) {
        try {
          await newAlbum.save();
          refreshList();
          Navigator.pushNamed(context, 'AlbumDetail', arguments: newAlbum);
          done = true;
        } catch (ex) {
          errorMessage = ex.message;
        }
      } else
        errorMessage = newAlbum.lastErrors.join('\n');
    } // of done loop
  } // handleAddAlbum
} // of AlbumListState

class ChildItem extends StatelessWidget {
  final AopAlbum album;

  ChildItem(this.album);

  @override
  Widget build(BuildContext context) {
    return TextButton(
    //    contentPadding: EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0),
        child: new Text(this.album.name,style:Theme.of(context).textTheme.headline5),
        onPressed: () =>
            Navigator.pushNamed(context, 'AlbumDetail', arguments: this.album));
  }
}
