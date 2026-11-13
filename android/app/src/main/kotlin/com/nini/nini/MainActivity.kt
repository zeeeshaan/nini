package com.nini.nini

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.nini.nini.media.DocumentCompressionChannel

class MainActivity : FlutterActivity() {
    private var documentCompression: DocumentCompressionChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        documentCompression = DocumentCompressionChannel(
            flutterEngine.dartExecutor.binaryMessenger, applicationContext
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        documentCompression?.dispose()
        documentCompression = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
