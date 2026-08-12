import 'package:flutter/services.dart';

/// Streams barcodes scanned via the Zebra device's hardware trigger
/// (top scan button), delivered by DataWedge as a broadcast Intent and
/// forwarded to Dart by the native side (see MainActivity.kt).
///
/// This is independent of camera-based scanning (mobile_scanner) — screens
/// should listen to both and feed matches into the same `_handleScan`.
///
/// Requires a DataWedge profile on the device configured for this app:
///   - Associated app: com.example.reach_logistics_warehouse (this app)
///   - Barcode input: enabled
///   - Intent output: enabled
///     - Intent action: com.reachlogisticswarehouse.SCAN
///     - Intent delivery: Broadcast intent
/// On devices without DataWedge (non-Zebra), this stream simply never emits.
class ZebraScanService {
  ZebraScanService._internal();
  static final ZebraScanService instance = ZebraScanService._internal();
  factory ZebraScanService() => instance;

  static const _channel = EventChannel('reach_logistics_warehouse/datawedge_scan');

  Stream<String>? _scans;

  /// Broadcast stream of scanned barcode strings. Safe to listen to from
  /// multiple screens; a no-op on platforms without the native channel
  /// (iOS, desktop, web).
  Stream<String> get onScan {
    return _scans ??= _channel
        .receiveBroadcastStream()
        .map((event) => event.toString())
        .handleError((_) {}) // ignore platform errors (e.g. unsupported platform)
        .asBroadcastStream();
  }
}