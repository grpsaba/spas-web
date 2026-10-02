import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/providers/speech_provider.dart';
import 'package:spas_web/services/authentication.dart';
import 'package:spas_web/services/export.dart';
import 'package:spas_web/services/loading.dart';
import 'package:spas_web/services/note.dart';
import 'package:spas_web/services/player.dart';

class UnreadNotesNotification extends StatefulWidget {
  const UnreadNotesNotification({super.key});

  @override
  State<UnreadNotesNotification> createState() =>
      _UnreadNotesNotificationState();
}

class _UnreadNotesNotificationState extends State<UnreadNotesNotification> {
  final NoteService _noteService = NoteService();

  Set<String>? _knownUnreadIds;
  Set<String>? _pendingUnreadIds;
  bool _syncScheduled = false;

  void _scheduleUnreadSync(Set<String> unreadIds) {
    _pendingUnreadIds = unreadIds;
    if (_syncScheduled) return;

    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;

      final nextIds = _pendingUnreadIds ?? <String>{};
      _pendingUnreadIds = null;
      final previousIds = _knownUnreadIds;
      final hasNewNotes = previousIds == null
          ? nextIds.isNotEmpty
          : nextIds.difference(previousIds).isNotEmpty;

      _knownUnreadIds = Set<String>.from(nextIds);
      if (hasNewNotes) {
        _announceUnreadNotes(nextIds.length);
      }
    });
  }

  void _announceUnreadNotes(int count) {
    final speechProvider = context.read<SpeechProvider>();
    if (!speechProvider.canSpeak()) return;

    final plural = count > 1;
    try {
      TTS().speetch(
        'Vous avez $count ${plural ? 'notes' : 'note'} '
        '${plural ? 'non lues' : 'non lue'}',
      );
      speechProvider.updateLastSpeechTime();
    } catch (_) {
      // The visual notification remains available if speech is unsupported.
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _noteService.allNoViewedNote(),
      builder: (context, snapshot) {
        final unreadIds = snapshot.hasData
            ? snapshot.data!.docs.map((document) => document.id).toSet()
            : <String>{};
        if (snapshot.hasData) {
          _scheduleUnreadSync(unreadIds);
        }

        final count = unreadIds.length;
        final hasError = snapshot.hasError;
        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final tooltip = hasError
            ? 'Impossible de charger les notes non consultées'
            : count == 0
                ? 'Aucune note non consultée'
                : '$count ${count > 1 ? 'notes non consultées' : 'note non consultée'}';

        return Tooltip(
          message: tooltip,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showUnreadNotesDialog(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: count > 0 ? const Color(0xFFFFF1F0) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: count > 0
                        ? const Color(0xFFFFB4AD)
                        : const Color(0xFFE5EAF2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (count > 0)
                          Loading(
                            size: 28,
                            inline: false,
                            sos: true,
                            status: true,
                          )
                        else
                          Icon(
                            hasError
                                ? Icons.cloud_off_outlined
                                : Icons.notifications_none_outlined,
                            color: hasError
                                ? const Color(0xFFD14343)
                                : const Color(0xFF667085),
                            size: 24,
                          ),
                        if (count > 0)
                          Positioned(
                            top: -9,
                            right: -12,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 20),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white),
                              ),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 11),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Notes',
                          style: TextStyle(
                            color: Color(0xFF172033),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          isLoading
                              ? 'Chargement...'
                              : hasError
                                  ? 'Indisponibles'
                                  : count == 0
                                      ? 'À jour'
                                      : '$count non ${count > 1 ? 'lues' : 'lue'}',
                          style: TextStyle(
                            color: count > 0
                                ? const Color(0xFFD14343)
                                : const Color(0xFF667085),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> showUnreadNotesDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _UnreadNotesDialog(),
  );
}

class _UnreadNotesDialog extends StatefulWidget {
  const _UnreadNotesDialog();

  @override
  State<_UnreadNotesDialog> createState() => _UnreadNotesDialogState();
}

class _UnreadNotesDialogState extends State<_UnreadNotesDialog> {
  final NoteService _noteService = NoteService();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _updatingNoteIds = <String>{};
  String _query = '';

  bool get _canMarkAsRead =>
      AuthService.currentManager?.profil?.getModule(ModuleName.NOTE)?.add ??
      false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead(Note note) async {
    if (_updatingNoteIds.contains(note.id)) return;
    setState(() => _updatingNoteIds.add(note.id));

    note.viewed = true;
    try {
      await _noteService.update(note);
    } catch (_) {
      note.viewed = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de marquer cette note comme consultée.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingNoteIds.remove(note.id));
      }
    }
  }

  List<Note> _parseNotes(QuerySnapshot snapshot) {
    final notes = <Note>[];
    for (final document in snapshot.docs) {
      try {
        final data = Map<String, dynamic>.from(
          document.data() as Map<String, dynamic>,
        );
        data.putIfAbsent('id', () => document.id);
        notes.add(Note.fromJson(data));
      } catch (_) {
        // A malformed legacy document must not hide all other unread notes.
      }
    }
    notes.sort((first, second) => second.date.compareTo(first.date));
    return notes;
  }

  List<Note> _filterNotes(List<Note> notes) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return notes;

    return notes.where((note) {
      final searchableText = [
        note.title,
        note.source,
        note.note,
        note.site?.name ?? '',
        note.department?.label ?? '',
      ].join(' ').toLowerCase();
      return searchableText.contains(query);
    }).toList();
  }

  String _formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} '
        'à ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = math.max(300.0, math.min(760.0, screenSize.width - 24));
    final dialogHeight =
        math.max(360.0, math.min(720.0, screenSize.height - 32));

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Rechercher par site, source, titre ou contenu',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Effacer la recherche',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _noteService.allNoViewedNote(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _NotesMessage(
                      icon: Icons.cloud_off_outlined,
                      title: 'Notes indisponibles',
                      message:
                          'La liste des notes non consultées ne peut pas être chargée.',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allNotes = _parseNotes(snapshot.data!);
                  final notes = _filterNotes(allNotes);
                  if (allNotes.isEmpty) {
                    return const _NotesMessage(
                      icon: Icons.task_alt_rounded,
                      title: 'Tout est à jour',
                      message: 'Vous n’avez aucune note non consultée.',
                    );
                  }
                  if (notes.isEmpty) {
                    return const _NotesMessage(
                      icon: Icons.search_off_rounded,
                      title: 'Aucun résultat',
                      message: 'Aucune note ne correspond à votre recherche.',
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${notes.length} ${notes.length > 1 ? 'notes non consultées' : 'note non consultée'}',
                                style: const TextStyle(
                                  color: Color(0xFF667085),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => NoteListToPDF.printNote(notes),
                              icon: const Icon(Icons.print_outlined, size: 18),
                              label: const Text('Imprimer'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: notes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _buildNoteCard(notes[index]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF22252A), Color(0xFF3B3F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFFFFC46B),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes non consultées',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Consultez et validez les dernières observations',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Voir toutes les observations',
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.go('/notes');
            },
            icon: const Icon(Icons.open_in_new, color: Colors.white70),
          ),
          IconButton(
            tooltip: 'Fermer',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final siteName = note.site?.name.trim();
    final departmentName = note.department?.label.trim();
    final isUpdating = _updatingNoteIds.contains(note.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sticky_note_2_outlined,
                  color: Color(0xFFEF8C00),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${note.source} • ${_formatDate(note.date)}',
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Non lue',
                  style: TextStyle(
                    color: Color(0xFFB76E00),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            note.note,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (siteName != null && siteName.isNotEmpty)
                _NoteMetadata(
                  icon: Icons.location_on_outlined,
                  label: siteName,
                ),
              if (departmentName != null && departmentName.isNotEmpty)
                _NoteMetadata(
                  icon: Icons.apartment_outlined,
                  label: departmentName,
                ),
              if (_canMarkAsRead)
                FilledButton.icon(
                  onPressed: isUpdating ? null : () => _markAsRead(note),
                  icon: isUpdating
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Noté'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteMetadata extends StatelessWidget {
  const _NoteMetadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF667085)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475467),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesMessage extends StatelessWidget {
  const _NotesMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: const Color(0xFF98A2B3)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
