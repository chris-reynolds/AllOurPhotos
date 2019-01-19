import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:all_our_photos_app/GooglePhotoApi.dart';

class Categories {
  String category;
  String categoryDesc;
  int id;
  String autocompleteterm;
  String desc;

  Categories({
    this.category,
    this.categoryDesc,
    this.id,
    this.autocompleteterm,
    this.desc
  });

  factory Categories.fromJson(Map<String, dynamic> parsedJson) {
    return Categories(
        category:parsedJson['serviceCategory'] as String,
        categoryDesc: parsedJson['serviceCategoryDesc'] as String,
        id: parsedJson['serviceCategoryId'],
        autocompleteterm: parsedJson['autocompleteTerm'] as String,
        desc: parsedJson['description'] as String
    );
  }
}

class GoogleAlbumsWidget extends StatefulWidget {
  @override
  _GoogleAlbumsState createState() => _GoogleAlbumsState();
}


class _GoogleAlbumsState extends State<GoogleAlbumsWidget> {
  List data;
  String stuff;


  @override
  void initState() {
    super.initState();
    PhotosLibraryClient.listAlbums();
  }

  @override
  Widget build(BuildContext context) {
//    Future<String> stuff = DefaultAssetBundle
//        .of(context)
//        .loadString('assets/services.json');
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Load local JSON file"),
        ),
        body: new Container(
            child: new Center(
              // Use future builder and DefaultAssetBundle to load the local JSON file
                child: new FutureBuilder(
                    future: DefaultAssetBundle
                        .of(context)
                        .loadString('assets/services.json'),
                    builder: (context, snapshot) {
                      // Decode the JSON
                      Map data = json.decode(snapshot.data
                          .toString());
                      final List<Categories> items = (data['data'] as List).map((i) => new Categories.fromJson(i)).toList();
                      for (final item in items) {
                        print(item.category);

                        return new ListView.builder(

                          itemBuilder: (BuildContext context, int index) {
                            return new Card(
                              child: new Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  new Text('Service Category: ' +
                                      items[index].category),
                                  new Text('Auto complete term: ' + items[index].autocompleteterm),
                                  new Text('Desc: ' + items[index].desc),
                                  new Text('Category desc: ' + items[index].categoryDesc)
                                ],
                              ),
                            );
                          },
                        );
                      }
                    }

                )
            )
        )
    );
  }
}
