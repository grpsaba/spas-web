import 'package:flutter/material.dart';
import '../design_system.dart';

/// Helper class for creating consistent, accessible tooltips throughout the application
/// 
/// Provides:
/// - Standardized tooltip styling
/// - Keyboard shortcut integration
/// - Screen reader accessibility
/// - Consistent timing and behavior
class TooltipHelper {
  /// Create a tooltip with optional keyboard shortcut
  /// 
  /// Example:
  /// ```dart
  /// Tooltip(
  ///   message: TooltipHelper.withShortcut('Rechercher', 'Ctrl+F'),
  ///   ...
  /// )
  /// ```
  static String withShortcut(String message, String? shortcut) {
    if (shortcut == null || shortcut.isEmpty) {
      return message;
    }
    return '$message ($shortcut)';
  }

  /// Standard tooltip decoration for consistent styling
  static Decoration get decoration => BoxDecoration(
        color: PointageColors.textPrimary.withValues(alpha: 0.9),
        borderRadius: PointageBorderRadius.small,
      );

  /// Standard tooltip text style
  static TextStyle get textStyle => PointageTextStyles.caption.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      );

  /// Standard tooltip padding
  static EdgeInsets get padding => const EdgeInsets.symmetric(
        horizontal: PointageSpacing.sm,
        vertical: PointageSpacing.xs,
      );

  /// Standard tooltip wait duration before showing
  static Duration get waitDuration => const Duration(milliseconds: 500);

  /// Standard tooltip show duration
  static Duration get showDuration => const Duration(seconds: 3);

  /// Wrap a widget with a tooltip
  /// 
  /// This provides consistent tooltip styling and accessibility
  /// 
  /// Example:
  /// ```dart
  /// TooltipHelper.wrap(
  ///   message: 'Rafraîchir les données',
  ///   shortcut: 'Ctrl+R',
  ///   child: IconButton(
  ///     icon: Icon(Icons.refresh),
  ///     onPressed: _refresh,
  ///   ),
  /// )
  /// ```
  static Widget wrap({
    required String message,
    String? shortcut,
    required Widget child,
    bool preferBelow = true,
    EdgeInsetsGeometry? margin,
  }) {
    return Tooltip(
      message: withShortcut(message, shortcut),
      decoration: decoration,
      textStyle: textStyle,
      padding: padding,
      waitDuration: waitDuration,
      showDuration: showDuration,
      preferBelow: preferBelow,
      margin: margin,
      child: Semantics(
        label: message,
        hint: shortcut != null ? 'Raccourci clavier: $shortcut' : null,
        button: true,
        enabled: true,
        child: child,
      ),
    );
  }

  /// Create a tooltip for an icon button
  static Widget iconButton({
    required String tooltip,
    String? shortcut,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
    double? iconSize,
    EdgeInsetsGeometry? padding,
  }) {
    return wrap(
      message: tooltip,
      shortcut: shortcut,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: color,
        iconSize: iconSize,
        padding: padding,
      ),
    );
  }

  /// Create a tooltip for a text button
  static Widget textButton({
    required String tooltip,
    String? shortcut,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    ButtonStyle? style,
  }) {
    return wrap(
      message: tooltip,
      shortcut: shortcut,
      child: icon != null
          ? TextButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: style,
            )
          : TextButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            ),
    );
  }

  /// Create a tooltip for an elevated button
  static Widget elevatedButton({
    required String tooltip,
    String? shortcut,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    ButtonStyle? style,
  }) {
    return wrap(
      message: tooltip,
      shortcut: shortcut,
      child: icon != null
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: style,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            ),
    );
  }

  /// Create a tooltip for a floating action button
  static Widget floatingActionButton({
    required String tooltip,
    String? shortcut,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    bool mini = false,
  }) {
    return wrap(
      message: tooltip,
      shortcut: shortcut,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        mini: mini,
        child: Icon(icon),
      ),
    );
  }

  /// Common tooltip messages used throughout the application
  static const String refresh = 'Rafraîchir les données';
  static const String search = 'Rechercher';
  static const String filter = 'Filtrer les résultats';
  static const String export = 'Exporter les données';
  static const String exportExcel = 'Exporter en Excel';
  static const String exportPdf = 'Exporter en PDF';
  static const String close = 'Fermer';
  static const String cancel = 'Annuler';
  static const String confirm = 'Confirmer';
  static const String delete = 'Supprimer';
  static const String edit = 'Modifier';
  static const String add = 'Ajouter';
  static const String save = 'Enregistrer';
  static const String clear = 'Effacer';
  static const String clearAll = 'Tout effacer';
  static const String selectDate = 'Sélectionner une date';
  static const String selectDateRange = 'Sélectionner une période';
  static const String previousPage = 'Page précédente';
  static const String nextPage = 'Page suivante';
  static const String firstPage = 'Première page';
  static const String lastPage = 'Dernière page';
  static const String sort = 'Trier';
  static const String sortAscending = 'Trier par ordre croissant';
  static const String sortDescending = 'Trier par ordre décroissant';
  static const String showChart = 'Afficher le graphique';
  static const String hideChart = 'Masquer le graphique';
  static const String toggleView = 'Basculer la vue';
  static const String generateReport = 'Générer le rapport';
  static const String downloadReport = 'Télécharger le rapport';
  static const String previewReport = 'Prévisualiser le rapport';
  static const String selectSupervisors = 'Sélectionner des superviseurs';
  static const String selectSites = 'Sélectionner des sites';
  static const String selectZones = 'Sélectionner des zones';
  static const String clearFilters = 'Effacer tous les filtres';
  static const String applyFilters = 'Appliquer les filtres';
  static const String retry = 'Réessayer';
  static const String back = 'Retour';
  static const String forward = 'Suivant';
  static const String settings = 'Paramètres';
  static const String help = 'Aide';
  static const String info = 'Information';
  static const String warning = 'Avertissement';
  static const String error = 'Erreur';
  static const String success = 'Succès';

  /// Keyboard shortcuts used in the application
  static const String shortcutRefresh = 'Ctrl+R';
  static const String shortcutSearch = 'Ctrl+F';
  static const String shortcutExport = 'Ctrl+E';
  static const String shortcutSave = 'Ctrl+S';
  static const String shortcutClose = 'Esc';
  static const String shortcutSelectAll = 'Ctrl+A';
  static const String shortcutCopy = 'Ctrl+C';
  static const String shortcutPaste = 'Ctrl+V';
  static const String shortcutUndo = 'Ctrl+Z';
  static const String shortcutRedo = 'Ctrl+Y';
}
