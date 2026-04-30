import 'package:cloud_firestore/cloud_firestore.dart';

class AgentBulkConfigService {
  AgentBulkConfigService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'agentconfig';
  static const String defaultDocumentId = 'default';

  static const String lastSecurityAgentNumField = 'lastSecurityAgentNum';
  static const String lastCleaningAgentNumField = 'lastCleaningAgentNum';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _documentReference =>
      _firestore.collection(collectionName).doc(defaultDocumentId);

  Future<AgentBulkConfig> getConfig() async {
    final snapshot = await _documentReference.get();

    if (!snapshot.exists) {
      return const AgentBulkConfig();
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    return AgentBulkConfig.fromJson(data);
  }

  Future<void> ensureConfigExists() async {
    final snapshot = await _documentReference.get();

    if (!snapshot.exists) {
      await _documentReference.set(const AgentBulkConfig().toJson());
    }
  }

  Future<void> setLastSecurityAgentNum(int value) {
    return _documentReference.set(
      <String, dynamic>{lastSecurityAgentNumField: value},
      SetOptions(merge: true),
    );
  }

  Future<void> setLastCleaningAgentNum(int value) {
    return _documentReference.set(
      <String, dynamic>{lastCleaningAgentNumField: value},
      SetOptions(merge: true),
    );
  }

  Future<int> getLastNumberForDepartment(String departmentLabel) async {
    final config = await getConfig();
    return _fieldNameForDepartment(departmentLabel) == lastSecurityAgentNumField
        ? config.lastSecurityAgentNum
        : config.lastCleaningAgentNum;
  }

  Future<void> setLastNumberForDepartment(
    String departmentLabel,
    int value,
  ) async {
    final fieldName = _fieldNameForDepartment(departmentLabel);
    await _documentReference.set(
      <String, dynamic>{fieldName: value},
      SetOptions(merge: true),
    );
  }

  Future<AgentBulkAllocation> reserveRangeForDepartment({
    required String departmentLabel,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'La quantité doit être supérieure à 0.',
      );
    }

    final fieldName = _fieldNameForDepartment(departmentLabel);
    final allocation = await _firestore
        .runTransaction<AgentBulkAllocation>((transaction) async {
      final snapshot = await transaction.get(_documentReference);
      final data = snapshot.data() ?? <String, dynamic>{};

      final currentValue = _readPositiveInt(data[fieldName]);
      final startNumber = currentValue + 1;
      final endNumber = currentValue + quantity;

      transaction.set(
        _documentReference,
        <String, dynamic>{fieldName: endNumber},
        SetOptions(merge: true),
      );

      return AgentBulkAllocation(
        fieldName: fieldName,
        startNumber: startNumber,
        endNumber: endNumber,
      );
    });

    return allocation;
  }

  String getCodePrefixForDepartment(String departmentLabel) {
    return _fieldNameForDepartment(departmentLabel) == lastSecurityAgentNumField
        ? 'SEC'
        : 'NET';
  }

  String formatCode({
    required String departmentLabel,
    required int agentNumber,
    int minDigits = 6,
  }) {
    final prefix = getCodePrefixForDepartment(departmentLabel);
    final paddedNumber = agentNumber.toString().padLeft(minDigits, '0');
    return '$prefix$paddedNumber';
  }

  String _fieldNameForDepartment(String departmentLabel) {
    final normalized = departmentLabel.trim().toLowerCase();

    if (normalized.contains('net')) {
      return lastCleaningAgentNumField;
    }

    if (normalized.contains('sec')) {
      return lastSecurityAgentNumField;
    }

    throw ArgumentError(
      'Département non supporté pour la création bulk: $departmentLabel',
    );
  }

  int _readPositiveInt(dynamic value) {
    if (value is int && value >= 0) {
      return value;
    }

    if (value is num && value >= 0) {
      return value.toInt();
    }

    return 0;
  }
}

class AgentBulkConfig {
  const AgentBulkConfig({
    this.lastSecurityAgentNum = 0,
    this.lastCleaningAgentNum = 0,
  });

  final int lastSecurityAgentNum;
  final int lastCleaningAgentNum;

  factory AgentBulkConfig.fromJson(Map<String, dynamic> json) {
    return AgentBulkConfig(
      lastSecurityAgentNum: _parseInt(json['lastSecurityAgentNum']),
      lastCleaningAgentNum: _parseInt(json['lastCleaningAgentNum']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'lastSecurityAgentNum': lastSecurityAgentNum,
      'lastCleaningAgentNum': lastCleaningAgentNum,
    };
  }

  AgentBulkConfig copyWith({
    int? lastSecurityAgentNum,
    int? lastCleaningAgentNum,
  }) {
    return AgentBulkConfig(
      lastSecurityAgentNum: lastSecurityAgentNum ?? this.lastSecurityAgentNum,
      lastCleaningAgentNum: lastCleaningAgentNum ?? this.lastCleaningAgentNum,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int && value >= 0) {
      return value;
    }

    if (value is num && value >= 0) {
      return value.toInt();
    }

    return 0;
  }
}

class AgentBulkAllocation {
  const AgentBulkAllocation({
    required this.fieldName,
    required this.startNumber,
    required this.endNumber,
  });

  final String fieldName;
  final int startNumber;
  final int endNumber;

  int get quantity => (endNumber - startNumber) + 1;
}
