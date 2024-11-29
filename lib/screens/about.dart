import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: const Text('About OpenWRT Flutter'),
      ),
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Version'),
              subtitle: const Text('1.0.0'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Author'),
              subtitle: const Text('@kattschan'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('License'),
              subtitle: const Text('GNU GPLv3'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('We\'re open source on GitHub!'),
              onTap: () {
                launchUrl(
                    Uri.parse("https://github.com/kattschan/openwrt_flutter"));
              },
            ),
          ],
        ).toList(),
      ),
    );
  }
}
