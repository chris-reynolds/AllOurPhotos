import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import 'package:aopmodel/aopClasses.dart';
import 'scSimpleDlg.dart';

class AlbumList extends StatefulWidget {
  const AlbumList({Key? key}) : super(key: key);

  @override
  AlbumListState createState() => AlbumListState();
}

class AlbumListState extends State<AlbumList> {
  Widget appBarTitle = Text(
    "Search Albums",
    style: TextStyle(color: Colors.yellow),
  );
  Icon actionIcon = Icon(
    Icons.search,
    color: Colors.white,
  );
  final key = GlobalKey<ScaffoldState>();
  final TextEditingController _searchQuery = TextEditingController();
  final _scrollController = ScrollController();
  List<AopAlbum> _list = [];
  late bool _isSearching;
  String _searchText = "";

  AlbumListState() {
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
    refreshList().then((x) {});
  }

  Future<void> refreshList() async {
    log.message('refresh list');
    var newList = await AopAlbum.all();
    newList.sort((AopAlbum a, AopAlbum b) => b.name.compareTo(a.name));
    _list = newList;
    //_scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    log.message('${_list.length} albums loaded');
    setState(() {});
  } // of refreshList

  @override
  Widget build(BuildContext context) {
    log.message('build');
    return Scaffold(
      key: key,
      appBar: buildBar(context) as PreferredSizeWidget?,
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
    log.message('buildlist() from _list');
    return _list.map((album) => ChildItem(album, this)).toList();
  }

  List<ChildItem> _buildAlbumList() {
    log.message('buildAlbumlist() from _list');
    if (_searchText.isEmpty) {
      return _list.map((album) => ChildItem(album, this)).toList();
    } else {
      List<AopAlbum> searchList = [];
      for (int i = 0; i < _list.length; i++) {
        String name = _list.elementAt(i).name;
        if (name.toLowerCase().contains(_searchText.toLowerCase())) {
          searchList.add(_list.elementAt(i));
        }
      }
      return searchList.map((contact) => ChildItem(contact, this)).toList();
    }
  }

  Widget buildBar(BuildContext context) {
    return AppBar(centerTitle: true, title: appBarTitle, actions: <Widget>[
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
        "Search Albums",
        style: TextStyle(color: Colors.white),
      );
      _isSearching = false;
      _searchQuery.clear();
    });
  }

  void handleAddAlbum(BuildContext context) async {
    String? name = '${formatDate(DateTime.now(), format: 'yyyy')} Unknown';
    String? errorMessage = '';
    bool done = false;
    while (!done) {
      name = await showDialog(
          context: context,
          builder: (BuildContext context) =>
              DgSimple('Album name', name, errorMessage: errorMessage));
      if (name == EXIT_CODE) return;
      log.message('new name is: $name');
      AopAlbum newAlbum = AopAlbum(data: {});
      newAlbum.name = name ?? 'Undefined';
      await newAlbum.validate();

      if (newAlbum.isValid) {
        try {
          await newAlbum.save();
          //await refreshList();
          Navigator.pushNamed(context, 'AlbumDetail', arguments: newAlbum)
              .then((value) async {
            log.message('popping at list add');
            await refreshList();
          });
          done = true;
        } catch (ex) {
          errorMessage = '$ex';
        }
      } else
        errorMessage = newAlbum.lastErrors.join('\n');
    } // of done loop
  } // handleAddAlbum
} // of AlbumListState

class ChildItem extends StatelessWidget {
  final AopAlbum album;
  final AlbumListState parent;
  const ChildItem(this.album, this.parent, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
            //padding: EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0),
            child:
                Text(album.name, style: Theme.of(context).textTheme.titleLarge),
            onPressed: () =>
                Navigator.pushNamed(context, 'AlbumDetail', arguments: album)
                    .then((value) {
                  log.message('popping at list select');
                  parent.refreshList();
                })),
      ],
    );
  }
}
