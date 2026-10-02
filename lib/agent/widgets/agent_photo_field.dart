import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../services/agent_photo.dart';

class AgentPhotoField extends StatefulWidget {
  const AgentPhotoField({
    super.key,
    required this.photoUrl,
    required this.onChanged,
    required this.onBusyChanged,
    this.enabled = true,
  });

  final String? photoUrl;
  final void Function(Uint8List? photo, bool removed) onChanged;
  final ValueChanged<bool> onBusyChanged;
  final bool enabled;

  @override
  State<AgentPhotoField> createState() => _AgentPhotoFieldState();
}

class _AgentPhotoFieldState extends State<AgentPhotoField> {
  Uint8List? _photo;
  bool _removed = false;
  bool _reading = false;
  String? _error;

  Future<void> _pick() async {
    widget.onBusyChanged(true);
    setState(() {
      _reading = true;
      _error = null;
    });
    try {
      final file = await openFile(acceptedTypeGroups: const [
        XTypeGroup(label: 'Photo', extensions: ['jpg', 'jpeg', 'png']),
      ]);
      if (file == null) return;
      if (await file.length() > AgentPhotoService.maxFileBytes) {
        throw const FormatException('La photo doit peser moins de 5 Mo.');
      }
      final photo = await AgentPhotoService.prepare(await file.readAsBytes());
      if (!mounted) return;
      setState(() {
        _photo = photo;
        _removed = false;
      });
      widget.onChanged(photo, false);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is FormatException
            ? error.message.toString()
            : 'Impossible de lire cette photo. Choisissez une image JPG ou PNG.');
      }
    } finally {
      if (mounted) {
        setState(() => _reading = false);
        widget.onBusyChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.photoUrl?.trim() ?? '';
    final hasPhoto = _photo != null || (!_removed && url.isNotEmpty);
    final placeholder = ColoredBox(
      color: const Color(0xFFEDF3FA),
      child: Center(
          child: Icon(Icons.person_outline,
              size: 44, color: Colors.blueGrey.shade400)),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 20,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 100,
              height: 120,
              child: _photo != null
                  ? Image.memory(_photo!, fit: BoxFit.cover)
                  : hasPhoto
                      ? Image.network(url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => placeholder)
                      : placeholder,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Photo d’identité du badge',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                    'JPG ou PNG, 5 Mo maximum. Choisissez un portrait avec le visage centré.'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                    onPressed: widget.enabled && !_reading ? _pick : null,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(_reading
                        ? 'Lecture de la photo…'
                        : hasPhoto
                            ? 'Changer la photo'
                            : 'Choisir une photo'),
                  ),
                  if (hasPhoto)
                    TextButton(
                      onPressed: widget.enabled && !_reading
                          ? () {
                              setState(() {
                                _photo = null;
                                _removed = true;
                                _error = null;
                              });
                              widget.onChanged(null, true);
                            }
                          : null,
                      child: const Text('Retirer'),
                    ),
                ]),
                if (_error != null)
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
