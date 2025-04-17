package uz.shs.better_player_plus

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log

import androidx.media3.database.StandaloneDatabaseProvider
import androidx.media3.datasource.cache.LeastRecentlyUsedCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import java.io.File

@SuppressLint("UnsafeOptInUsageError")
object BetterPlayerCache {

    @Volatile
    private var instance: SimpleCache? = null

    fun createCache(context: Context, cacheFileSize: Long): SimpleCache? {
        return instance ?: synchronized(this) {
            instance ?: SimpleCache(
                File(context.cacheDir, "betterPlayerCache"),
                LeastRecentlyUsedCacheEvictor(cacheFileSize),
                StandaloneDatabaseProvider(context)
            ).also {
                instance = it
            }
        }
    }

    @JvmStatic
    fun releaseCache() {
        try {
            instance?.let {
                it.release()
                instance = null
            }
        } catch (exception: Exception) {
            Log.e("BetterPlayerCache", "Error releasing cache: ${exception.localizedMessage}", exception)
        }
    }
}
