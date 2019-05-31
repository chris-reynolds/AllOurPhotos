import 'package:flutter/material.dart';
import 'screens/scRecentPics.dart';
import 'screens/scAlbumList.dart';
import 'screens/scHistory.dart';
import 'screens/scTesting.dart';
// import 'screens/scDeviceCameraRoll.dart';
import 'screens/scLogin.dart';
import 'screens/scAlbumDetail.dart';
import 'screens/scAlbumAddPhoto.dart';
import 'appNavigator.dart';
import 'dart_common/Config.dart';
import 'dart_common/LoginStateMachine.dart';


void main() async {
  await loadConfig('allourphotos.config.json');
//  await DbAllOurPhotos().initConnection(config); // todo parameterise
  loginStateMachine = LoginStateMachine(config);
  await loginStateMachine.initState();
  Widget dashboardScreen = DashboardScreen(title: 'All Our Photos v0.53');
  Widget loginScreen = LoginForm(loginStateMachine);
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
    home:  (loginStateMachine.loginStatus==etLoginStatus.LoggedIn)
        ? dashboardScreen : loginScreen,
    routes: <String, WidgetBuilder> {
//      '/a': (BuildContext context) => GridListDemo(),
    'home': (context) => dashboardScreen,
      'login': (BuildContext context) => loginScreen,
      'AlbumList': (BuildContext context) => AlbumList(),
      'AlbumDetail': (BuildContext context) => AlbumDetail(),
      'AlbumItemCreate': (BuildContext context) => AlbumAddPhoto(),
    },
  );
  runApp(application);
} // of main

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
    // loadTop will callback when completed
//    loadTop(() {
//      initTimer();
//      _pageController.jumpToPage(2);
//    });
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
//          new MyHomePage(),
          new AlbumList(),
          new HistoryScreen("History"),
          new SearchList(),
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
            bottomButton('Recent Pics',Icons.camera_roll),
            bottomButton('Albums',Icons.collections),
            bottomButton('History',Icons.history),
            bottomButton('Testing',Icons.text_fields),
          ],
          onTap: navigationTapped,
          currentIndex: _page,
        ),
      ),
    );
  }
  BottomNavigationBarItem bottomButton(String keyText,IconData valueIcon)=>
      BottomNavigationBarItem(
        icon: new Icon(valueIcon),title: new Text(keyText));
}


