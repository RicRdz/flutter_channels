package com.example.flutter_channels

import android.os.Handler
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Suppress("UNCHECKED_CAST")
class MainActivity: FlutterActivity() {

    private val sendFromFlutterToNativeChannelName = "sendFromFlutterToNativeChannel"
    private val sendFromNativeToFlutterChannelName = "sendFromNativeToFlutterChannel"
    private val counterReadingEventChannelName = "counterReadingEventChannel"

    private var eventSink : EventChannel.EventSink? = null
    private var job: Job? = null
    private var count = 1
    private suspend fun run() {
        val TOTAL_COUNT = 500
        while (count <= TOTAL_COUNT) {
            val percentage = count.toDouble() / TOTAL_COUNT
            eventSink?.success(percentage)
            count++
            delay(500)
        }
        eventSink?.endOfStream()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val sendFromFlutterToAndroidChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sendFromFlutterToNativeChannelName)
        sendFromFlutterToAndroidChannel.setMethodCallHandler { call, _ ->
            val args = call.arguments as Map<String, String>
            val message = args["message"]

            if (call.method == "showToastNative") {
                Toast.makeText(this, message, Toast.LENGTH_LONG).show()
            }
        }

        val sendFromAndroidToFlutterChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sendFromNativeToFlutterChannelName)
        sendFromAndroidToFlutterChannel.setMethodCallHandler { call, result ->
            if (call.method == "tellMeSomethingNative") {
                result.success("Hey Flutter, hello from native side")
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, counterReadingEventChannelName).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                count = 1
                job = CoroutineScope(Dispatchers.Main).launch {
                    run()
                }
            }

            override fun onCancel(arguments: Any?) {
                job?.cancel()
                job = null
                count = 1
                eventSink = null
            }
        })
    }
}
