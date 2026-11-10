import 'package:flutter/material.dart';

import '../api/api_client.dart';

/// Barebones landing page: checks connectivity with the server.
class ServerStatusPage extends StatefulWidget {
  const ServerStatusPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<ServerStatusPage> createState() => _ServerStatusPageState();
}

class _ServerStatusPageState extends State<ServerStatusPage> {
  late Future<Map<String, dynamic>> _root;

  @override
  void initState() {
    super.initState();
    _root = widget.api.getRoot();
  }

  void _retry() => setState(() => _root = widget.api.getRoot());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Hub')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _root,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CircularProgressIndicator();
              }
              final connected = snapshot.hasData;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    connected ? Icons.cloud_done : Icons.cloud_off,
                    size: 64,
                    color: connected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(connected ? 'Connected' : 'Not connected'),
                  const SizedBox(height: 8),
                  Text(
                    connected ? '${snapshot.data}' : '${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text('${widget.api.baseUri}'),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _retry, child: const Text('Retry')),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
