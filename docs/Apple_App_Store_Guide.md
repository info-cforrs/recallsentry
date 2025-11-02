# RecallSentry: Apple App Store Deployment Guide

## Overview
This comprehensive guide covers the entire process of creating an Apple Developer account, preparing your Flutter app, and publishing it to the Apple App Store.

---

## Table of Contents
1. [Apple Developer Account Setup](#part-1-apple-developer-account-setup)
2. [App Store Connect Configuration](#part-2-app-store-connect-configuration)
3. [Xcode Project Configuration](#part-3-xcode-project-configuration)
4. [App Store Assets Preparation](#part-4-app-store-assets-preparation)
5. [Build and Archive](#part-5-build-and-archive)
6. [App Store Submission](#part-6-app-store-submission)
7. [Review Process](#part-7-review-process)

---

## Part 1: Apple Developer Account Setup

### Step 1: Enroll in Apple Developer Program
**Cost: $99 USD per year**

1. Visit the **Apple Developer Program** enrollment page:
   - URL: https://developer.apple.com/programs/enroll/

2. Click **Start Your Enrollment**

3. Sign in with your **Apple ID**
   - Use a business/professional Apple ID (recommended)
   - If you don't have one, create a new Apple ID first

4. Complete the enrollment form:
   - **Entity Type:**
     - Select **Individual** if registering as yourself
     - Select **Organization** if registering as a company (requires D-U-N-S number)

   - **Contact Information:**
     - Legal name (must match government ID)
     - Address
     - Phone number
     - Date of birth

5. Review the **Apple Developer Program License Agreement**
   - Read carefully
   - Click **Agree** to continue

6. Complete purchase:
   - Payment method: Credit/Debit card or Apple Pay
   - Cost: $99 USD (annual subscription)
   - Click **Purchase**

7. Wait for confirmation:
   - You'll receive an email confirmation
   - Account activation can take **24-48 hours** (sometimes instant)
   - You'll receive another email when account is activated

### Step 2: Verify Developer Account Status
1. Visit: https://developer.apple.com/account
2. Sign in with your Apple ID
3. Verify you see:
   - **Membership Status: Active**
   - **Program: Apple Developer Program**
   - **Membership Type: Individual** (or Organization)

---

## Part 2: App Store Connect Configuration

### Step 3: Access App Store Connect
1. Visit: https://appstoreconnect.apple.com
2. Sign in with your Apple Developer Apple ID
3. You'll see the App Store Connect dashboard

### Step 4: Register Your App Bundle Identifier
1. Go to **Certificates, Identifiers & Profiles**:
   - Click your name in top-right corner
   - Select **Certificates, IDs & Profiles**

2. Click **Identifiers** in the left sidebar

3. Click the **+** button (or **Register an App ID**)

4. Select **App IDs** → Click **Continue**

5. Select **App** → Click **Continue**

6. Configure App ID:
   - **Description:** RecallSentry (or your app name)
   - **Bundle ID:** Select **Explicit**
   - **Bundle ID:** `com.yourname.recallsentry`
     - Must be unique across all apps in App Store
     - Use reverse domain notation
     - Examples: `com.johnsmith.recallsentry`, `com.acme.recallsentry`
     - ⚠️ **IMPORTANT:** Write this down! You'll need it later

7. **Capabilities:** Check any needed capabilities:
   - ✅ Push Notifications (if you plan to add push notifications)
   - ✅ Background Modes (if needed)
   - ✅ Sign in with Apple (if implementing Apple authentication)
   - For RecallSentry, default capabilities should be sufficient

8. Click **Continue** → Click **Register**

### Step 5: Create App in App Store Connect
1. Return to App Store Connect: https://appstoreconnect.apple.com

2. Click **My Apps**

3. Click the **+** button in top-left corner

4. Select **New App**

5. Fill in the **New App** form:

   **Platforms:**
   - ✅ Check **iOS**

   **Name:**
   - Enter: **RecallSentry** (or your app name)
   - Must be unique in App Store (you'll get an error if taken)
   - Maximum 30 characters

   **Primary Language:**
   - Select: **English (U.S.)**

   **Bundle ID:**
   - Select the Bundle ID you created in Step 4
   - Should show: `com.yourname.recallsentry`

   **SKU:**
   - Enter a unique identifier for your app (internal use only)
   - Example: `RECALLSENTRY001`
   - Can be any alphanumeric string
   - This is NOT visible to users

   **User Access:**
   - Select **Full Access** (default)

6. Click **Create**

### Step 6: Complete App Information
After creating the app, you'll be taken to the app's dashboard.

#### 6.1: App Information Tab
1. Click **App Information** in the left sidebar

2. Fill in required fields:

   **Subtitle** (optional, 30 characters max):
   - Example: "FDA & USDA Recall Alerts"

   **Category:**
   - **Primary Category:** Health & Fitness (or Food & Drink)
   - **Secondary Category (optional):** Lifestyle

   **Content Rights:**
   - If your app contains third-party content, check the box

   **Age Rating:**
   - Click **Edit** next to Age Rating
   - Answer the questionnaire honestly:
     - Medical/Treatment Information: None (unless you provide medical advice)
     - Unrestricted Web Access: No
     - Gambling: No
     - Violence: No
     - Mature/Suggestive Themes: No
   - Click **Done**
   - Your rating will likely be **4+** (all ages)

3. Click **Save**

#### 6.2: Pricing and Availability
1. Click **Pricing and Availability** in the left sidebar

2. Configure pricing:
   - **Price:** Select **Free** (or choose a paid tier)
   - For RecallSentry, recommend starting with **Free**

3. **Availability:**
   - Select **All territories** or choose specific countries
   - For maximum reach, select **All territories**

4. **App Distribution:**
   - Check **Public** (available to everyone)
   - Or select **Private** if you want to limit distribution

5. Click **Save**

---

## Part 3: Xcode Project Configuration

### Step 7: Update Flutter Project Configuration

#### 7.1: Update pubspec.yaml
1. On your **MacBook**, open the project in a text editor:
   ```bash
   cd ~/path/to/rs_flutter
   open pubspec.yaml
   ```

2. Verify/update version number:
   ```yaml
   version: 1.0.0+1
   ```
   - Format: `MAJOR.MINOR.PATCH+BUILDNUMBER`
   - Example: `1.0.0+1` means version 1.0.0, build 1
   - Increment build number for each submission

3. Verify app name:
   ```yaml
   name: rs_flutter
   description: RecallSentry - FDA & USDA Recall Tracking App
   ```

#### 7.2: Configure iOS Deployment Settings
1. Open Xcode project:
   ```bash
   cd ~/path/to/rs_flutter
   open ios/Runner.xcworkspace
   ```

2. Select **Runner** in the project navigator (left sidebar)

3. Select **Runner** target under TARGETS

4. **General Tab:**
   - **Display Name:** RecallSentry
   - **Bundle Identifier:** `com.yourname.recallsentry` (must match App Store Connect)
   - **Version:** 1.0.0
   - **Build:** 1
   - **Deployment Target:** iOS 12.0 (or minimum version you want to support)

5. **Signing & Capabilities Tab:**
   - **Team:** Select your Apple Developer Team
   - **Automatically manage signing:** ✅ Checked
   - **Bundle Identifier:** Verify it matches App Store Connect
   - **Provisioning Profile:** Xcode will automatically select

6. Verify no signing errors appear at the top of the window

#### 7.3: Update App Icons
1. In Xcode, click **Runner** → **Assets.xcassets** → **AppIcon**

2. You need app icons in the following sizes:
   - 20x20 (2x and 3x)
   - 29x29 (2x and 3x)
   - 40x40 (2x and 3x)
   - 60x60 (2x and 3x)
   - 1024x1024 (App Store icon)

3. **Option A: Use a tool to generate all sizes:**
   - Visit: https://appicon.co
   - Upload your 1024x1024 icon
   - Download the iOS icon set
   - Drag all icons into Xcode's AppIcon slots

4. **Option B: Manual creation:**
   - Use Photoshop, Figma, or similar tool
   - Export each required size
   - Drag each into the appropriate slot in Xcode

#### 7.4: Update Launch Screen
1. In Xcode, open **Runner** → **LaunchScreen.storyboard**
2. Customize the launch screen (optional):
   - Add your logo
   - Change background color
   - Add app name text
3. Or use the default Flutter launch screen

#### 7.5: Update Info.plist
1. In Xcode, open **Runner** → **Info.plist**

2. Add/verify these keys:

   **App Name:**
   ```xml
   <key>CFBundleDisplayName</key>
   <string>RecallSentry</string>
   ```

   **Privacy Descriptions (add any you use):**
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Allow RecallSentry to scan barcodes for recall checking</string>

   <key>NSPhotoLibraryUsageDescription</key>
   <string>Allow RecallSentry to select photos for product identification</string>

   <key>NSLocationWhenInUseUsageDescription</key>
   <string>Allow RecallSentry to find recalls in your area</string>
   ```
   - Add only the permissions your app actually uses
   - Update descriptions to match your app's functionality

3. Save the file

---

## Part 4: App Store Assets Preparation

### Step 8: Prepare App Store Screenshots

#### 8.1: Required Screenshot Sizes
You need screenshots for these device sizes:
- **6.7" Display (iPhone 14 Pro Max):** 1290 x 2796 pixels (required)
- **6.5" Display (iPhone 11 Pro Max):** 1242 x 2688 pixels (required)
- **5.5" Display (iPhone 8 Plus):** 1242 x 2208 pixels (optional)

Apple requires at least **3 screenshots**, maximum **10 screenshots** per device size.

#### 8.2: Capture Screenshots
**Option A: Use iPhone Simulator**
1. On MacBook, open Terminal:
   ```bash
   cd ~/path/to/rs_flutter
   ```

2. List available simulators:
   ```bash
   xcrun simctl list devices
   ```

3. Start simulator (iPhone 14 Pro Max):
   ```bash
   open -a Simulator
   ```
   - In Simulator: **Device** → **iPhone 14 Pro Max**

4. Run your app:
   ```bash
   flutter run
   ```

5. Navigate through your app and capture key screens:
   - Press **Cmd + S** to save screenshot
   - Or: **File** → **New Screenshot**
   - Take screenshots of:
     - Home screen
     - Main features
     - Category browsing
     - Recall details
     - Filter functionality
     - Settings/profile

6. Repeat for other required device sizes

**Option B: Use Real Device**
1. Connect iPhone to MacBook
2. Run app: `flutter run --release`
3. Take screenshots on device (Power + Volume Up button)
4. Transfer screenshots to MacBook via AirDrop or cable

#### 8.3: Enhance Screenshots (Recommended)
Use tools to make screenshots more appealing:
- **Figma, Sketch, or Photoshop:**
  - Add text overlays explaining features
  - Add device frames
  - Add captions highlighting key benefits

- **Online Tools:**
  - Screely: https://screely.com
  - AppMockUp: https://app-mockup.com
  - Previewed: https://previewed.app

### Step 9: Prepare App Preview Video (Optional but Recommended)
- **Duration:** 15-30 seconds
- **Format:** .mov, .mp4, or .m4v
- **Size:** Up to 500 MB
- **Resolution:** Match screenshot requirements
- **Content:** Show key app features and user flow

### Step 10: Write App Store Listing Content

#### 10.1: App Name
- **Maximum:** 30 characters
- **Example:** RecallSentry
- Keep it simple, memorable, and searchable

#### 10.2: Subtitle
- **Maximum:** 30 characters
- **Example:** "FDA & USDA Recall Alerts"
- Briefly describes your app's main benefit

#### 10.3: Description
- **Maximum:** 4,000 characters
- **First 2-3 lines are critical** (shown before "more" link)

**Example Description:**
```
Stay safe and informed with RecallSentry - your essential companion for tracking FDA and USDA product recalls.

RecallSentry provides real-time alerts and comprehensive information about food, drug, medical device, and veterinary product recalls, helping you and your family stay safe.

KEY FEATURES:
• Real-Time Recall Alerts - Get instant notifications about the latest FDA and USDA recalls
• Smart Filtering - Customize alerts based on categories, brands, and products you care about
• Comprehensive Database - Access detailed recall information including affected products, health hazards, and remedies
• Category Browsing - Easily explore recalls by category: Food, Drugs, Cosmetics, Medical Devices, Veterinary Products, and more
• Saved Recalls - Bookmark important recalls for quick reference
• No Ads - Enjoy an ad-free experience focused on your safety

SUBSCRIPTION TIERS:
• Free - Access to all recalls from the last 30 days
• Smart Filtering - Advanced filtering and year-to-date recall access
• Recall Match - Premium features with personalized recommendations

RecallSentry aggregates official recall data from the FDA and USDA, making it easy to stay informed about product safety issues that matter to you.

Download RecallSentry today and take control of your product safety!
```

#### 10.4: Keywords
- **Maximum:** 100 characters total (including commas)
- **Separate with commas**, no spaces
- **Example:** recall,FDA,USDA,food,safety,alert,notification,health,drug,medical,product,consumer

**Tips:**
- Research keywords using App Store search
- Include variations (recall, recalls, recalled)
- Avoid app name (automatically indexed)
- Think about how users will search

#### 10.5: Support URL
- Must be a valid URL
- Example: https://www.recallsentry.com/support
- Or create a simple support page on Google Sites/Wix

#### 10.6: Marketing URL (optional)
- Your main website
- Example: https://www.recallsentry.com

#### 10.7: Privacy Policy URL (Required)
⚠️ **REQUIRED** for all apps

**Option A: Create your own**
- Host on your website
- Must cover: data collection, usage, sharing, security
- Must be specific to your app

**Option B: Use a generator**
- https://www.privacypolicygenerator.info
- https://app-privacy-policy-generator.firebaseapp.com
- Answer questions about your app
- Download and host the generated policy

**Example hosting options:**
- GitHub Pages (free)
- Google Sites (free)
- Your domain

---

## Part 5: Build and Archive

### Step 11: Prepare for Release Build

#### 11.1: Clean and Update Dependencies
```bash
cd ~/path/to/rs_flutter
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

#### 11.2: Run Tests
```bash
flutter test
```
- Fix any failing tests before proceeding

#### 11.3: Analyze Code
```bash
flutter analyze
```
- Address any critical issues or warnings

### Step 12: Build Release IPA (iOS App Package)

#### Method A: Using Flutter Build Command
1. Build iOS app:
   ```bash
   flutter build ios --release
   ```
   - This compiles your app for release
   - Takes 5-15 minutes
   - Creates optimized app bundle

2. If successful, proceed to archiving in Xcode

#### Method B: Using Xcode (Recommended for App Store)

1. Open Xcode project:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In Xcode toolbar:
   - Set scheme to **Runner**
   - Set destination to **Any iOS Device (arm64)**

3. **Product Menu → Archive**
   - This builds and archives your app
   - Takes 5-15 minutes for first build
   - Archive will appear in Organizer window when complete

### Step 13: Upload to App Store Connect

1. After archiving completes, **Organizer** window appears automatically
   - If not, go to **Window → Organizer** (or press **Cmd + Shift + Option + O**)

2. Select your archive from the list (should be the most recent)

3. Click **Distribute App** button

4. Select **App Store Connect**
   - Click **Next**

5. Select **Upload**
   - Click **Next**

6. Distribution options:
   - **App Thinning:** All compatible device variants (default)
   - **Rebuild from Bitcode:** Yes (checked)
   - **Include symbols:** Yes (checked)
   - Click **Next**

7. Automatic signing:
   - **Automatically manage signing:** Checked
   - Click **Next**

8. Review your app information:
   - Verify bundle ID, version, build number
   - Click **Upload**

9. Wait for upload to complete (5-20 minutes depending on internet speed)

10. You'll see a success message when upload is complete

### Step 14: Verify Upload in App Store Connect

1. Go to: https://appstoreconnect.apple.com
2. Click **My Apps** → **RecallSentry**
3. Click the **+** button next to **iOS App** in the left sidebar
4. You should see your build processing
   - Status will show **Processing** initially
   - Processing can take **30 minutes to 2 hours**
   - You'll receive an email when processing is complete

---

## Part 6: App Store Submission

### Step 15: Complete App Store Listing

Once your build is processed, return to App Store Connect:

1. Click **My Apps** → **RecallSentry**

2. Under **iOS App**, click the version number (e.g., **1.0 Prepare for Submission**)

#### 15.1: App Information
1. Upload **Screenshots**:
   - Drag and drop screenshots for each required device size
   - Arrange in order (first screenshot is most important)
   - Must have at least 3 screenshots per device size

2. Upload **App Preview Video** (optional):
   - Drag and drop video file
   - Add video poster frame

3. Enter **Promotional Text** (optional):
   - Maximum 170 characters
   - Can be updated anytime without new version submission
   - Example: "Now with enhanced recall filtering and year-to-date access for premium users!"

4. Enter **Description** (prepared in Step 10)

5. Enter **Keywords** (prepared in Step 10)

6. Enter **Support URL** (prepared in Step 10)

7. Enter **Marketing URL** (optional, prepared in Step 10)

#### 15.2: General App Information
1. Click **General App Information** in left sidebar

2. **App Icon:**
   - Upload 1024x1024 PNG icon
   - No transparency, no alpha channel
   - Square with no rounded corners (Apple adds them)

3. **Version:** Should show 1.0.0 (or your version)

4. **Copyright:** `© 2025 Your Name` (or your company)

5. **Age Rating:** Should be set from earlier (4+ recommended)

6. **Privacy Policy URL:** Enter URL from Step 10

#### 15.3: Build Selection
1. Scroll to **Build** section
2. Click the **+** button next to Build
3. Select your uploaded build from the list
4. Click **Done**

#### 15.4: App Review Information
This information is for Apple reviewers, not public:

1. **Sign-In Information:**
   - If your app requires login, provide test credentials:
     - **Username:** testuser@example.com
     - **Password:** TestPassword123
   - If no login required, check "Sign-in required: No"

2. **Contact Information:**
   - **First Name:** Your first name
   - **Last Name:** Your last name
   - **Phone Number:** Your phone number
   - **Email:** Your email address
   - This is for Apple to contact you if needed

3. **Notes:**
   - Add any information that will help reviewers understand your app
   - Example:
     ```
     RecallSentry provides FDA and USDA recall information to consumers.

     Test Data:
     - All recall data is live from government APIs
     - No special setup required for testing
     - Premium features can be tested with the provided test account

     Key Features to Review:
     - Browse recalls by category
     - Apply filters to customize recall views
     - Save recalls for later reference
     - View detailed recall information
     ```

4. **Attachment (optional):**
   - Add screenshots or documents if it helps explain your app

#### 15.5: Version Release
1. Scroll to **Version Release** section

2. Select release option:
   - **Automatic release:** App goes live immediately after approval
   - **Manual release:** You control when to release after approval
   - **Scheduled release:** Set a specific date/time

3. For first release, recommend **Automatic release**

### Step 16: Submit for Review

1. Review all sections - look for any red warning icons

2. All sections must show green checkmarks:
   - ✅ App Store Information
   - ✅ Pricing and Availability
   - ✅ General App Information
   - ✅ App Review Information
   - ✅ Version Information

3. Click **Submit for Review** button in top-right corner

4. Confirm submission in the popup dialog

5. Status changes to **Waiting for Review**

---

## Part 7: Review Process

### Step 17: App Review Timeline

**Typical Timeline:**
- **In Review:** 1-2 days (sometimes 24 hours)
- **Under Review:** Usually completes within 24 hours
- **Total:** Typically 1-3 days from submission to approval

**Status Progression:**
1. **Waiting for Review** - In queue
2. **In Review** - Apple reviewer is testing your app
3. **Pending Developer Release** - Approved, waiting for you to release (if manual release)
4. **Ready for Sale** - Live on App Store!

**Or:**
- **Rejected** - Apple found issues (see Step 18)

### Step 18: If Your App is Rejected

Don't worry! Rejection is common for first-time submissions.

#### 18.1: Understanding the Rejection
1. You'll receive an email from Apple
2. Log into App Store Connect
3. Click **Resolution Center** in top menu
4. Read the rejection reason carefully

**Common Rejection Reasons:**
- Missing features/content (app seems incomplete)
- Crashes or bugs during review
- Violates App Store Review Guidelines
- Missing privacy policy or incorrect implementation
- Misleading screenshots or description
- Requires permissions not listed in Info.plist
- In-app purchases not properly implemented

#### 18.2: Fixing and Resubmitting
1. Address all issues mentioned in the rejection

2. If you need clarification:
   - Click **Reply** in Resolution Center
   - Ask specific questions
   - Apple typically responds within 1-2 days

3. Update your app:
   - Fix bugs/issues on MacBook
   - Rebuild and upload new version (follow Steps 11-14)
   - Or update app information if that was the issue

4. Once fixed:
   - Go to App Store Connect → Your App
   - Click the version
   - Address reviewer notes if needed
   - Click **Submit for Review** again

### Step 19: App Approved - Going Live!

🎉 **Congratulations!** Your app is approved!

#### 19.1: Manual Release (if selected)
1. Go to App Store Connect → Your App
2. Status shows **Pending Developer Release**
3. Click **Release this Version** button
4. App goes live within 24 hours

#### 19.2: Automatic Release
- App automatically goes live within 24 hours
- Status changes to **Ready for Sale**

#### 19.3: Verify on App Store
1. Open App Store on iPhone or Mac
2. Search for "RecallSentry"
3. Your app should appear!
4. Share the link with friends and family

**Get Your App Store Link:**
- Format: `https://apps.apple.com/us/app/recallsentry/id[APPID]`
- Find exact link in App Store Connect under **App Information**

---

## Part 8: Post-Launch

### Step 20: Monitor App Performance

#### 20.1: App Analytics
1. Go to App Store Connect → **Analytics**
2. View:
   - Impressions (how many people see your app)
   - Product Page Views
   - Downloads
   - App Units (installs)
   - Crashes
   - Ratings & Reviews

#### 20.2: Respond to Reviews
1. Go to App Store Connect → **Ratings and Reviews**
2. Respond to user reviews (highly recommended)
3. Be professional and helpful
4. Address issues users mention

### Step 21: Releasing Updates

When you want to update your app:

1. Update code and test on MacBook

2. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2
   ```
   - Increment version number (1.0.1)
   - Increment build number (+2)

3. Update version in Xcode:
   - Open `ios/Runner.xcworkspace`
   - Update **Version** and **Build** numbers

4. Follow Steps 11-16 again:
   - Build → Archive → Upload → Submit for Review

5. In App Store Connect:
   - Click the **+** button to add a new version
   - Enter version number (e.g., 1.0.1)
   - Complete "What's New in This Version" field
   - Select new build
   - Submit for review

**Update Review Time:**
- Usually faster than initial review (1-2 days)

---

## Troubleshooting

### Issue: "Bundle identifier mismatch"
**Solution:**
- Ensure Bundle ID in Xcode matches App Store Connect exactly
- Check for typos or extra spaces

### Issue: "Missing compliance"
**Solution:**
- After upload, you'll see "Missing Compliance" warning
- Click **Manage** → Answer export compliance questions
- If your app doesn't use encryption: Select "No"

### Issue: "Invalid icon"
**Solution:**
- Icon must be exactly 1024x1024 pixels
- PNG format, no transparency
- Square (no rounded corners)

### Issue: "Build processing taking too long"
**Solution:**
- Processing can take up to 2 hours
- If longer than 4 hours, contact Apple Support
- Check for email from Apple about any issues

### Issue: "Provisioning profile error"
**Solution:**
- In Xcode: **Product → Clean Build Folder**
- Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Regenerate profiles: Xcode → Preferences → Accounts → Download Manual Profiles

### Issue: "App crashes during review"
**Solution:**
- Test thoroughly on multiple devices
- Check crash logs in Xcode Organizer
- Test release build specifically: `flutter run --release`

---

## Checklist

Before submitting, verify:

- ✅ Apple Developer account is active ($99/year)
- ✅ Bundle ID created and matches across all places
- ✅ App created in App Store Connect
- ✅ All required screenshots uploaded (minimum 3 per device size)
- ✅ App icon (1024x1024) uploaded
- ✅ Description, keywords, and URLs entered
- ✅ Privacy Policy URL provided
- ✅ App Information completed (age rating, category, etc.)
- ✅ Build uploaded and processed
- ✅ Build selected in version
- ✅ App Review Information filled out (test credentials if needed)
- ✅ All green checkmarks showing in submission page
- ✅ Tested app thoroughly on real device
- ✅ No crashes or critical bugs

---

## Cost Summary

**Required Costs:**
- Apple Developer Program: **$99/year** (required for App Store)

**Optional Costs:**
- Professional app icon design: $50-$500
- Screenshot design/enhancement: $0-$200 (optional, DIY possible)
- Privacy policy generator: $0-$50 (free options available)
- Domain name for website/support: $10-$15/year (optional)

**Total Minimum:** $99/year

---

## Timeline Summary

**First-Time Submission:**
- Account setup: 1-2 days (waiting for Apple activation)
- Asset preparation: 2-4 hours (screenshots, description, etc.)
- Xcode configuration: 1-2 hours
- Build and upload: 30 minutes - 1 hour
- App Store Connect setup: 1-2 hours
- Review process: 1-3 days
- **Total: ~1 week** from starting enrollment to app going live

**Subsequent Updates:**
- Build and upload: 30 minutes
- Review: 1-2 days
- **Total: 2-3 days** per update

---

## Resources

**Official Apple Documentation:**
- App Store Connect Help: https://help.apple.com/app-store-connect/
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/

**Helpful Tools:**
- App Icon Generator: https://appicon.co
- Screenshot Mockup: https://app-mockup.com
- Privacy Policy Generator: https://www.privacypolicygenerator.info
- ASO (App Store Optimization): https://www.appradar.com

**Support:**
- Apple Developer Support: https://developer.apple.com/support/
- Apple Developer Forums: https://developer.apple.com/forums/

---

*Document created: 2025-11-02*
*Project: RecallSentry Flutter Application*
*Version: 1.0*
