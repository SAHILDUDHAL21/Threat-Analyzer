package com.your.app

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileInputStream
import java.security.MessageDigest

class VirusScannerPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    
    // Known virus signatures (MD5 hashes)
    private val virusSignatures = setOf(
        "44d88612fea8a8f36de82e1278abb02f",  // EICAR test virus
        "e904f3d38f8523d330a0468158b21018",  // Sample virus signature
        "d41d8cd98f00b204e9800998ecf8427e"   // Empty file (suspicious)
    )

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.your.app/virus_scan")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initializeScanner" -> {
                result.success(true)
            }
            "scanFile" -> {
                val filePath = call.argument<String>("filePath")
                if (filePath == null) {
                    result.error("INVALID_ARGUMENT", "File path is required", null)
                    return
                }

                try {
                    val file = File(filePath)
                    if (!file.exists()) {
                        result.error("FILE_NOT_FOUND", "File does not exist", null)
                        return
                    }

                    val scanResult = scanFile(file)
                    result.success(mapOf(
                        "isInfected" to scanResult.first,
                        "threatName" to scanResult.second
                    ))
                } catch (e: Exception) {
                    result.error("SCAN_FAILED", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun scanFile(file: File): Pair<Boolean, String> {
        try {
            // Check file size
            if (file.length() == 0L) {
                return Pair(true, "Suspicious: Empty file")
            }

            // Calculate MD5 hash of file
            val md5 = calculateMD5(file)
            
            // Check against known virus signatures
            if (virusSignatures.contains(md5)) {
                return Pair(true, "Malware detected: Signature match")
            }

            // Check file content for suspicious patterns
            val content = file.readBytes().toString(Charsets.UTF_8)
            
            // Check for EICAR test virus string
            if (content.contains("X5O!P%@AP[4\\PZX54(P^)7CC)7}")) {
                return Pair(true, "Test Virus: EICAR")
            }

            // Check for suspicious patterns
            if (containsSuspiciousPatterns(content)) {
                return Pair(true, "Suspicious: Potentially harmful content")
            }

            return Pair(false, "Clean")
        } catch (e: Exception) {
            println("Error scanning file: ${e.message}")
            return Pair(false, "Scan error: ${e.message}")
        }
    }

    private fun calculateMD5(file: File): String {
        val md = MessageDigest.getInstance("MD5")
        val buffer = ByteArray(8192)
        FileInputStream(file).use { fis ->
            var bytesRead: Int
            while (fis.read(buffer).also { bytesRead = it } != -1) {
                md.update(buffer, 0, bytesRead)
            }
        }
        return md.digest().joinToString("") { "%02x".format(it) }
    }

    private fun containsSuspiciousPatterns(content: String): Boolean {
        val suspiciousPatterns = listOf(
            "#!/", // Shebang (script files)
            "eval(", // JavaScript eval
            "system(", // System commands
            "exec(", // Execute commands
            ".exe", // Executable files
            "powershell", // PowerShell commands
            "cmd.exe", // Command prompt
            "chmod +x", // Change executable permissions
            "rm -rf", // Dangerous delete command
            "format c:", // Format command
            "del /f", // Force delete
            "wget ", // Download commands
            "curl ", // Download commands
            "<script>", // Script tags
            "function()", // JavaScript functions
            ".vbs", // Visual Basic Script
            ".bat", // Batch files
            ".sh", // Shell scripts
            "sudo ", // Superuser commands
            "base64_decode" // Base64 decoded content
        )

        return suspiciousPatterns.any { pattern ->
            content.contains(pattern, ignoreCase = true)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
} 