import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  Map<String, String> _preferences = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    setState(() {
      _preferences = {for (var key in keys) key: prefs.get(key).toString()};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: const Text('About OpenWRT-Flutter'),
      ),
      body: ListView.builder(
        itemCount: _preferences.length,
        itemBuilder: (context, index) {
          final key = _preferences.keys.elementAt(index);
          final value = _preferences[key].toString();

          return ListTile(
            leading: const Icon(Icons.devices),
            title: Text(key),
            subtitle: Text(value),
            trailing: const Icon(Icons.more_vert),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(key),
                    content: Text(value),
                    actions: <Widget>[
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Row(children: [
                            Icon(Icons.close),
                            Text('Close'),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                prefs.remove(key);
                                _loadPreferences();
                                Navigator.of(context).pop();
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final controller =
                                    TextEditingController(text: value);
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Edit $key'),
                                      content: TextField(
                                        controller: controller,
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Row(children: [
                                            Icon(Icons.close),
                                            Text('Close'),
                                          ]),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            prefs.setString(
                                                key, controller.text);
                                            _loadPreferences();
                                            Navigator.of(context).pop();
                                          },
                                          child: Row(children: [
                                            Icon(Icons.save),
                                            Text('Save'),
                                          ]),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ])),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
