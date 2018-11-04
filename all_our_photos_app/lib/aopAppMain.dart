import 'package:flutter/material.dart';
import 'package:all_our_photos_app/screens/scRecentPics.dart';
import 'package:all_our_photos_app/screens/scAlbums.dart';
import 'package:all_our_photos_app/screens/scHistory.dart';
import 'package:all_our_photos_app/screens/scTesting.dart';
import 'package:all_our_photos_app/srvCatalogueLoader.dart';
import 'package:all_our_photos_app/appNavigator.dart';
import 'package:all_our_photos_app/widgets/wdgPhotoGrid.dart';


void main() {
  application = new MaterialApp(
    title: 'All Our Photos',
    debugShowCheckedModeBanner: true,
    theme: new ThemeData(
      primaryColor: const Color(0xFF02BB9F),
      primaryColorDark: const Color(0xFF167F67),
      accentColor: const Color(0xFFFFAD32),
      textTheme: TextTheme(
//          body1: TextStyle(fontSize: 25.0, color: Colors.red),
          body2: TextStyle(fontSize: 25.0, color: Colors.red)
      ),
    ),
    home: new DashboardScreen(title: 'All Our Photos v0.2'),
    routes: <String, WidgetBuilder> {
//      '/a': (BuildContext context) => GridListDemo(),
      '/b': (BuildContext context) => Albums('albums route b'),
      '/c': (BuildContext context) => Albums('albums route c'),
    },
  );
  runApp(application);
} // of main

/*class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'All Our Photos',
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
        primaryColor: const Color(0xFF02BB9F),
        primaryColorDark: const Color(0xFF167F67),
        accentColor: const Color(0xFFFFAD32),
      ),
      home: new DashboardScreen(title: 'All Our Photos3'),
    );
  }
}
*/

class DashboardScreen extends StatefulWidget {
  DashboardScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _DashboardScreenState createState() => new _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  //inside _DashboardScreenState class

  PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = new PageController();
    loadTop().then((loadResult) {
      print(loadResult);
      initTimer();
      _pageController.jumpToPage(2);
    }); // TODO show bad result
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  void navigationTapped(int page) {
    // Animating to the page.
    // You can use whatever duration and curve you like
    _pageController.jumpToPage(page);
//    _pageController.animateToPage(page,
//        duration: const Duration(milliseconds: 100), curve: Curves.ease);
  }

  void onPageChanged(int page) {
    setState(() {
      this._page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(
          widget.title,
          style: new TextStyle(color: const Color(0xFFFFFFFF)),
        ),
      ),
      body: new PageView(
        children: [
          new Home("Recent Pics"),
          new Albums("Albums"),
          new HistoryScreen("History"),
          new Testing("Testing"),
        ],
        onPageChanged: onPageChanged,
        controller: _pageController,
      ),
      bottomNavigationBar: new Theme(
        data: Theme.of(context).copyWith(
          // sets the background color of the `BottomNavigationBar`
          canvasColor: const Color(0xFF167F67),
        ), // sets the inactive color of the `BottomNavigationBar`
        child: new BottomNavigationBar(
          items: [
            new BottomNavigationBarItem(
                icon: new Icon(
                  Icons.camera_roll,
   //               color: const Color(0xFFFFFFFF),
                ),
                title: new Text(
                  "Recent Pics",
                  style: new TextStyle(
   //                 color: const Color(0xFFFFFFFF),
                  ),
                )),
            new BottomNavigationBarItem(
                icon: new Icon(
                  Icons.collections,
  //                color: const Color(0xFFFFFFFF),
                ),
                title: new Text(
                  "Albums",
                  style: new TextStyle(
   //                 color: const Color(0xFFFFFFFF),
                  ),
                )),
            new BottomNavigationBarItem(
                icon: new Icon(
                  Icons.history,
   //               color: const Color(0xFFFFFFFF),
                ),
                title: new Text(
                  "History",
                  style: new TextStyle(
   //                 color: const Color(0xFFFFFFFF),
                  ),
                )),
            new BottomNavigationBarItem(
                icon: new Icon(
                  Icons.text_fields,
  //                color: const Color(0xFFFFFFFF),
                ),
                title: new Text(
                  "Testing",
                  style: new TextStyle(
  //                  color: const Color(0xFFFFFFFF),
                  ),
                ))
          ],
          onTap: navigationTapped,
          currentIndex: _page,
        ),
      ),
    );
  }
}
