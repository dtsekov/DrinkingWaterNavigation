
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class FountainListScreen extends StatefulWidget {
  @override
  _FountainListScreenState createState() => _FountainListScreenState();
}

class _FountainListScreenState extends State<FountainListScreen> {
  late DatabaseReference _ref;

  static const int pageSize = 50;
  List<MapEntry<String, dynamic>> _items = [];
  String? _lastKey;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _initialized = false;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _scrollCtrl.addListener(_onScroll);
  }

  Future<void> _initializeDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final dbUrl = prefs.getString('db_url');

    if (dbUrl == null) {
      // Handle missing DB URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database URL not configured.')),
      );
      return;
    }

    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: dbUrl,
    );

    _ref = database.ref().child('fountains');

    setState(() {
      _initialized = true;
    });

    _loadNextPage();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (!_initialized || _isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    Query query = _ref.orderByKey().limitToFirst(pageSize);
    if (_lastKey != null) {
      query = _ref.orderByKey()
          .startAt(_lastKey)
          .limitToFirst(pageSize + 1);
    }

    final snapshot = await query.get();
    final data = snapshot.value as Map<dynamic, dynamic>?;
    if (data != null) {
      final entries = data.entries
          .map((e) => MapEntry(e.key as String, e.value))
          .toList();
      final pageItems = (_lastKey == null) ? entries : entries.sublist(1);

      setState(() {
        _items.addAll(pageItems);
        _lastKey = entries.last.key;
        if (pageItems.length < pageSize) {
          _hasMore = false;
        }
      });
    } else {
      _hasMore = false;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteFountain(String key) async {
    await _ref.child(key).remove();
    setState(() {
      _items.removeWhere((e) => e.key == key);
    });
  }

  Future<void> _updateFountain(String key, double lat, double lon) async {
    await _ref.child(key).update({
      'latitude': lat,
      'longitude': lon,
    });
    setState(() {
      final idx = _items.indexWhere((e) => e.key == key);
      if (idx != -1)
        _items[idx] = MapEntry(key, {'latitude': lat, 'longitude': lon});
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        appBar: AppBar(title: Text('Fountains')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Fountains')),
      body: ListView.builder(
        controller: _scrollCtrl,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            return Center(child: CircularProgressIndicator());
          }
          final key = _items[i].key;
          final val = _items[i].value as Map<dynamic, dynamic>;
          final lat = val['latitude'];
          final lon = val['longitude'];

          return ListTile(
            title: Text('Fountain $key'),
            subtitle: Text('Lat: $lat, Lon: $lon'),
            onTap: () => _deleteConfirm(key),
            onLongPress: () => _editDialog(key, lat, lon),
          );
        },
      ),
    );
  }

  void _deleteConfirm(String key) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Fountain?'),
        content: Text('Are you sure you want to delete fountain $key?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(onPressed: () {
            Navigator.pop(context);
            _deleteFountain(key);
          }, child: Text('Delete')),
        ],
      ),
    );
  }

  void _editDialog(String key, double lat, double lon) {
    final latCtrl = TextEditingController(text: lat.toString());
    final lonCtrl = TextEditingController(text: lon.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Fountain $key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: latCtrl, decoration: InputDecoration(labelText: 'Lat')),
            TextField(controller: lonCtrl, decoration: InputDecoration(labelText: 'Lon')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(onPressed: () {
            Navigator.pop(context);
            _updateFountain(key, double.parse(latCtrl.text), double.parse(lonCtrl.text));
          }, child: Text('Save')),
        ],
      ),
    );
  }
}
