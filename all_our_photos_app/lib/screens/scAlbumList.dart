import 'package:flutter/material.dart';
import '../shared/aopClasses.dart';
import '../dart_common/Logger.dart' as Log;
import '../dart_common/DateUtil.dart';
import 'scSimpleDlg.dart';

class AlbumList extends StatefulWidget {
  const AlbumList({Key key}) : super(key: key);

  @override
  _AlbumListState createState() => _AlbumListState();
}

class _AlbumListState extends State<AlbumList> {
  Widget appBarTitle = Text(
    "Search Albums",
    style: TextStyle(color: Colors.white),
  );
  Icon actionIcon = Icon(
    Icons.search,
    color: Colors.white,
  );
  final key = GlobalKey<ScaffoldState>();
  final TextEditingController _searchQuery = TextEditingController();
  final _scrollController = ScrollController();
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
    refreshList().then((x){});
  }

  Future<void> refreshList() async {
    Log.message('refresh list');
    var newList = await AopAlbum.all();
        newList.sort((AopAlbum a,AopAlbum b) => b.name.compareTo(a.name));
        _list = newList;
        //_scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        Log.message('${_list.length} albums loaded');
      setState((){});
  } // of refreshList

  @override
  Widget build(BuildContext context) {
    Log.message('build');
    return Scaffold(
      key: key,
      appBar: buildBar(context),
      body: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _isSearching ? _buildAlbumList() : _buildList(),
            ),
          ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add), onPressed: () => handleAddAlbum(context)),
    );
  }

  List<ChildItem> _buildList() {
    Log.message('buildlist() from _list');
    return _list.map((album) => ChildItem(album,this)).toList();
  }

  List<ChildItem> _buildAlbumList() {
    Log.message('buildAlbumlist() from _list');
    if (_searchText.isEmpty) {
      return _list.map((album) => ChildItem(album,this)).toList();
    } else {
      List<AopAlbum> _searchList = [];
      for (int i = 0; i < _list.length; i++) {
        String name = _list.elementAt(i).name;
        if (name.toLowerCase().contains(_searchText.toLowerCase())) {
          _searchList.add(_list.elementAt(i));
        }
      }
      return _searchList.map((contact) => ChildItem(contact,this)).toList();
    }
  }

  Widget buildBar(BuildContext context) {
    return AppBar(centerTitle: true, title: appBarTitle, actions: <Widget>[
     IconButton(
        icon: actionIcon,
        onPressed: () {
          setState(() {
            if (actionIcon.icon == Icons.search) {
              actionIcon =Icon(
                Icons.close,
                color: Colors.white,
              );
              appBarTitle =TextField(
                controller: _searchQuery,
                style:TextStyle(
                  color: Colors.white,
                ),
                decoration:InputDecoration(
                    prefixIcon:Icon(Icons.search, color: Colors.white),
                    hintText: "Search...",
                    hintStyle:TextStyle(color: Colors.white)),
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
      actionIcon =Icon(
        Icons.search,
        color: Colors.white,
      );
      appBarTitle =Text(
        "Search Albums",
        style:TextStyle(color: Colors.white),
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
          //await refreshList();
          Navigator.pushNamed(context, 'AlbumDetail', arguments: newAlbum).then((value) async {
            Log.message('popping at list add');
            await this.refreshList();
          });
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
  final _AlbumListState parent;
  const ChildItem(this.album,this.parent,{Key key}):super(key:key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
            //padding: EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0),
            child:Text(album.name,style:Theme.of(context).textTheme.headline6),
            onPressed: () =>
                Navigator.pushNamed(context, 'AlbumDetail', arguments: album).then((value)  {
                  Log.message('popping at list select');
                  parent.refreshList();
                })),
      ],
    );
  }
}
