import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spas_web/providers/speech_provider.dart';
import '../services/loading.dart';
import '../services/player.dart';

class NoteStat extends StatefulWidget {
  final int notesLenght;
  const NoteStat({super.key, required this.notesLenght});

  @override
  _NoteStatState createState() => _NoteStatState();
}

class _NoteStatState extends State<NoteStat> {
  @override
  void dispose() {
    super.dispose();
    Audio().stopSOs();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpeechProvider>(builder: (context, speechProvider, child) {
      if (widget.notesLenght == 0) {
        return const SizedBox.shrink();
      } else {
        // Déplacer la logique de speech hors du build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (speechProvider.canSpeak()) {
            TTS().speetch(
                "Vous avez ${widget.notesLenght} nouvelle note${widget.notesLenght > 1 ? 's' : ''} non lue${widget.notesLenght > 1 ? 's' : ''}");
            speechProvider.updateLastSpeechTime();
          }
        });
        return GestureDetector(
            onTap: () {
              /* Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SiteSOSList()));*/
            },
            child: Loading(size: 18, inline: false, sos: true, status: true));
      }
    });
  }
}
