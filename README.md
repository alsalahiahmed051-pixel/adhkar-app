# أذكاري — Flutter App

تطبيق أذكار إسلامي متكامل بنظامَي Android وiOS.

---

## الميزات

- أذكار الصباح والمساء والنوم والصلاة على النبي ﷺ وغيرها
- **مسبحة رقمية مرسومة يدويًا** (33 حبّة، حبّة الإمام، الشرّابة)
- **ذكر صوتي** — قل الذكر بصوتك ويُحسب تلقائيًا
- إضافة ذكر بنص أو صورة أو صوت mp3 أو ملف PDF
- مشاركة الذكر بكود فريد + عدّاد مشترك مع أي شخص
- إضافة تصنيفات من المستخدمين (تحتاج موافقة المشرف)
- لوحة مراجعة للمشرف (قبول / رفض محتوى + تصنيفات)
- وضع ليلي / نهاري كامل
- تذكيرات يومية بأذكار الصباح والمساء
- شاشة تعريفية عند أول تشغيل

---

## متطلبات البيئة

| الأداة | الإصدار المطلوب |
|--------|----------------|
| Flutter SDK | ≥ 3.19 |
| Dart SDK | ≥ 3.0 |
| Android SDK | compileSdk 34, minSdk 21 |
| Xcode | ≥ 15 (iOS) |
| Firebase CLI | أي إصدار حديث |
| Node.js | ≥ 18 (للـ Firebase CLI) |

---

## خطوات الإعداد

### 1. استنسخ المشروع أو انسخ الملفات

```bash
cd adhkar_app
flutter pub get
```

---

### 2. أنشئ مشروع Firebase

1. اذهب لـ [console.firebase.google.com](https://console.firebase.google.com)
2. **Create Project** → اختر اسمًا مثل `adhkar-app`
3. فعّل هذه الخدمات من القائمة الجانبية:
   - **Firestore Database** → ابدأ بـ Production Mode
   - **Storage** → ابدأ بـ Production Mode
4. في Firestore اذهب لـ **Rules** والصق محتوى ملف `firestore.rules`
5. في Storage اذهب لـ **Rules** والصق محتوى ملف `storage.rules`

---

### 3. ربط Firebase بالتطبيق (FlutterFire CLI)

```bash
# تثبيت FlutterFire CLI
dart pub global activate flutterfire_cli

# الربط (سيولّد ملف firebase_options.dart تلقائيًا)
flutterfire configure --project=YOUR_PROJECT_ID
```

سيُنشئ هذا الأمر تلقائيًا:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

> **مهم:** بعد الإنشاء، عدّل `main.dart` وأضف `options`:
> ```dart
> await Firebase.initializeApp(
>   options: DefaultFirebaseOptions.currentPlatform,
> );
> ```
> واستورد: `import 'firebase_options.dart';`

---

### 4. إعداد Android

في `android/app/build.gradle` تأكد من:
```gradle
minSdk 21
compileSdk 34
```

في `android/app/src/main/AndroidManifest.xml` الأذونات مُضافة بالفعل.

**تفعيل desugaring (مطلوب للإشعارات):**
في `android/app/build.gradle`:
```gradle
compileOptions {
    coreLibraryDesugaringEnabled true
}
dependencies {
    coreLibraryDesugaring "com.android.tools.build:desugaring:2.0.4"
}
```

---

### 5. إعداد iOS

1. افتح `ios/Runner/Info.plist` وأضف المفاتيح الموضحة في الملف المرفق.
2. في Xcode → **Signing & Capabilities** → فعّل:
   - **Push Notifications**
   - **Background Modes** → ضع علامة على **Remote notifications**

```bash
cd ios && pod install
```

---

### 6. تشغيل التطبيق

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Release APK
flutter build apk --release

# Release IPA
flutter build ipa --release
```

---

## هيكل المشروع

```
lib/
├── main.dart                    ← نقطة الدخول
├── theme/
│   ├── app_colors.dart          ← الألوان (ink, gold, voiceRed...)
│   └── app_theme.dart           ← ThemeData builder
├── models/
│   ├── category.dart            ← DhikrCategory + البيانات المدمجة
│   ├── dhikr_item.dart          ← موديل الذكر + Firestore (de)serialization
│   └── seed_data.dart           ← الأذكار المدمجة في التطبيق
├── services/
│   ├── utils.dart               ← generateId, generateShareCode, normalizeArabic
│   ├── local_prefs_service.dart ← SharedPreferences (بيانات خاصة بالجهاز)
│   ├── firestore_service.dart   ← Firebase Firestore + Storage
│   └── notification_service.dart← تذكيرات يومية (flutter_local_notifications)
├── providers/
│   └── app_state.dart           ← ChangeNotifier الرئيسي
├── widgets/
│   ├── tasbih_ring.dart         ← المسبحة (CustomPainter مرسومة يدويًا)
│   ├── diamond_rule.dart        ← الفاصل الزخرفي بالماسات
│   ├── pill.dart                ← بادج المصدر / العدد / الكود
│   └── dhikr_card.dart          ← بطاقة الذكر في القائمة
└── screens/
    ├── home_screen.dart         ← الشاشة الرئيسية + قائمة جانبية + بحث
    ├── detail_screen.dart       ← تفاصيل الذكر + مسبحة كبيرة + أزرار المشاركة
    ├── add_dhikr_screen.dart    ← إضافة ذكر (نص / صورة / صوت / ملف)
    ├── voice_screen.dart        ← اذكر الله بصوتك
    ├── admin_screen.dart        ← لوحة المراجعة (gate + panel)
    └── onboarding_screen.dart   ← شاشة الترحيب (أول تشغيل)
```

---

## بيانات المشرف (تجريبي فقط)

الرمز الافتراضي: **1234**

> ⚠️ هذا قفل تجريبي للعرض فقط — في الإنتاج استخدم Firebase Authentication مع Custom Claims لتحديد صلاحيات المشرف بشكل حقيقي.

لتغيير الرمز، عدّل الثابت في:
```dart
// lib/providers/app_state.dart
const String kAdminPasscode = '1234';
```

---

## الانتقال للإنتاج الحقيقي

| الميزة | الحالي (تجريبي) | للإنتاج |
|--------|----------------|---------|
| صلاحية المشرف | رمز PIN ثابت | Firebase Auth + Custom Claims |
| قواعد Firestore | مفتوحة للقراءة | مشروطة بـ auth.uid |
| الإشعارات | flutter_local_notifications | Firebase Cloud Messaging (FCM) |
| رفع الملفات | مباشرة من الجهاز | Firebase Storage مع حد الحجم |
| البحث الكامل النصي | normalizeArabic على العميل | Algolia أو Typesense أو Firebase Extensions |

---

## الاعتمادات

- [Flutter](https://flutter.dev)
- [Firebase](https://firebase.google.com)
- [google_fonts](https://pub.dev/packages/google_fonts) — Amiri + Tajawal
- [speech_to_text](https://pub.dev/packages/speech_to_text)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [audioplayers](https://pub.dev/packages/audioplayers)
- [share_plus](https://pub.dev/packages/share_plus)
