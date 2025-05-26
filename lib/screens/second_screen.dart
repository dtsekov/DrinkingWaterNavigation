import 'package:flutter/material.dart';
class SecondScreen extends StatefulWidget {
  @override
  _SecondScreenState createState() => _SecondScreenState();
}
class _SecondScreenState extends State<SecondScreen> {
  @override
  void initState() {
    super.initState();
    // This method is called once when the state object is created.
    // It's a good place to initialize data that depends on the state.
    print("initState: Initial state setup.");
  }
  @override
  Widget build(BuildContext context) {
    // Similar to the build method of a StatelessWidget,
    // this method is called every time the widget needs to be rebuilt, for example, after calling setState().
    print("build: Building the user interface.");
    return Scaffold(
      appBar: AppBar(
        title: Text('Second screen'),
      ),
      body: Center(
        child: Text('Welcome to the Second Screen!'),
      ),
    );
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This method is called right after initState the first time
    // the widget is built and when any dependencies of the InheritedWidget change.
    print("didChangeDependencies: Dependencies updated.");
  }
  @override
  void didUpdateWidget(SecondScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent widget changes and has to rebuild this widget (because it needs to update the configuration),
    // this method is called with the old widget as an argument.

    print("didUpdateWidget: The widget has been updated from the parent.");
  }
  @override
  void dispose() {
    // This method is called when this state object is permanently removed.
    print("dispose: Cleaning up before the state is destroyed.");
    super.dispose();
  }
}
