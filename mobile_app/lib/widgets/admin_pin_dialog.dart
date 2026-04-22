import 'package:flutter/material.dart';

class AdminPinDialog extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AdminPinDialog({super.key, required this.onAuthenticated});

  @override
  State<AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<AdminPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = "1234";

  void _verifyPin() {
    if (_pinController.text == _correctPin) {
      Navigator.pop(context);
      widget.onAuthenticated();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect PIN! ❌"), backgroundColor: Colors.red),
      );
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Admin Access"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Please enter 4-digit PIN"),
          const SizedBox(height: 20),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 20),
            decoration: const InputDecoration(counterText: "", border: OutlineInputBorder()),
            onChanged: (val) {
              if (val.length == 4) _verifyPin();
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
      ],
    );
  }
}
