import 'package:flutter/material.dart';
import 'package:flutter_map_offline_poc/src/features/sharing_fmtc/view/sharing_reciever_screen.dart';
import 'package:flutter_map_offline_poc/src/features/sharing_fmtc/view/sharing_sender_screen.dart';
// Import the ReceiverScreen

class CommonSharingScreen extends StatelessWidget {
  const CommonSharingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Common Sharing Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SenderScreen()),
                );
              },
              child: const Text('Send Files'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReceiverScreen()),
                );
              },
              child: const Text('Receive Files'),
            ),
          ],
        ),
      ),
    );
  }
}
