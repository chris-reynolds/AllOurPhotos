import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import 'package:aopmodel/aop_classes.dart';
import '../flutter_common/WidgetSupport.dart';
import 'scSimpleDlg.dart';
import 'package:provider/provider.dart';
import '../providers/albumProvider.dart';

class AlbumList extends StatefulWidget {
  const AlbumList({super.key});

  @override
  AlbumListState createState() => AlbumListState();
}

class AlbumListState extends State<AlbumList> {
  final key = GlobalKey<ScaffoldState>();
  final TextEditingController _searchQuery = TextEditingController();
  final _scrollController = ScrollController();
  List<AopAlbum> _list = [];
  late bool _isSearching;
  bool loading = true;
  String _searchText = "";

  AlbumListState() {
    _searchQuery.addListener(() {
      setState(() {
        _searchText = _searchQuery.text;
      });
    });
  }

  Future<void> buildAlbumList() async {
    loading = true;
    _list = await AopAlbum.all();
    _list.sort((AopAlbum a, AopAlbum b) => -a.name.compareTo(b.name));
    loading = false;
    setState(() {});
  } // of buildAlbumList

  @override
  void initState() {
    super.initState();
    _isSearching = false;
    buildAlbumList();
  } // of initState

  void toggleSearching() => setState(() {
        _isSearching = !_isSearching;
      });

  @override
  Widget build(BuildContext context) {
    if (loading)
      return Center(
        child: CircularProgressIndicator(),
      );
    else
      return albumListWidget(context, _list);
  }

  Widget albumListWidget(BuildContext context, List<AopAlbum> stuff) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        buildSearchBar(context),
        ...stuff.where(albumSelected).map((album) => buildAlbumLine(album)),
      ]),
    );
  }

  showAlbum(AopAlbum album) {
    Provider.of<AlbumProvider>(context, listen: false).setAlbum(album);
    Navigator.pushNamed(context, 'AlbumDetail').then((value) {
      log.message('popping at show album');
      buildAlbumList();
    });
  }

  Widget buildAlbumLine(AopAlbum album) {
    return Row(
      children: [
        TextButton(
            child:
                Text(album.name, style: Theme.of(context).textTheme.titleLarge),
            onPressed: () => showAlbum(album)),
      ],
    );
  } // of buildAlbumLine

  Widget buildSearchBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
            flex: 3,
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
            )),
        Spacer(),
        FloatingActionButton.extended(
          onPressed: () {
            handleAddAlbum(context);
          },
          label: const Text("New Album"),
          icon: const Icon(Icons.add),
        )
      ],
    );
  } // of buildSearchBar

  void handleAddAlbum(BuildContext context) async {
    String? name = '${formatDate(DateTime.now(), format: 'yyyy')} Unknown';
    String errorMessage = '';
    bool done = false;
    while (!done) {
      name = await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) =>
              DgSimple('Album name', name, errorMessage: errorMessage));
      if (name == EXIT_CODE || name == null) return;
      log.message('new name is: $name');
      AopAlbum newAlbum = AopAlbum(data: {});
      newAlbum.name = name;
      await newAlbum.validate();

      if (newAlbum.isValid) {
        try {
          await newAlbum.save();
          _list.add(newAlbum);
          showAlbum(newAlbum);
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
  const ChildItem(this.album, this.parent, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          child:
              Text(album.name, style: Theme.of(context).textTheme.titleLarge),
          onPressed: () => parent.showAlbum(album),
          // Navigator.pushNamed(context, 'AlbumDetail', arguments: album)
          //     .then((value) {
          //   log.message('popping at list selectttttttttttttt 2');
          // })
        ),
      ],
    );
  }
}

void handleMultiRemoveFromAlbum(BuildContext context, AopAlbum argAlbum,
    List<AopSnap> selectedSnaps) async {
  try {
    bool deleteAlbum = false;
    String message = '';
    if (selectedSnaps.isEmpty) return; // nothing to delete
    if ((await argAlbum.albumItems).length == selectedSnaps.length) {
      if ((await confirmYesNo(context, 'Delete this album',
          description:
              'All photos for this album have been\n selected for deletion'))!)
        deleteAlbum = true;
    }
    int count = await argAlbum.removeSnaps(selectedSnaps);
    message = "$count photos removed\n";
    if (deleteAlbum) {
      await argAlbum.delete();
      message += 'Album deleted';
      log.message('popping from grid after delete album');
      await showMessage(context, message);
      Navigator.pop(context, true);
    } else {
      await showMessage(context, message);
    }
  } catch (ex) {
    showMessage(context, 'Error: $ex');
  }
} // of handleMultiRemoveFromAlbum*/

// TODO: Try and get album create in correct location
// Future<AopAlbum?> showAlbumCreate(BuildContext context) async {
//   var nameController = TextEditingController(text: 'fred');
//   await showDialog(
//       context: context,
//       builder: ((context) {
//         return AlertDialog(
//           backgroundColor: Color.fromARGB(255, 183, 195, 207),
//           title: Text('Enter new album name'),
//           content: TextField(controller: nameController),
//           actions: [
//             ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   log.message('pressed create');
//                   return;
//                 },
//                 child: Text('Create')),
//             ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   log.message('pressed cancel');
//                   return;
//                 },
//                 child: Text('Cancel')),
//           ],
//         );
//       })); // of showDialog
//   log.message('done show dialog');
//   return null;
// } // of showAlbumCreate
