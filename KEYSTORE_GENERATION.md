# Android Release Keystore Generation Guide

## Overview
This guide will help you create a production-ready keystore for signing your RecallSentry Android app for Google Play Store release.

**IMPORTANT:** The keystore file and its passwords are critical security assets. If you lose them, you will NEVER be able to update your app on Google Play Store. Store them securely!

---

## Prerequisites
- Java JDK installed (comes with Android Studio)
- Command-line access (Terminal/Command Prompt/PowerShell)

---

## Step 1: Generate the Keystore

### On Windows (PowerShell or Command Prompt):
```powershell
keytool -genkey -v -keystore C:\secure\recallsentry-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias recallsentry-key
```

### On macOS/Linux (Terminal):
```bash
keytool -genkey -v -keystore ~/secure/recallsentry-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias recallsentry-key
```

### Parameters Explained:
- `-keystore`: Path where the keystore will be saved
- `-keyalg RSA`: Use RSA encryption algorithm
- `-keysize 2048`: 2048-bit key (Google Play requirement)
- `-validity 10000`: Valid for 10,000 days (~27 years)
- `-alias recallsentry-key`: Alias to reference this key

---

## Step 2: Answer the Prompts

You'll be prompted for information. Example:

```
Enter keystore password: [Create a STRONG password]
Re-enter new password: [Confirm password]

What is your first and last name?
  [Unknown]: John Smith
What is the name of your organizational unit?
  [Unknown]: Development
What is the name of your organization?
  [Unknown]: Center for Recall Safety
What is the name of your City or Locality?
  [Unknown]: Your City
What is the name of your State or Province?
  [Unknown]: Your State
What is the two-letter country code for this unit?
  [Unknown]: US

Is CN=John Smith, OU=Development, O=Center for Recall Safety, L=Your City, ST=Your State, C=US correct?
  [no]: yes

Enter key password for <recallsentry-key>
  (RETURN if same as keystore password): [Press ENTER or create different password]
```

---

## Step 3: Create key.properties File

1. Navigate to the `android/` directory in your project:
   ```bash
   cd rs_flutter/android
   ```

2. Copy the template file:
   ```bash
   cp key.properties.template key.properties
   ```

3. Open `key.properties` in a text editor and fill in your values:

   ```properties
   storeFile=C:/secure/recallsentry-release.jks
   storePassword=YOUR_ACTUAL_STORE_PASSWORD
   keyAlias=recallsentry-key
   keyPassword=YOUR_ACTUAL_KEY_PASSWORD
   ```

   **Important:**
   - Use forward slashes (/) in paths, even on Windows
   - Or use relative path: `../recallsentry-release.jks` if stored outside android folder
   - Replace `YOUR_ACTUAL_*` with the passwords you created in Step 2

---

## Step 4: Secure Your Keystore

### Critical Security Measures:

1. **Backup the Keystore:**
   - Store the `.jks` file in a secure location (encrypted cloud storage, password manager)
   - Create multiple backups in different locations
   - Consider using a hardware security key or encrypted USB drive

2. **Document Passwords:**
   - Store passwords in a secure password manager (1Password, LastPass, Bitwarden)
   - NEVER commit passwords to version control
   - Share with team members only through secure channels (encrypted)

3. **Verify .gitignore:**
   - The following files should NEVER be committed:
     - `key.properties` ✅ Already in .gitignore
     - `*.jks` ✅ Already in .gitignore
     - `*.keystore` ✅ Already in .gitignore

4. **Access Control:**
   - Limit access to keystore to authorized team members only
   - Use different keystores for different environments if needed

---

## Step 5: Verify Configuration

1. **Check that key.properties exists:**
   ```bash
   ls android/key.properties
   ```

2. **Verify the keystore was created:**
   - Windows: `dir C:\secure\recallsentry-release.jks`
   - macOS/Linux: `ls ~/secure/recallsentry-release.jks`

3. **Test the configuration:**
   ```bash
   flutter build apk --release
   ```

   You should see output like:
   ```
   ✓ Built build/app/outputs/flutter-apk/app-release.apk (XX MB)
   ```

4. **Verify the APK is signed:**
   ```bash
   # On Windows
   cd rs_flutter\build\app\outputs\flutter-apk

   # On macOS/Linux
   cd rs_flutter/build/app/outputs/flutter-apk

   # Check signature (requires Java JDK)
   jarsigner -verify -verbose -certs app-release.apk
   ```

   Look for: `jar verified.` in the output

---

## Step 6: Build for Production

### Build APK (for testing):
```bash
flutter build apk --release
```

### Build App Bundle (for Play Store submission):
```bash
flutter build appbundle --release
```

The App Bundle will be located at:
- `build/app/outputs/bundle/release/app-release.aab`

---

## Troubleshooting

### Error: "keystore password was incorrect"
- Double-check your password in `key.properties`
- Ensure no extra spaces or special characters were added by mistake
- Try regenerating the keystore if password is lost (but you'll need a new app listing)

### Error: "key.properties not found"
- Ensure `key.properties` is in the `android/` directory
- Check that you copied from `key.properties.template` correctly

### Warning: "Using debug signing"
- This means `key.properties` wasn't found
- The app will build but won't be suitable for Play Store submission
- Follow Step 3 to create the file

### Error: "storeFile not found"
- Check the path in `key.properties` is correct
- Use absolute path or correct relative path
- Use forward slashes (/) even on Windows

---

## What If I Lose the Keystore?

**CRITICAL:** If you lose your keystore after publishing to Google Play Store:

1. You **CANNOT** update your existing app
2. You must create a new app listing with a new package name
3. Users will have to uninstall the old app and install the new one
4. You'll lose all reviews, ratings, and download statistics

**This is why backup and security are critical!**

---

## For CI/CD (GitHub Actions, etc.)

If you want to automate builds:

1. **Encrypt the keystore:**
   ```bash
   gpg -c --armor recallsentry-release.jks
   ```

2. **Store in CI/CD secrets:**
   - Store base64-encoded keystore as secret
   - Store passwords as separate secrets
   - Decode during build process

3. **Example GitHub Actions secret setup:**
   - `KEYSTORE_BASE64`: Base64-encoded keystore file
   - `KEYSTORE_PASSWORD`: Store password
   - `KEY_ALIAS`: recallsentry-key
   - `KEY_PASSWORD`: Key password

---

## Best Practices

1. ✅ Use strong, unique passwords (20+ characters, mixed case, numbers, symbols)
2. ✅ Store keystore outside your project directory
3. ✅ Create multiple backups immediately after generation
4. ✅ Document all passwords in a secure password manager
5. ✅ Test the keystore before Play Store submission
6. ✅ Set calendar reminder to backup keystore quarterly
7. ✅ Use different keystores for internal testing vs production
8. ❌ NEVER commit keystore or passwords to Git
9. ❌ NEVER share keystore via email or unsecured channels
10. ❌ NEVER use weak or guessable passwords

---

## Quick Reference

**Generate keystore:**
```bash
keytool -genkey -v -keystore recallsentry-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias recallsentry-key
```

**Build release APK:**
```bash
flutter build apk --release
```

**Build release App Bundle:**
```bash
flutter build appbundle --release
```

**Verify signature:**
```bash
jarsigner -verify -verbose -certs app-release.apk
```

---

## Support

If you encounter issues:
1. Check Flutter documentation: https://docs.flutter.dev/deployment/android
2. Check Android signing docs: https://developer.android.com/studio/publish/app-signing
3. Review this guide's Troubleshooting section
4. Contact your development team lead

---

**Remember: Your keystore is the key to your app's identity on Google Play Store. Protect it like you would protect your bank account credentials!**
