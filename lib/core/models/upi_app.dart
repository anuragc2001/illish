import 'dart:typed_data';

class UpiApp {
  final String name;
  final String packageName;
  final Uint8List? icon;
  final String? assetIcon;

  UpiApp({
    required this.name,
    required this.packageName,
    this.icon,
    this.assetIcon,
  });

  factory UpiApp.fromMap(Map<String, dynamic> map) {
    return UpiApp(
      name: map['name'] as String,
      packageName: map['packageName'] as String,
      icon: map['icon'] as Uint8List?,
      assetIcon: map['assetIcon'] as String?,
    );
  }
}

class UpiResponse {
  final String status;
  final String? txnId;
  final String? txnRef;
  final String? rawResponse;

  UpiResponse({
    required this.status,
    this.txnId,
    this.txnRef,
    this.rawResponse,
  });

  bool get isSuccess => status.toUpperCase() == 'SUCCESS' || status.toUpperCase() == '00';
  bool get isFailed => status.toUpperCase() == 'FAILURE';
  bool get isSubmitted => status.toUpperCase() == 'SUBMITTED';

  factory UpiResponse.fromMap(Map<String, dynamic> map) {
    return UpiResponse(
      status: (map['Status'] ?? map['status'] ?? 'UNKNOWN').toString(),
      txnId: map['txnId']?.toString(),
      txnRef: map['txnRef']?.toString(),
      rawResponse: map.toString(),
    );
  }
}
