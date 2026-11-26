package com.hywork.hywork.media

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class DocumentCompressionChannel(messenger: BinaryMessenger, private val context: Context) :
    MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "hywork/document_compression")
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init { channel.setMethodCallHandler(this) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "compressPdf") {
            result.notImplemented()
            return
        }
        val source = call.argument<String>("source")
        val target = call.argument<String>("target")
        if (source == null || target == null) {
            result.error("invalid_arguments", "Missing PDF paths", null)
            return
        }
        worker.execute {
            try {
                val compressed = PdfDocumentCompressor.compress(context, File(source), File(target))
                main.post { result.success(compressed) }
            } catch (error: Exception) {
                main.post { result.error("pdf_compression_failed", error.message, null) }
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        worker.shutdown()
    }
}
