package uz.shs.better_player_plus

import android.annotation.SuppressLint
import android.net.Uri
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultHttpDataSource

@SuppressLint("UnsafeOptInUsageError")
internal object DataSourceUtils {
    private const val USER_AGENT = "User-Agent"
    private const val USER_AGENT_PROPERTY = "http.agent"

    @JvmStatic
    fun getUserAgent(headers: Map<String, String>?): String {
        return headers?.get(USER_AGENT) ?: System.getProperty(USER_AGENT_PROPERTY) ?: "DefaultUserAgent"
    }

    @JvmStatic
    fun getDataSourceFactory(userAgent: String?, headers: Map<String, String>?): DataSource.Factory {
        // Initialize DefaultHttpDataSource.Factory with user agent and defaults
        val dataSourceFactory = DefaultHttpDataSource.Factory()
            .setUserAgent(userAgent)
            .setAllowCrossProtocolRedirects(true)
            .setConnectTimeoutMs(DefaultHttpDataSource.DEFAULT_CONNECT_TIMEOUT_MILLIS)
            .setReadTimeoutMs(DefaultHttpDataSource.DEFAULT_READ_TIMEOUT_MILLIS)

        // Set request headers if provided
        headers?.let {
            dataSourceFactory.setDefaultRequestProperties(it)
        }

        return dataSourceFactory
    }

    @JvmStatic
    fun isHTTP(uri: Uri?): Boolean {
        return uri?.scheme in listOf("http", "https")
    }
}
