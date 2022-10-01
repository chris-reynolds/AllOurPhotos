import 'package:flutter/material.dart';

class HistoryScrollingList extends StatelessWidget {
  const HistoryScrollingList(this.listType);
  final String listType;
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              listType,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
    );
  }
}