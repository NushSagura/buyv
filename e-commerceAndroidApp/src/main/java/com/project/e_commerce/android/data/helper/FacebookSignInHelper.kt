package com.project.e_commerce.android.data.helper

import android.content.Context
import android.util.Log
import com.facebook.AccessToken
import com.facebook.CallbackManager
import com.facebook.FacebookCallback
import com.facebook.FacebookException
import com.facebook.login.LoginManager
import com.facebook.login.LoginResult
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class FacebookSignInHelper(private val context: Context) {

    companion object {
        private const val TAG = "FacebookSignInHelper"
    }

    private val callbackManager: CallbackManager = CallbackManager.Factory.create()
    private val loginManager: LoginManager = LoginManager.getInstance()

    /**
     * Check if user is already logged in to Facebook
     */
    fun isLoggedIn(): Boolean {
        val accessToken = AccessToken.getCurrentAccessToken()
        return accessToken != null && !accessToken.isExpired
    }

    /**
     * Get current access token
     */
    fun getCurrentAccessToken(): AccessToken? {
        return AccessToken.getCurrentAccessToken()
    }

    /**
     * Sign in with Facebook
     * @return Result containing the access token or error
     */
    suspend fun signIn(): Result<String> = suspendCancellableCoroutine { continuation ->
        try {
            // Check if already logged in
            val currentToken = AccessToken.getCurrentAccessToken()
            if (currentToken != null && !currentToken.isExpired) {
                Log.d(TAG, "User already logged in to Facebook")
                continuation.resume(Result.success(currentToken.token))
                return@suspendCancellableCoroutine
            }

            // Register callback
            loginManager.registerCallback(callbackManager, object : FacebookCallback<LoginResult> {
                override fun onSuccess(result: LoginResult) {
                    Log.d(TAG, "Facebook login successful")
                    val accessToken = result.accessToken
                    if (accessToken != null) {
                        continuation.resume(Result.success(accessToken.token))
                    } else {
                        continuation.resumeWithException(Exception("Failed to get access token from Facebook"))
                    }
                }

                override fun onCancel() {
                    Log.d(TAG, "Facebook login cancelled by user")
                    continuation.resumeWithException(Exception("Facebook login was cancelled by user"))
                }

                override fun onError(error: FacebookException) {
                    Log.e(TAG, "Facebook login error: ${error.message}")
                    continuation.resumeWithException(Exception("Facebook login failed: ${error.message}"))
                }
            })

            // Start login with required permissions
            loginManager.logInWithReadPermissions(
                context as androidx.fragment.app.FragmentActivity,
                listOf("email", "public_profile")
            )

        } catch (e: Exception) {
            Log.e(TAG, "Facebook sign-in setup failed: ${e.message}")
            continuation.resumeWithException(e)
        }
    }

    /**
     * Sign out from Facebook
     */
    fun signOut() {
        try {
            loginManager.logOut()
            Log.d(TAG, "Facebook sign-out completed")
        } catch (e: Exception) {
            Log.e(TAG, "Facebook sign-out failed: ${e.message}")
        }
    }

    /**
     * Get callback manager for handling Facebook login results
     */
    fun getCallbackManager(): CallbackManager {
        return callbackManager
    }

    /**
     * Handle activity result (should be called from Activity.onActivityResult)
     */
    fun handleActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?): Boolean {
        return callbackManager.onActivityResult(requestCode, resultCode, data)
    }
}