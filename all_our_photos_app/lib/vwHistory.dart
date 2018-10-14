import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'wdgHistoryScrollingList.dart';
import 'wdgPhotoGrid.dart';
import 'wdgMonthGrid.dart';

class HistoryScreen extends StatefulWidget {
  HistoryScreen(this.title) : super();

  final String title;

  @override
  _HistoryScreenState createState() => new _HistoryScreenState(this.title);
}

class _HistoryScreenState extends State<HistoryScreen> {
  _HistoryScreenState(this.listType);
  final String listType;
  PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = new PageController();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  void navigationTapped(int page) {
    // Animating to the page.
    // You can use whatever duration and curve you like
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  void onPageChanged(int page) {
    setState(() {
      this._page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new PageView(
   //   body: PageView(
        children: [
//          new GridListDemo(),
          new MonthGrid(),
          new HistoryScrollingList("Albums"),
          new HistoryScrollingList("History"),
          new HistoryScrollingList("Testing"),
        ],
        onPageChanged: onPageChanged,
        controller: _pageController,
//      ),
    );
  }
}
