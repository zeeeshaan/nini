package com.nini.nini

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.nini.nini.media.DocumentCompressionChannel
import android.util.AtomicFile
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID

class MainActivity : FlutterActivity() {
    private var documentCompression: DocumentCompressionChannel? = null
    private var installationChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        documentCompression = DocumentCompressionChannel(
            flutterEngine.dartExecutor.binaryMessenger, applicationContext
        )
        installationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, "hywork/installation"
        ).apply {
            setMethodCallHandler { call, result ->
                if (call.method != "getInstallationId") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    result.success(installationId())
                } catch (_: Exception) {
                    result.error("installation_unavailable", "Could not read installation identity.", null)
                }
            }
        }
    }

    private fun installationId(): String {
        val marker = AtomicFile(File(noBackupFilesDir, "hywork_auth_installation"))
        if (marker.baseFile.exists()) {
            return String(marker.readFully(), Charsets.UTF_8).trim().also {
                UUID.fromString(it)
            }
        }
        val id = UUID.randomUUID().toString()
        val stream = marker.startWrite()
        try {
            stream.write(id.toByteArray(Charsets.UTF_8))
            marker.finishWrite(stream)
        } catch (error: Exception) {
            marker.failWrite(stream)
            throw error
        }
        return id
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        installationChannel?.setMethodCallHandler(null)
        installationChannel = null
        documentCompression?.dispose()
        documentCompression = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
