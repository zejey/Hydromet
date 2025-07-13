// ApiService.kt
import retrofit2.Response
import retrofit2.http.Header
import retrofit2.http.POST
import retrofit2.http.Body
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import java.util.concurrent.TimeUnit

interface ApiService {
    
    @POST("auth/verify-phone")
    suspend fun verifyPhone(
        @Header("Authorization") token: String
    ): Response<VerifyPhoneResponse>
    
    @POST("auth/register")
    suspend fun registerUser(
        @Header("Authorization") token: String,
        @Body request: RegisterRequest
    ): Response<RegisterResponse>
    
    companion object {
        fun create(): ApiService {
            // Create logging interceptor
            val loggingInterceptor = HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BODY
            }
            
            // Create OkHttp client with logging
            val client = OkHttpClient.Builder()
                .addInterceptor(loggingInterceptor)
                .connectTimeout(30, TimeUnit.SECONDS)
                .readTimeout(30, TimeUnit.SECONDS)
                .writeTimeout(30, TimeUnit.SECONDS)
                .build()
            
            return Retrofit.Builder()
                // .baseUrl("http://10.0.2.2:5000/") // For Android emulator
                .baseUrl("http://192.168.1.255:5000/") // For physical device, replace YOUR_LOCAL_IP with your computer's IP
                .client(client)
                .addConverterFactory(GsonConverterFactory.create())
                .build()
                .create(ApiService::class.java)
        }
    }
}

// Data classes
data class VerifyPhoneResponse(
    val message: String,
    val user: User?,
    val isNewUser: Boolean,
    val requiresRegistration: Boolean = false
)

data class RegisterRequest(
    val firstName: String,
    val lastName: String,
    val address: String,
    val barangay: String,
    val email: String?
)

data class RegisterResponse(
    val message: String,
    val user: User
)

data class User(
    val id: String,
    val firebaseUid: String,
    val fullName: String,
    val phone: String,
    val address: String,
    val barangay: String,
    val email: String?
)
