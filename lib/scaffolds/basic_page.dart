import 'package:flutter/material.dart';
import 'package:scroll_bottom_navigation_bar/scroll_bottom_navigation_bar.dart';

class BasicPage extends StatelessWidget {
  BasicPage({Key? key}) : super(key: key);

  final controller = ScrollController();

  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: "Page 1",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: "Page 2",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Basic"),
        foregroundColor: Colors.black,
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: controller.bottomNavigationBar.tabNotifier,
        child: SizedBox(height: MediaQuery.of(context).size.height * 2),
        // child: SizedBox(
        //   height: MediaQuery.of(context).size.height * 2,
        //   child: ListView.builder(
        //     itemCount: 100,
        //     itemBuilder: (BuildContext context, int index) {
        //       return ListTile(
        //         title: Text("$index"),
        //       );
        //     },
        //   ),
        // ),
        builder: (context, pageIndex, child) => ListView(
          key: PageStorageKey(pageIndex),
          controller: controller, // Note the controller here
          // children: [child!],
          children: const [
            ListTile(title: Text("data", style: TextStyle(fontSize: 200))),
            ListTile(title: Text("data", style: TextStyle(fontSize: 200))),
            ListTile(title: Text("data", style: TextStyle(fontSize: 200))),
            ListTile(title: Text("data", style: TextStyle(fontSize: 200))),
          ],
        ),
      ),
      bottomNavigationBar: ScrollBottomNavigationBar(
        controller: controller, // Controller is also here
        items: _items,
      ),
    );
  }
}
