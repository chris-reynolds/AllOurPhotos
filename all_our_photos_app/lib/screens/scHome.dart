import 'package:flutter/material.dart';
import 'scAlbumList.dart';
import 'scTesting.dart';
import 'scDBFix.dart';
import '../widgets/wdgYearGrid.dart';
import '../flutter_common/WidgetSupport.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.title, this.logoutFn});
  final Function? logoutFn;
  final String? title;

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  PageController? _pageController;
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
    _pageController!.dispose();
  }

  void navigationTapped(int page) {
    _pageController!.jumpToPage(page);
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    UIPreferences.setContext(context);
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
            child: Text(widget.title ?? '',
                style: Theme.of(context).tabBarTheme.labelStyle),
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
                if ((await confirmYesNo(
                    context, 'Do really want to log out?'))!) {
                  widget.logoutFn!();
                }
              },
            ),
          if (_debugMode) navIconButton(context, 'testlog', Icons.list),
          if (_debugMode)
            navIconButton(context, 'Db Fixs', Icons.local_hospital),
        ],
      ),
      body: PageView(
        onPageChanged: onPageChanged,
        controller: _pageController,
        children: const [
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
        ],
        onTap: navigationTapped,
        currentIndex: _page,
      ),
    );
  }
}
