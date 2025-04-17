package uz.shs.better_player_plus

import android.annotation.SuppressLint
import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.HttpDataSource
import androidx.media3.datasource.cache.CacheWriter
import androidx.work.Data
import uz.shs.better_player_plus.DataSourceUtils.isHTTP
import uz.shs.better_player_plus.DataSourceUtils.getUserAgent
import uz.shs.better_player_plus.DataSourceUtils.getDataSourceFactory
import androidx.work.WorkerParameters
import androidx.work.Worker
import java.lang.Exception


/**
 * Cache worker which download part of video and save in cache for future usage. The cache job
 * will be executed in work manager.
 */
@SuppressLint("UnsafeOptInUsageError")
class CacheWorker(
    private val context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    private var cacheWriter: CacheWriter? = null
    private var lastCacheReportIndex = 0

    override fun doWork(): Result {
        return try {
            val data = inputData
            val url = data.getString(BetterPlayerPlugin.URL_PARAMETER) ?: throw IllegalArgumentException("URL is required")
            val cacheKey = data.getString(BetterPlayerPlugin.CACHE_KEY_PARAMETER)
            val preCacheSize = data.getLong(BetterPlayerPlugin.PRE_CACHE_SIZE_PARAMETER, 0)
            val maxCacheSize = data.getLong(BetterPlayerPlugin.MAX_CACHE_SIZE_PARAMETER, 0)
            val maxCacheFileSize = data.getLong(BetterPlayerPlugin.MAX_CACHE_FILE_SIZE_PARAMETER, 0)

            val headers = extractHeaders(data)

            val uri = Uri.parse(url)
            if (isHTTP(uri)) {
                val userAgent = getUserAgent(headers)
                val dataSourceFactory = getDataSourceFactory(userAgent, headers)

                var dataSpec = DataSpec(uri, 0, preCacheSize)
                if (!cacheKey.isNullOrEmpty()) {
                    dataSpec = dataSpec.buildUpon().setKey(cacheKey).build()
                }

                val cacheDataSourceFactory = CacheDataSourceFactory(
                    context,
                    maxCacheSize,
                    maxCacheFileSize,
                    dataSourceFactory
                )

                cacheWriter = CacheWriter(
                    cacheDataSourceFactory.createDataSource(),
                    dataSpec,
                    null
                ) { _, bytesCached, _ ->
                    val completedData = (bytesCached * 100f / preCacheSize).toDouble()
                    if (completedData >= lastCacheReportIndex * 10) {
                        lastCacheReportIndex += 1
                        Log.d(
                            TAG,
                            "Completed pre-cache of $url: ${completedData.toInt()}%"
                        )
                    }
                }

                cacheWriter?.cache()
            } else {
                Log.e(TAG, "Preloading is only possible for remote data sources")
                Result.failure()
            }
        } catch (exception: Exception) {
            Log.e(TAG, "Error during cache work: ${exception.localizedMessage}", exception)
            if (exception is HttpDataSource.HttpDataSourceException) {
                Result.success() // We consider the error handled as a successful result
            } else {
                Result.failure()
            }
        } as Result
    }

    override fun onStopped() {
        try {
            cacheWriter?.cancel()
            super.onStopped()
        } catch (exception: Exception) {
            Log.e(TAG, "Error stopping cache writer: ${exception.localizedMessage}", exception)
        }
    }

    private fun extractHeaders(data: Data): MutableMap<String, String> {
        val headers = mutableMapOf<String, String>()
        data.keyValueMap.keys
            .filter { it.contains(BetterPlayerPlugin.HEADER_PARAMETER) }
            .forEach { key ->
                val keySplit = key.split(BetterPlayerPlugin.HEADER_PARAMETER.toRegex())[0]
                data.keyValueMap[key]?.let { value ->
                    headers[keySplit] = value.toString()
                }
            }
        return headers
    }

    companion object {
        private const val TAG = "CacheWorker"
    }
}
