package com.nini.nini.media

import android.content.Context
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.cos.COSName
import com.tom_roush.pdfbox.cos.COSStream
import com.tom_roush.pdfbox.io.MemoryUsageSetting
import com.tom_roush.pdfbox.pdmodel.PDDocument
import java.io.File

object PdfDocumentCompressor {
    fun compress(context: Context, source: File, target: File): Boolean {
        if (source.canonicalPath == target.canonicalPath) return false
        PDFBoxResourceLoader.init(context)
        PDDocument.load(source, MemoryUsageSetting.setupTempFileOnly()).use { document ->
            if (document.isEncrypted || document.signatureDictionaries.isNotEmpty()) return false
            val pages = document.numberOfPages
            if (pages == 0) return false
            for (entry in document.document.objects) {
                val stream = entry.`object` as? COSStream ?: continue
                // Deflate uncompressed streams; keep already encoded images and fonts.
                if (stream.filters != null || stream.length > 32 * 1024 * 1024) continue
                val content = stream.createInputStream().use { it.readBytes() }
                stream.createOutputStream(COSName.FLATE_DECODE).use { it.write(content) }
            }
            document.save(target)
            PDDocument.load(target, MemoryUsageSetting.setupTempFileOnly()).use { verified ->
                if (verified.numberOfPages == pages) return true
            }
        }
        target.delete()
        return false
    }
}
