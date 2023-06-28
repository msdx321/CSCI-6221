import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiUrlController = TextEditingController();
  String dropdownValue = 'gpt-3.5-turbo';
  bool _isHidden = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _toggleVisibility() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKeyController.text = prefs.getString('apiKey') ?? '';
    _apiUrlController.text =
        prefs.getString('apiUrl') ?? 'https://api.openai.com/';
    setState(() {
      dropdownValue = prefs.getString('model') ?? 'gpt-3.5-turbo';
    });
  }

  _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiKey', _apiKeyController.text);
    await prefs.setString('apiUrl', _apiUrlController.text);
    await prefs.setString('model', dropdownValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _apiKeyController,
              obscureText: _isHidden,
              decoration: InputDecoration(
                labelText: 'API Key',
                suffix: InkWell(
                  onTap: _toggleVisibility,
                  child: Icon(
                    _isHidden ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: TextField(
                controller: _apiUrlController,
                decoration: const InputDecoration(
                  labelText: 'API URL',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: DropdownButton<String>(
                value: dropdownValue,
                icon: const Icon(Icons.arrow_downward),
                iconSize: 24,
                elevation: 16,
                style: const TextStyle(color: Colors.black),
                underline: Container(
                  height: 2,
                  color: Colors.blueAccent,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    dropdownValue = newValue!;
                  });
                },
                items: <String>['gpt-3.5-turbo', 'gpt-3.5-turbo-16k', 'gpt-4']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
