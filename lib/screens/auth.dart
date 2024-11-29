import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final _formKey = GlobalKey<FormState>();
final serverController = TextEditingController();
final usernameController = TextEditingController();
final passwordController = TextEditingController();
void setAuth(BuildContext context, String server, String username,
    String password, String token, bool isAuthenticated) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('server', server);
  prefs.setString('username', username);
  prefs.setString('password', password);
  prefs.setString('token', token);
  prefs.setBool('isAuthenticated', isAuthenticated);
  Navigator.pushReplacementNamed(context, '/');
}

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          title: const Text('Sign in to your router'),
        ),
        body: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Server Address',
                    ),
                    controller: serverController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      if (!value.startsWith('http://') &&
                          !value.startsWith('https://')) {
                        return 'Please enter a valid URL';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Username',
                    ),
                    controller: usernameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    controller: passwordController,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        String server = serverController.text;
                        String username = usernameController.text;
                        String password = passwordController.text;
                        Future<http.Response> response = http.post(
                          Uri.parse('$server/cgi-bin/luci/rpc/auth'),
                          headers: <String, String>{
                            'Content-Type': 'application/json; charset=UTF-8',
                          },
                          body: jsonEncode({
                            'method': 'login',
                            'params': [username, password],
                          }),
                        );
                        response.then((value) {
                          if (jsonDecode(value.body)["result"] != null) {
                            setAuth(context, server, username, password,
                                jsonDecode(value.body)["result"], true);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Login successful')));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Login failed')));
                          }
                        });
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ),
              ],
            )));
  }
}
