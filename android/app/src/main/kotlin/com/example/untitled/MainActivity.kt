package com.example.untitled

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val voiceRequestCode = 8142
    private var voiceResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "harvesthub/voice_search")
            .setMethodCallHandler { call, result ->
                if (call.method != "listen") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (voiceResult != null) {
                    result.error("already_listening", "Voice search is already open.", null)
                    return@setMethodCallHandler
                }
                if (!SpeechRecognizer.isRecognitionAvailable(this)) {
                    result.error("unavailable", "No speech recognition service is installed.", null)
                    return@setMethodCallHandler
                }
                voiceResult = result
                if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                    requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), voiceRequestCode)
                } else {
                    launchVoiceSearch()
                }
            }
    }

    private fun launchVoiceSearch() {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-PK")
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Say a product, category, or farmer name")
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
        }
        try {
            startActivityForResult(intent, voiceRequestCode)
        } catch (_: Exception) {
            voiceResult?.error("unavailable", "Voice search could not be opened on this device.", null)
            voiceResult = null
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != voiceRequestCode) return
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            launchVoiceSearch()
        } else {
            voiceResult?.error("permission_denied", "Allow microphone access to use voice search.", null)
            voiceResult = null
        }
    }

    @Deprecated("Deprecated by Android, retained for the speech recognition activity result")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != voiceRequestCode || voiceResult == null) return
        val result = voiceResult
        voiceResult = null
        if (resultCode == RESULT_OK) {
            val phrase = data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull()
            result?.success(phrase)
        } else if (resultCode == RESULT_CANCELED) {
            result?.success(null)
        } else {
            result?.error("recognition_failed", "Voice search did not complete.", null)
        }
    }
}
