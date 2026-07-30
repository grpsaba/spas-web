import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/error_logs/models/error_log_model.dart';
import 'package:spas_web/error_logs/providers/error_log_provider.dart';
import 'package:spas_web/error_logs/widgets/error_type_badge.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';
import 'package:spas_web/pointage_redesign/presentation/dialogs/modern_dialog.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/success_snackbar.dart';
import 'package:spas_web/services/authentication.dart';
import 'package:spas_web/services/site.dart';

class ErrorLogDetailPage extends StatefulWidget {
  final ErrorLog errorLog;

  const ErrorLogDetailPage({super.key, required this.errorLog});

  @override
  State<ErrorLogDetailPage> createState() => _ErrorLogDetailPageState();
}

class _ErrorLogDetailPageState extends State<ErrorLogDetailPage> {
  late ErrorLog _currentLog;
  bool _showTechnicalDetails = false;
  bool _showStackTrace = false;

  @override
  void initState() {
    super.initState();
    _currentLog = widget.errorLog;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    return PageModel(
      pageIndex: 18,
      title: "Détail de l'erreur",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PointageSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: PointageSpacing.lg),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildDetailsCard()),
                  const SizedBox(width: PointageSpacing.lg),
                  Expanded(flex: 3, child: _buildMapCard()),
                ],
              )
            else ...[
              _buildDetailsCard(),
              const SizedBox(height: PointageSpacing.lg),
              _buildMapCard(),
            ],
            const SizedBox(height: PointageSpacing.lg),
            _buildTechnicalDetails(),
            if (_currentLog.isResolved) ...[
              const SizedBox(height: PointageSpacing.lg),
              _buildResolutionCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1000;

    return Container(
      padding: const EdgeInsets.all(PointageSpacing.md),
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: PointageSpacing.md,
            runSpacing: PointageSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                onPressed: () => context.go('/errorlogs'),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Retour',
              ),
              ErrorTypeBadge(errorType: _currentLog.errorType, large: true),
              _buildStatusBadge(),
              if (!isCompact) _buildResolveAction(context),
            ],
          ),
          const SizedBox(height: PointageSpacing.md),
          if (isCompact) ...[
            _buildLogIdentityBlock(),
            const SizedBox(height: PointageSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildResolveAction(context),
            ),
          ] else
            _buildLogIdentityBlock(),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informations générales',
              style: PointageTextStyles.headline4),
          const SizedBox(height: PointageSpacing.md),
          const Divider(),
          const SizedBox(height: PointageSpacing.md),
          _buildDetailRow('Type de pointage', _currentLog.pointageTypeLabel),
          _buildDetailRow('Type d\'erreur',
              ErrorTypeConfig.getLabel(_currentLog.errorType)),
          _buildDetailRow('Message', _currentLog.customMessage ?? 'N/A'),
          if (_currentLog.distance != null)
            _buildDetailRow(
                'Distance', '${_currentLog.distance!.toStringAsFixed(2)} m'),
          if (_currentLog.gpsAccuracy != null)
            _buildGpsAccuracyRow(_currentLog.gpsAccuracy!),
          if (_currentLog.gpsSource != null ||
              _currentLog.gpsAgeSeconds != null ||
              _currentLog.gpsTimestamp != null ||
              _currentLog.backgroundTrackerActive != null ||
              _currentLog.backgroundCacheAgeSeconds != null ||
              _currentLog.backgroundCacheAccuracy != null ||
              _currentLog.backgroundCacheTimestamp != null ||
              _currentLog.freshGpsAttempted != null ||
              (_currentLog.freshGpsFailedReason != null &&
                  _currentLog.freshGpsFailedReason!.trim().isNotEmpty))
            _buildGpsContextSection(),
          _buildDetailRow(
              'En ligne', _currentLog.isOnline == true ? 'Oui' : 'Non'),
          _buildDetailRow('Plateforme', _currentLog.devicePlatform ?? 'N/A'),
          // Update coordinates button for distance errors
          if (_currentLog.errorType == 'distanceError' &&
              _currentLog.hasValidActorPosition &&
              _currentLog.siteUID != null) ...[
            const SizedBox(height: PointageSpacing.lg),
            _UpdateCoordinatesButton(
              errorLog: _currentLog,
              onSuccess: () => _proposeMarkAsResolved(context),
            ),
          ],
          const SizedBox(height: PointageSpacing.lg),
          Text(_currentLog.actorRoleLabel, style: PointageTextStyles.headline4),
          const SizedBox(height: PointageSpacing.sm),
          const Divider(),
          const SizedBox(height: PointageSpacing.sm),
          if (_currentLog.actor != null) ...[
            _buildDetailRow('Nom', _currentLog.actorName),
            _buildDetailRow('Code', _currentLog.actorCode),
            _buildDetailRow('Téléphone', _currentLog.actorPhone),
            _buildDetailRow('Email', _currentLog.actorEmail),
            if (_currentLog.isZonePointing &&
                _currentLog.zoneMemberPoste != 'N/A')
              _buildDetailRow('Poste', _currentLog.zoneMemberPoste),
            if (_currentLog.isZonePointing &&
                _currentLog.zoneDisplayName != 'N/A')
              _buildDetailRow('Zone', _currentLog.zoneDisplayName),
            if (_currentLog.hasValidActorPosition)
              _buildDetailRow('Position',
                  '${_currentLog.actorLat!.toStringAsFixed(6)}, ${_currentLog.actorLng!.toStringAsFixed(6)}'),
          ] else
            Text('${_currentLog.actorRoleLabel} non disponible',
                style: PointageTextStyles.caption),
          const SizedBox(height: PointageSpacing.lg),
          Text(_currentLog.entityTypeLabel,
              style: PointageTextStyles.headline4),
          const SizedBox(height: PointageSpacing.sm),
          const Divider(),
          const SizedBox(height: PointageSpacing.sm),
          if ((_currentLog.isSitePointing || _currentLog.isZonePointing) &&
              _currentLog.site != null) ...[
            _buildDetailRow('Nom', _currentLog.siteName),
            _buildDetailRow('Code', _currentLog.siteCode),
            _buildDetailRow('Adresse', _currentLog.siteAddress),
            _buildDetailRow('Téléphone', _currentLog.sitePhone),
            if (_currentLog.hasValidSitePosition)
              _buildDetailRow('Position',
                  '${_currentLog.siteLat!.toStringAsFixed(6)}, ${_currentLog.siteLng!.toStringAsFixed(6)}'),
          ] else if (_currentLog.isAgentPointing &&
              _currentLog.agent != null) ...[
            _buildDetailRow('Nom', _currentLog.agentName),
            _buildDetailRow('Code', _currentLog.agentCode),
            _buildDetailRow('Téléphone', _currentLog.agentPhone),
            if (_currentLog.agentSiteName != null)
              _buildDetailRow('Site', _currentLog.agentSiteName!),
            _buildDetailRow(
                'Agent trouvé', _currentLog.agentFound == true ? 'Oui' : 'Non'),
            _buildDetailRow('Actif', _currentLog.agentActif ? 'Oui' : 'Non'),
          ] else
            const Text('Données non disponibles',
                style: PointageTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildLogIdentityBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PointageSpacing.md),
      decoration: BoxDecoration(
        color: PointageColors.background,
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(color: PointageColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Erreur #${_currentLog.id.substring(0, 8)}...',
            style: PointageTextStyles.headline4,
          ),
          const SizedBox(height: PointageSpacing.xs),
          Text(
            _formatDateTime(_currentLog.timestamp),
            style: PointageTextStyles.caption,
          ),
          const SizedBox(height: PointageSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SelectableText(
                  _currentLog.id,
                  style: PointageTextStyles.body2.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: PointageSpacing.sm),
              Tooltip(
                message: 'Copier l’identifiant complet',
                child: IconButton(
                  onPressed: _copyLogId,
                  icon: const Icon(Icons.copy, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResolveAction(BuildContext context) {
    if (_currentLog.isResolved) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: () => _markAsResolved(context),
      icon: const Icon(Icons.check_circle, size: 18),
      label: const Text('Marquer comme résolu'),
      style: ElevatedButton.styleFrom(
        backgroundColor: PointageColors.success,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isResolved = _currentLog.isResolved;
    final color = isResolved ? PointageColors.success : PointageColors.error;
    final icon = isResolved ? Icons.check_circle : Icons.pending_actions;
    final label = isResolved ? 'Résolu' : 'À traiter';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.md,
        vertical: PointageSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: PointageSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isCompact = MediaQuery.of(context).size.width < 720;

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: PointageSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: PointageTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: PointageTextStyles.body2,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PointageSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: PointageTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: PointageTextStyles.body2,
            ),
          ),
        ],
      ),
    );
  }

  /// Build GPS accuracy row with visual quality indicator
  Widget _buildGpsAccuracyRow(double accuracy,
      {String label = 'Précision GPS'}) {
    // Determine quality level based on accuracy
    // < 10m = Excellent, 10-25m = Good, 25-50m = Fair, > 50m = Poor
    final String qualityLabel;
    final Color qualityColor;
    final IconData qualityIcon;

    if (accuracy < 10) {
      qualityLabel = 'Excellente';
      qualityColor = PointageColors.success;
      qualityIcon = Icons.gps_fixed;
    } else if (accuracy < 25) {
      qualityLabel = 'Bonne';
      qualityColor = const Color(0xFF4CAF50);
      qualityIcon = Icons.gps_fixed;
    } else if (accuracy < 50) {
      qualityLabel = 'Moyenne';
      qualityColor = PointageColors.warning;
      qualityIcon = Icons.gps_not_fixed;
    } else {
      qualityLabel = 'Faible';
      qualityColor = PointageColors.error;
      qualityIcon = Icons.gps_off;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PointageSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: PointageTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(qualityIcon, size: 16, color: qualityColor),
                const SizedBox(width: 6),
                Text(
                  '${accuracy.toStringAsFixed(1)} m',
                  style: PointageTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: qualityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: qualityColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    qualityLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: qualityColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build GPS context section with source, age, timestamp and enriched diagnostics
  Widget _buildGpsContextSection() {
    final hasFreshGpsFailedReason = _currentLog.freshGpsFailedReason != null &&
        _currentLog.freshGpsFailedReason!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: PointageSpacing.sm),
      padding: const EdgeInsets.all(PointageSpacing.md),
      decoration: BoxDecoration(
        color: PointageColors.chartBlue.withValues(alpha: 0.05),
        borderRadius: PointageBorderRadius.medium,
        border:
            Border.all(color: PointageColors.chartBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.satellite_alt,
                size: 16,
                color: PointageColors.chartBlue,
              ),
              const SizedBox(width: PointageSpacing.xs),
              Text(
                'Contexte GPS',
                style: PointageTextStyles.label.copyWith(
                  color: PointageColors.chartBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.sm),
          if (_currentLog.gpsSource != null)
            _buildGpsSourceRow(_currentLog.gpsSource!),
          if (_currentLog.gpsAgeSeconds != null)
            _buildGpsAgeRow(_currentLog.gpsAgeSeconds!),
          if (_currentLog.gpsTimestamp != null)
            _buildDetailRow(
              'Timestamp GPS',
              _formatDateTime(_currentLog.gpsTimestamp!),
            ),
          if (_currentLog.backgroundTrackerActive != null ||
              _currentLog.backgroundCacheAgeSeconds != null ||
              _currentLog.backgroundCacheAccuracy != null ||
              _currentLog.backgroundCacheTimestamp != null) ...[
            const SizedBox(height: PointageSpacing.sm),
            _buildGpsDiagnosticSection(
              title: 'Cache background',
              icon: Icons.route,
              color: PointageColors.warning,
              children: [
                if (_currentLog.backgroundTrackerActive != null)
                  _buildBooleanDiagnosticRow(
                    'Background tracker',
                    _currentLog.backgroundTrackerActive!,
                    trueLabel: 'Actif',
                    falseLabel: 'Inactif',
                  ),
                if (_currentLog.backgroundCacheAgeSeconds != null)
                  _buildGpsAgeRow(
                    _currentLog.backgroundCacheAgeSeconds!,
                    label: 'Âge cache',
                  ),
                if (_currentLog.backgroundCacheAccuracy != null)
                  _buildGpsAccuracyRow(
                    _currentLog.backgroundCacheAccuracy!,
                    label: 'Précision cache',
                  ),
                if (_currentLog.backgroundCacheTimestamp != null)
                  _buildDetailRow(
                    'Timestamp cache',
                    _formatDateTime(_currentLog.backgroundCacheTimestamp!),
                  ),
              ],
            ),
          ],
          if (_currentLog.freshGpsAttempted != null ||
              hasFreshGpsFailedReason) ...[
            const SizedBox(height: PointageSpacing.sm),
            _buildGpsDiagnosticSection(
              title: 'Tentative GPS frais',
              icon: Icons.my_location,
              color: PointageColors.success,
              children: [
                if (_currentLog.freshGpsAttempted != null)
                  _buildBooleanDiagnosticRow(
                    'GPS frais tenté',
                    _currentLog.freshGpsAttempted!,
                    trueLabel: 'Oui',
                    falseLabel: 'Non',
                  ),
                if (hasFreshGpsFailedReason)
                  _buildDetailRow(
                    'Cause échec GPS frais',
                    _currentLog.freshGpsFailedReason!,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build GPS source row with descriptive label
  Widget _buildGpsSourceRow(String source) {
    final String displayLabel;
    final IconData icon;
    final Color color;

    if (source.toLowerCase() == 'cache') {
      displayLabel = 'Cache (background tracking)';
      icon = Icons.cached;
      color = PointageColors.chartBlue;
    } else if (source.toLowerCase() == 'fresh') {
      displayLabel = 'Frais (demande directe)';
      icon = Icons.refresh;
      color = PointageColors.success;
    } else {
      displayLabel = source;
      icon = Icons.help_outline;
      color = PointageColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PointageSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'Source GPS',
              style: PointageTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  displayLabel,
                  style: PointageTextStyles.body2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build GPS age row with warning indicator for old positions
  Widget _buildGpsAgeRow(int ageSeconds, {String label = 'Âge position'}) {
    final bool isOld = ageSeconds > 60;
    final Color color =
        isOld ? PointageColors.warning : PointageColors.textPrimary;

    String ageDisplay;
    if (ageSeconds < 60) {
      ageDisplay = '$ageSeconds secondes';
    } else if (ageSeconds < 3600) {
      final minutes = ageSeconds ~/ 60;
      final seconds = ageSeconds % 60;
      ageDisplay = '$minutes min ${seconds > 0 ? '$seconds sec' : ''}';
    } else {
      final hours = ageSeconds ~/ 3600;
      final minutes = (ageSeconds % 3600) ~/ 60;
      ageDisplay = '$hours h ${minutes > 0 ? '$minutes min' : ''}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PointageSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: PointageTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (isOld) Icon(Icons.warning_amber, size: 16, color: color),
                if (isOld) const SizedBox(width: 6),
                Text(
                  ageDisplay,
                  style: PointageTextStyles.body2.copyWith(
                    color: color,
                    fontWeight: isOld ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                if (isOld) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PointageColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Position ancienne',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: PointageColors.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsDiagnosticSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PointageSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: PointageSpacing.xs),
              Text(
                title,
                style: PointageTextStyles.label.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBooleanDiagnosticRow(
    String label,
    bool value, {
    String trueLabel = 'Oui',
    String falseLabel = 'Non',
  }) {
    final color = value ? PointageColors.success : PointageColors.textSecondary;
    final icon = value ? Icons.check_circle : Icons.cancel_outlined;
    final text = value ? trueLabel : falseLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PointageSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: PointageTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: PointageTextStyles.body2.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    final hasPositions =
        _currentLog.hasValidActorPosition || _currentLog.hasValidSitePosition;

    return Container(
      height: 400,
      decoration: PointageCardDecorations.standard,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(PointageSpacing.md),
            child: Row(
              children: [
                const Text('Comparaison des positions',
                    style: PointageTextStyles.headline4),
                const Spacer(),
                if (hasPositions) ...[
                  _buildLegendItem(Colors.blue, _currentLog.actorRoleLabel),
                  const SizedBox(width: PointageSpacing.md),
                  _buildLegendItem(
                    Colors.red,
                    _currentLog.referenceSiteLabel,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: hasPositions
                ? GoogleMap(
                    initialCameraPosition: _getInitialCameraPosition(),
                    markers: _buildMarkers(),
                    polylines: _buildPolylines(),
                    onMapCreated: (controller) {},
                    mapType: MapType.normal,
                    zoomControlsEnabled: true,
                    myLocationButtonEnabled: false,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_outlined,
                            size: 64, color: PointageColors.disabled),
                        const SizedBox(height: PointageSpacing.md),
                        Text(
                          'Positions non disponibles',
                          style: PointageTextStyles.body2
                              .copyWith(color: PointageColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: PointageTextStyles.caption),
      ],
    );
  }

  CameraPosition _getInitialCameraPosition() {
    if (_currentLog.hasValidActorPosition) {
      return CameraPosition(
        target: LatLng(_currentLog.actorLat!, _currentLog.actorLng!),
        zoom: 15,
      );
    } else if (_currentLog.hasValidSitePosition) {
      return CameraPosition(
        target: LatLng(_currentLog.siteLat!, _currentLog.siteLng!),
        zoom: 15,
      );
    }
    return const CameraPosition(target: LatLng(0, 0), zoom: 2);
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_currentLog.hasValidActorPosition) {
      markers.add(Marker(
        markerId: const MarkerId('actor'),
        position: LatLng(_currentLog.actorLat!, _currentLog.actorLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: _currentLog.actorRoleLabel,
          snippet: _currentLog.actorName,
        ),
      ));
    }

    if (_currentLog.hasValidSitePosition) {
      markers.add(Marker(
        markerId: const MarkerId('site'),
        position: LatLng(_currentLog.siteLat!, _currentLog.siteLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: _currentLog.referenceSiteLabel,
          snippet: _currentLog.siteName,
        ),
      ));
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (!_currentLog.hasValidActorPosition ||
        !_currentLog.hasValidSitePosition) {
      return {};
    }

    return {
      Polyline(
        polylineId: const PolylineId('distance'),
        points: [
          LatLng(_currentLog.actorLat!, _currentLog.actorLng!),
          LatLng(_currentLog.siteLat!, _currentLog.siteLng!),
        ],
        color: PointageColors.error,
        width: 3,
        patterns: [PatternItem.dash(10), PatternItem.gap(5)],
      ),
    };
  }

  Widget _buildTechnicalDetails() {
    if (_currentLog.technicalError == null && _currentLog.stackTrace == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.code, size: 20, color: PointageColors.chartPurple),
              SizedBox(width: PointageSpacing.sm),
              Text('Détails techniques', style: PointageTextStyles.headline4),
            ],
          ),
          const SizedBox(height: PointageSpacing.sm),
          Text(
            'Cette section est surtout utile pour l’investigation technique.',
            style: PointageTextStyles.caption,
          ),
          const SizedBox(height: PointageSpacing.md),
          const Divider(),
          if (_currentLog.technicalError != null) ...[
            const SizedBox(height: PointageSpacing.sm),
            _buildExpandableTechnicalBlock(
              title: 'Erreur technique',
              isExpanded: _showTechnicalDetails,
              onToggle: () {
                setState(() {
                  _showTechnicalDetails = !_showTechnicalDetails;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(PointageSpacing.md),
                decoration: BoxDecoration(
                  color: PointageColors.background,
                  borderRadius: PointageBorderRadius.medium,
                  border: Border.all(color: PointageColors.divider),
                ),
                child: SelectableText(
                  _currentLog.technicalError!,
                  style: PointageTextStyles.body2.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
          if (_currentLog.stackTrace != null) ...[
            const SizedBox(height: PointageSpacing.sm),
            _buildExpandableTechnicalBlock(
              title: 'Stack trace',
              isExpanded: _showStackTrace,
              onToggle: () {
                setState(() {
                  _showStackTrace = !_showStackTrace;
                });
              },
              child: Container(
                width: double.infinity,
                height: 200,
                padding: const EdgeInsets.all(PointageSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: PointageBorderRadius.medium,
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _currentLog.stackTrace!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFFD4D4D4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResolutionCard() {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: BoxDecoration(
        color: PointageColors.success.withValues(alpha: 0.05),
        borderRadius: PointageBorderRadius.large,
        border:
            Border.all(color: PointageColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, size: 24, color: PointageColors.success),
              SizedBox(width: PointageSpacing.sm),
              Text('Résolution', style: PointageTextStyles.headline4),
            ],
          ),
          const SizedBox(height: PointageSpacing.md),
          _buildDetailRow('Résolu par', _currentLog.resolvedBy ?? 'N/A'),
          if (_currentLog.resolvedAt != null)
            _buildDetailRow(
                'Date de résolution', _formatDateTime(_currentLog.resolvedAt!)),
        ],
      ),
    );
  }

  Widget _buildExpandableTechnicalBlock({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: PointageColors.background,
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(color: PointageColors.divider),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: PointageBorderRadius.medium,
            child: Padding(
              padding: const EdgeInsets.all(PointageSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: PointageTextStyles.label),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: PointageColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PointageSpacing.md,
                0,
                PointageSpacing.md,
                PointageSpacing.md,
              ),
              child: child,
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _copyLogId() async {
    await Clipboard.setData(ClipboardData(text: _currentLog.id));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Identifiant du log copié'),
        backgroundColor: PointageColors.success,
      ),
    );
  }

  Future<void> _markAsResolved(BuildContext context) async {
    final manager = AuthService.currentManager;
    if (manager == null) return;

    final resolvedBy = '${manager.firstName} ${manager.lastName}';
    final provider = context.read<ErrorLogProvider>();
    final success = await provider.markAsResolved(_currentLog.id, resolvedBy);

    if (success && mounted) {
      setState(() {
        _currentLog = _currentLog.copyWithResolved(
          resolvedBy: resolvedBy,
          resolvedAt: DateTime.now(),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur marquée comme résolue'),
            backgroundColor: PointageColors.success,
          ),
        );
      }
    }
  }

  /// Propose to mark the error as resolved after a successful coordinate update
  Future<void> _proposeMarkAsResolved(BuildContext context) async {
    if (_currentLog.isResolved) return;

    final shouldResolve = await ModernDialog.show<bool>(
      context: context,
      title: 'Marquer comme résolu ?',
      content: const Text(
        'Les coordonnées du site ont été mises à jour. '
        'Voulez-vous marquer cette erreur comme résolue ?',
      ),
      actions: [
        DialogAction(
          label: 'Non',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        DialogAction(
          label: 'Oui, marquer comme résolu',
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );

    if (shouldResolve == true && mounted) {
      await _markAsResolved(context);
    }
  }
}

/// Widget for updating site coordinates from the actor position.
/// Only shown for distance errors with a valid actor position.
class _UpdateCoordinatesButton extends StatefulWidget {
  final ErrorLog errorLog;
  final VoidCallback onSuccess;

  const _UpdateCoordinatesButton({
    required this.errorLog,
    required this.onSuccess,
  });

  @override
  State<_UpdateCoordinatesButton> createState() =>
      _UpdateCoordinatesButtonState();
}

class _UpdateCoordinatesButtonState extends State<_UpdateCoordinatesButton> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.errorLog;

    return Container(
      padding: const EdgeInsets.all(PointageSpacing.md),
      decoration: BoxDecoration(
        color: PointageColors.warning.withValues(alpha: 0.1),
        borderRadius: PointageBorderRadius.medium,
        border:
            Border.all(color: PointageColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: PointageColors.warning,
                size: PointageIconSizes.md,
              ),
              const SizedBox(width: PointageSpacing.sm),
              const Expanded(
                child: Text(
                  'Corriger les coordonnées du site',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: PointageColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.sm),
          Text(
            'Cette action mettra à jour de façon durable la position enregistrée du site avec la ${log.actorPositionLabel}.',
            style: PointageTextStyles.caption,
          ),
          const SizedBox(height: PointageSpacing.sm),
          if (log.hasValidSitePosition) ...[
            Text(
              'Coordonnées actuellement enregistrées :',
              style: PointageTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: PointageSpacing.xs),
            Container(
              padding: const EdgeInsets.all(PointageSpacing.sm),
              decoration: BoxDecoration(
                color: PointageColors.background,
                borderRadius: PointageBorderRadius.small,
                border: Border.all(color: PointageColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latitude: ${log.siteLat!.toStringAsFixed(6)}',
                    style: PointageTextStyles.body2.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'Longitude: ${log.siteLng!.toStringAsFixed(6)}',
                    style: PointageTextStyles.body2.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: PointageSpacing.sm),
          ],
          Text(
            'Nouvelles coordonnées proposées (${log.actorPositionLabel}) :',
            style: PointageTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: PointageSpacing.xs),
          Container(
            padding: const EdgeInsets.all(PointageSpacing.sm),
            decoration: BoxDecoration(
              color: PointageColors.background,
              borderRadius: PointageBorderRadius.small,
              border: Border.all(color: PointageColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latitude: ${log.actorLat!.toStringAsFixed(6)}',
                        style: PointageTextStyles.body2.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'Longitude: ${log.actorLng!.toStringAsFixed(6)}',
                        style: PointageTextStyles.body2.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PointageSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUpdating ? null : () => _updateCoordinates(context),
              icon: _isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.update, size: 18),
              label: Text(_isUpdating
                  ? 'Mise à jour...'
                  : 'Mettre à jour les coordonnées du site'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PointageColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: PointageSpacing.md,
                  vertical: PointageSpacing.sm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCoordinates(BuildContext context) async {
    final log = widget.errorLog;

    // Show confirmation dialog
    final confirmed = await ModernDialog.show<bool>(
      context: context,
      title: 'Mettre à jour les coordonnées',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voulez-vous mettre à jour les coordonnées du site "${log.siteName}" '
            'avec la ${log.actorPositionLabel} ? Cette modification affectera la '
            'position de référence utilisée pour les prochains contrôles.',
          ),
          const SizedBox(height: PointageSpacing.md),
          if (log.hasValidSitePosition) ...[
            Container(
              padding: const EdgeInsets.all(PointageSpacing.md),
              decoration: BoxDecoration(
                color: PointageColors.background,
                borderRadius: PointageBorderRadius.medium,
                border: Border.all(color: PointageColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coordonnées actuelles:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: PointageSpacing.sm),
                  Text('Latitude: ${log.siteLat!.toStringAsFixed(6)}'),
                  Text('Longitude: ${log.siteLng!.toStringAsFixed(6)}'),
                ],
              ),
            ),
            const SizedBox(height: PointageSpacing.sm),
          ],
          Container(
            padding: const EdgeInsets.all(PointageSpacing.md),
            decoration: BoxDecoration(
              color: PointageColors.background,
              borderRadius: PointageBorderRadius.medium,
              border: Border.all(color: PointageColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nouvelles coordonnées:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: PointageSpacing.sm),
                Text('Latitude: ${log.actorLat!.toStringAsFixed(6)}'),
                Text('Longitude: ${log.actorLng!.toStringAsFixed(6)}'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        DialogAction(
          label: 'Annuler',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        DialogAction(
          label: 'Mettre à jour',
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );

    if (confirmed != true) return;

    setState(() => _isUpdating = true);

    try {
      // Fetch the site from Firestore
      final site = await SiteService().one(log.siteUID);

      if (site == null) {
        if (mounted) {
          _showErrorSnackbar(context, 'Site introuvable');
        }
        return;
      }

      // Update the site coordinates with actor position
      site.latLng = LatLngModel(
        lat: log.actorLat!,
        lng: log.actorLng!,
      );

      // Save to Firestore
      await SiteService().update(site);

      if (mounted) {
        SuccessSnackbar.show(
          context,
          message:
              'Coordonnées du site "${log.siteName}" mises à jour avec succès',
          icon: Icons.location_on,
        );

        // Call the success callback to propose marking as resolved
        widget.onSuccess();
      }
    } catch (e) {
      debugPrint('Error updating site coordinates: $e');
      if (mounted) {
        _showErrorSnackbar(
          context,
          'Erreur lors de la mise à jour: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: PointageSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: PointageColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
