package uz.shs.better_player_plus

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Log
import androidx.work.Data
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

import java.io.FileOutputStream
import java.io.InputStream
import java.lang.Exception
import java.net.HttpURLConnection
import java.net.URL

class ImageWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            val imageUrl = inputData.getString(BetterPlayerPlugin.URL_PARAMETER)
                ?: return Result.failure()

            val bitmap: Bitmap? = if (DataSourceUtils.isHTTP(Uri.parse(imageUrl))) {
                getBitmapFromExternalURL(imageUrl)
            } else {
                getBitmapFromInternalURL(imageUrl)
            }

            val fileName = imageUrl.hashCode().toString() + IMAGE_EXTENSION
            val filePath = applicationContext.cacheDir.absolutePath + "/" + fileName

            if (bitmap == null) {
                return Result.failure()
            }

            // Save bitmap to file
            val out = FileOutputStream(filePath)
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            out.close()

            val data = Data.Builder().putString(BetterPlayerPlugin.FILE_PATH_PARAMETER, filePath).build()
            Result.success(data)
        } catch (e: Exception) {
            Log.e(TAG, "Error during image processing", e)
            Result.failure()
        }
    }

    private fun getBitmapFromExternalURL(src: String): Bitmap? {
        var inputStream: InputStream? = null
        return try {
            val url = URL(src)
            var connection = url.openConnection() as HttpURLConnection
            inputStream = connection.inputStream

            val options = BitmapFactory.Options()
            options.inJustDecodeBounds = true
            BitmapFactory.decodeStream(inputStream, null, options)
            inputStream.close()

            // Reset the connection and stream to load the actual bitmap
            connection = url.openConnection() as HttpURLConnection
            inputStream = connection.inputStream

            options.inSampleSize = calculateBitmapInSampleSize(options)
            options.inJustDecodeBounds = false

            BitmapFactory.decodeStream(inputStream, null, options)
        } catch (exception: Exception) {
            Log.e(TAG, "Failed to get bitmap from external URL: $src", exception)
            null
        } finally {
            inputStream?.close()
        }
    }

    private fun getBitmapFromInternalURL(src: String): Bitmap? {
        return try {
            val options = BitmapFactory.Options()
            options.inJustDecodeBounds = true
            options.inSampleSize = calculateBitmapInSampleSize(options)
            options.inJustDecodeBounds = false

            BitmapFactory.decodeFile(src)
        } catch (exception: Exception) {
            Log.e(TAG, "Failed to get bitmap from internal URL: $src", exception)
            null
        }
    }

    private fun calculateBitmapInSampleSize(options: BitmapFactory.Options): Int {
        val height = options.outHeight
        val width = options.outWidth
        var inSampleSize = 1

        if (height > DEFAULT_NOTIFICATION_IMAGE_SIZE_PX || width > DEFAULT_NOTIFICATION_IMAGE_SIZE_PX) {
            val halfHeight = height / 2
            val halfWidth = width / 2
            while (halfHeight / inSampleSize >= DEFAULT_NOTIFICATION_IMAGE_SIZE_PX &&
                halfWidth / inSampleSize >= DEFAULT_NOTIFICATION_IMAGE_SIZE_PX) {
                inSampleSize *= 2
            }
        }

        return inSampleSize
    }

    companion object {
        private const val TAG = "ImageWorker"
        private const val IMAGE_EXTENSION = ".png"
        private const val DEFAULT_NOTIFICATION_IMAGE_SIZE_PX = 256
    }
}
