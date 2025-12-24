package com.project.e_commerce.android.domain.usecase

import com.project.e_commerce.android.data.helper.FacebookSignInHelper
import com.project.e_commerce.android.domain.repository.AuthRepository
import javax.inject.Inject

class FacebookSignInUseCase @Inject constructor(
    private val facebookSignInHelper: FacebookSignInHelper,
    private val authRepository: AuthRepository
) {

    /**
     * Execute Facebook sign-in process
     * @return Result containing success or error message
     */
    suspend fun execute(): Result<String> {
        return try {
            // First, get Facebook access token
            val facebookResult = facebookSignInHelper.signIn()
            
            if (facebookResult.isSuccess) {
                val accessToken = facebookResult.getOrNull()
                if (accessToken != null) {
                    // Use the access token to authenticate with Firebase
                    val firebaseResult = authRepository.signInWithFacebook(accessToken)
                    
                    if (firebaseResult.isSuccess) {
                        Result.success("Facebook sign-in successful")
                    } else {
                        Result.failure(Exception("Firebase authentication failed: ${firebaseResult.exceptionOrNull()?.message}"))
                    }
                } else {
                    Result.failure(Exception("Failed to get Facebook access token"))
                }
            } else {
                Result.failure(facebookResult.exceptionOrNull() ?: Exception("Facebook sign-in failed"))
            }
        } catch (e: Exception) {
            Result.failure(Exception("Facebook sign-in error: ${e.message}"))
        }
    }

    /**
     * Check if user is already signed in to Facebook
     */
    fun isSignedIn(): Boolean {
        return facebookSignInHelper.isLoggedIn()
    }

    /**
     * Sign out from Facebook
     */
    fun signOut() {
        facebookSignInHelper.signOut()
    }
}