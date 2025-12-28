# Stripe Android SDK - Keep rules
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# Ignore missing Push Provisioning classes (optional feature)
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
