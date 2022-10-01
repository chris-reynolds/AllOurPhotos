import 'package:flutter/material.dart';
import 'scAlbumList.dart';
import 'scTesting.dart';
import 'scDBFix.dart';
import '../widgets/wdgYearGrid.dart';
import '../flutter_common/WidgetSupport.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key key, this.title, this.logoutFn}) : super(key: key);
  final Function logoutFn;
  final String title;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //inside _HomeScreenState class

  PageController _pageController;
  int _page = 0;
  bool _debugMode = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
            child: Text(
              widget.title,
              style: TextStyle(color: const Color(0xFFFFFFFF)),
            ),
            onDoubleTap: () {
              setState(() {
                _debugMode = !_debugMode;
              });
            }),
        actions: <Widget>[
          if (_debugMode)
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () async {
                if (await confirmYesNo(context, 'Do really want to log out?')) {
                  widget.logoutFn();
                }
              },
            ),
          if (_debugMode) navIconButton(context, 'testlog', Icons.list),
          if (_debugMode) navIconButton(context, 'Db Fixs', Icons.local_hospital),
        ],
      ),
      body: PageView(
        onPageChanged: onPageChanged,
        controller: _pageController,
        children: [
//          HistoryScreen("History"),
          YearGrid(),
          AlbumList(),
          SearchList(),
          DbFixFormWidget(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
          items: [
            bottomButton('History', Icons.grid_on),
            bottomButton('Albums', Icons.collections),
//            bottomButton('Camera Roll', Icons.camera_roll),
          ],
          onTap: navigationTapped,
          currentIndex: _page,
        ),
    );
  }
}
