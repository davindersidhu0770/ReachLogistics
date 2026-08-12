package com.example.reach_logistics_warehouse

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

/// Bridges Zebra DataWedge hardware-scanner output into Flutter.
///
/// DataWedge (running on the Zebra device) intercepts the physical trigger
/// button and, once a profile is configured for this app, broadcasts the
/// decoded barcode as an Intent with action [DATAWEDGE_ACTION]. This
/// receiver picks that broadcast up and forwards the scanned string to
/// Dart over [SCAN_EVENT_CHANNEL], where ZebraScanService exposes it as a
/// stream (see lib/services/zebra_scan_service.dart).
///
/// The matching DataWedge profile is created/updated automatically by
/// [configureDataWedgeProfile] via DataWedge's public config API, so no
/// manual per-device setup in the DataWedge app is required — this only
/// has any effect on Zebra devices where DataWedge is installed; elsewhere
/// the broadcasts are silently dropped.
class MainActivity : FlutterActivity() {
    companion object {
        private const val SCAN_EVENT_CHANNEL = "reach_logistics_warehouse/datawedge_scan"
        private const val DATAWEDGE_ACTION = "com.reachlogisticswarehouse.SCAN"
        private const val EXTRA_DATA_STRING = "com.symbol.datawedge.data_string"

        private const val DATAWEDGE_PACKAGE = "com.symbol.datawedge"
        private const val DATAWEDGE_API_ACTION = "com.symbol.datawedge.api.ACTION"
        private const val DATAWEDGE_API_SET_CONFIG = "com.symbol.datawedge.api.SET_CONFIG"
        private const val DATAWEDGE_PROFILE_NAME = "ReachLogisticsWarehouse"
    }

    private var eventSink: EventChannel.EventSink? = null
    private var scanReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        configureDataWedgeProfile()

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCAN_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerScanReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterScanReceiver()
                    eventSink = null
                }
            })
    }

    private fun registerScanReceiver() {
        if (scanReceiver != null) return

        scanReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                // TEMPORARY diagnostic log — remove once hardware scanning is confirmed
                // working. Check with: adb logcat -s ZebraScan
                Log.d("ZebraScan", "Broadcast received, action=${intent.action}, " +
                        "data_string=${intent.getStringExtra(EXTRA_DATA_STRING)}")
                val scannedData = intent.getStringExtra(EXTRA_DATA_STRING) ?: return
                runOnUiThread { eventSink?.success(scannedData) }
            }
        }

        Log.d("ZebraScan", "Registering receiver for action=$DATAWEDGE_ACTION")
        val filter = IntentFilter(DATAWEDGE_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // DataWedge lives in another app/process, so the receiver must be
            // explicitly exported on Android 13+ or the broadcast never arrives.
            registerReceiver(scanReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(scanReceiver, filter)
        }
    }

    /// Auto-provisions the DataWedge profile for this app so hardware trigger
    /// scans work with zero manual configuration in the DataWedge app.
    ///
    /// Sends three SET_CONFIG broadcasts to DataWedge's public config API
    /// (https://techdocs.zebra.com/datawedge/latest/guide/api/setconfig/):
    ///   1. Create the profile (if missing), associate it with this app, and
    ///      make sure the barcode scanner input is enabled.
    ///   2. Turn on Intent output so decoded barcodes are broadcast to
    ///      [DATAWEDGE_ACTION] for [registerScanReceiver] to pick up.
    ///   3. Turn off Keystroke output (DataWedge's default), which otherwise
    ///      swallows scans by typing into whatever field happens to be
    ///      focused — or nowhere at all, which is why the trigger appeared to
    ///      do nothing while the camera scanner worked fine.
    private fun configureDataWedgeProfile() {
        val barcodeParams = Bundle().apply {
            putString("scanner_input_enabled", "true")
            putString("scanner_selection", "auto")
        }
        sendDataWedgeSetConfig("BARCODE", resetConfig = false, params = barcodeParams, includeAppList = true)

        val intentParams = Bundle().apply {
            putString("intent_output_enabled", "true")
            putString("intent_action", DATAWEDGE_ACTION)
            putString("intent_delivery", "2") // 0 = Activity, 1 = Service, 2 = Broadcast
        }
        sendDataWedgeSetConfig("INTENT", resetConfig = true, params = intentParams)

        val keystrokeParams = Bundle().apply {
            putString("keystroke_output_enabled", "false")
        }
        sendDataWedgeSetConfig("KEYSTROKE", resetConfig = true, params = keystrokeParams)
    }

    private fun sendDataWedgeSetConfig(
        pluginName: String,
        resetConfig: Boolean,
        params: Bundle,
        includeAppList: Boolean = false,
    ) {
        val pluginConfig = Bundle().apply {
            putString("PLUGIN_NAME", pluginName)
            putString("RESET_CONFIG", resetConfig.toString())
            putBundle("PARAM_LIST", params)
        }

        val profileConfig = Bundle().apply {
            putString("PROFILE_NAME", DATAWEDGE_PROFILE_NAME)
            putString("PROFILE_ENABLED", "true")
            // UPDATE (not CREATE_IF_NOT_EXIST) so this re-applies every launch — once
            // the profile exists, CREATE_IF_NOT_EXIST silently no-ops on every field,
            // including APP_LIST, which is why the app association never stuck
            // automatically and had to be added by hand in DataWedge the first time.
            putString("CONFIG_MODE", "UPDATE")
            putBundle("PLUGIN_CONFIG", pluginConfig)
            if (includeAppList) {
                val appConfig = Bundle().apply {
                    putString("PACKAGE_NAME", packageName)
                    putStringArray("ACTIVITY_LIST", arrayOf("*"))
                }
                putParcelableArrayList("APP_LIST", arrayListOf(appConfig))
            }
        }

        val intent = Intent(DATAWEDGE_API_ACTION).apply {
            setPackage(DATAWEDGE_PACKAGE)
            putExtra(DATAWEDGE_API_SET_CONFIG, profileConfig)
        }
        runCatching { sendBroadcast(intent) }
            .onSuccess { Log.d("ZebraScan", "Sent DataWedge SET_CONFIG for $pluginName") }
            .onFailure { Log.w("ZebraScan", "Failed to send DataWedge SET_CONFIG for $pluginName", it) }
    }

    private fun unregisterScanReceiver() {
        scanReceiver?.let {
            runCatching { unregisterReceiver(it) }
            scanReceiver = null
        }
    }

    override fun onDestroy() {
        unregisterScanReceiver()
        super.onDestroy()
    }
}
