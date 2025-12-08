#!/usr/bin/env python3
"""Add deep link configuration to Android and iOS"""

# ==== ANDROID ====
android_path = 'c:/RS_Flutter/rs_flutter/android/app/src/main/AndroidManifest.xml'

with open(android_path, 'r', encoding='utf-8') as f:
    android_content = f.read()

# Add deep link intent-filter to Android
old_android = '''            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>'''

new_android = '''            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            <!-- Deep Links for RecallSentry -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="recallsentry" />
            </intent-filter>
        </activity>'''

if old_android in android_content:
    android_content = android_content.replace(old_android, new_android)
    with open(android_path, 'w', encoding='utf-8') as f:
        f.write(android_content)
    print("[OK] Android: Added deep link intent-filter")
elif 'android:scheme="recallsentry"' in android_content:
    print("[OK] Android: Deep links already configured")
else:
    print("[ERROR] Android: Could not find expected pattern")

# ==== iOS ====
ios_path = 'c:/RS_Flutter/rs_flutter/ios/Runner/Info.plist'

with open(ios_path, 'r', encoding='utf-8') as f:
    ios_content = f.read()

# Add CFBundleURLTypes for iOS deep links
if 'CFBundleURLTypes' not in ios_content:
    # Insert before closing </dict></plist>
    url_types = '''	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLName</key>
			<string>com.centerforrecallsafety.recallsentry</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>recallsentry</string>
			</array>
		</dict>
	</array>
'''
    ios_content = ios_content.replace('</dict>\n</plist>', url_types + '</dict>\n</plist>')
    with open(ios_path, 'w', encoding='utf-8') as f:
        f.write(ios_content)
    print("[OK] iOS: Added CFBundleURLTypes for deep links")
else:
    print("[OK] iOS: CFBundleURLTypes already exists")

print("")
print("Deep link configuration complete!")
print("URL Scheme: recallsentry://")
print("")
print("Next: Add route handling in Flutter to parse deep link paths")
