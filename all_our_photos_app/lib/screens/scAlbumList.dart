import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import 'package:aopmodel/aop_classes.dart';
import 'scSimpleDlg.dart';

class AlbumList extends StatefulWidget {
  const AlbumList({Key? key}) : super(key: key);

  @override
  AlbumListState createState() => AlbumListState();
}

class AlbumListState extends State<AlbumList> {
  final key = GlobalKey<ScaffoldState>();
  final TextEditingController _searchQuery = TextEditingController();
  final _scrollController = ScrollController();
  late Future<List<AopAlbum>> _list;
  late bool _isSearching;
  String _searchText = "";

  AlbumListState() {
    _searchQuery.addListener(() {
      setState(() {
        _searchText = _searchQuery.text;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _isSearching = false;
    _list = AopAlbum.all();
    ;
    // noisyLoadList();
  }

  void toggleSearching() => setState(() {
        _isSearching = !_isSearching;
      });

  Future<List<AopAlbum>> noisyLoadList() async {
    log.message('noisy list');
    var newList = await AopAlbum.all();
    newList.sort((AopAlbum a, AopAlbum b) => b.name.compareTo(a.name));
    log.message('${newList.length} albums loaded');
    return newList;
  } // of refreshList

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      builder: (ctx, snapshot) {
        // Checking if future is resolved or not
        if (snapshot.connectionState == ConnectionState.done) {
          // If we got an error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${snapshot.error} occurred',
                style: TextStyle(fontSize: 18),
              ),
            );

            // if we got our data
          } else if (snapshot.hasData) {
            return albumListWidget(context, snapshot.data as List<AopAlbum>);
          }
        }

        // Displaying LoadingSpinner to indicate waiting state
        return Center(
          child: CircularProgressIndicator(),
        );
      },
      // Future that needs to be resolved in order to display
      future: _list,
    );
  }

  Widget albumListWidget(BuildContext context, List<AopAlbum> stuff) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        buildSearchBar(context),
        ...stuff
            .where(albumSelected)
            .map((album) => ChildItem(album, this))
            .toList(),
      ]),
    );
  }

  Widget buildSearchBar(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: TextField(
        controller: _searchQuery,
        //      style: TextStyle(fontSize: 25),
        decoration: InputDecoration(
            labelText: 'Enter your search text here',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search, color: Colors.white),
            contentPadding: EdgeInsets.all(10),
            hintText: "Search...",
            hintStyle: TextStyle(color: Colors.white)),
      ),
//        IconButton(icon: Icon(Icons.close), onPressed: toggleSearching)
//      ]
    );
  } // of buildSearchBar

  void handleAddAlbum(BuildContext context) async {
    String name = '${formatDate(DateTime.now(), format: 'yyyy')} Unknown';
    String errorMessage = '';
    bool done = false;
    while (!done) {
      name = await showDialog(
          context: context,
          builder: (BuildContext context) =>
              DgSimple('Album name', name, errorMessage: errorMessage));
      if (name == EXIT_CODE) return;
      log.message('new name is: $name');
      AopAlbum newAlbum = AopAlbum(data: {});
      newAlbum.name = name;
      await newAlbum.validate();

      if (newAlbum.isValid) {
        try {
          await newAlbum.save();
          (await _list).add(newAlbum);
          Navigator.pushNamed(context, 'AlbumDetail', arguments: newAlbum)
              .then((value) async {
            log.message('popping at album list add');
          });
          done = true;
        } catch (ex) {
          errorMessage = '$ex';
        }
      } else
        errorMessage = newAlbum.lastErrors.join('\n');
    } // of done loop
  } // handleAddAlbum

  bool albumSelected(AopAlbum album) =>
      _searchText.isEmpty ||
      album.name.toLowerCase().contains(_searchText.toLowerCase());
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
                })),
      ],
    );
  }
}
