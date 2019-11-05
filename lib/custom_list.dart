import 'package:flutter/material.dart';

class CustomList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
        // Add the app bar and list of items as slivers in the next steps.
        slivers: <Widget>[
          SliverAppBar(
            title: Text('Floating app bar'),
            floating: false,
            // Display a placeholder widget to visualize the shrinking size.
            flexibleSpace: Column(
              children: <Widget>[
                Text('xxx'),
                Text('xxx'),
                Text('xxx'),
                Text('xxx'),
                Text('xxx'),
                Text('xxx'),
                Text('xxx'),
              ],
            ),
            // Make the initial height of the SliverAppBar larger than normal.
            expandedHeight: 100,
            centerTitle: true,
            primary: true,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Text('$index'),
              childCount: 1000,
            ),
          ),
        ]);
  }
}
