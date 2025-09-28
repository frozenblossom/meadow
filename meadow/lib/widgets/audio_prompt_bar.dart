import 'package:flutter/material.dart';

class AudioPromptBar extends StatefulWidget {
  const AudioPromptBar({super.key});

  @override
  State<AudioPromptBar> createState() => _AudioPromptBarState();
}

class _AudioPromptBarState extends State<AudioPromptBar> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Genre',
              border: OutlineInputBorder(),
            ),
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a song genre';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          TextFormField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Lyrics',
              border: OutlineInputBorder(),
            ),
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter song lyrics';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onGenerate,
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _onGenerate() {}
}
