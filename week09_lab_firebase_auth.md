# ใบงานปฏิบัติสัปดาห์ที่ 9 Cloud Database — Firebase & Authentication

**เครื่องมือ** Flutter, Firebase Console, FlutterFire CLI, Firebase Authentication, Cloud Firestore, Firebase Storage, google_sign_in

---

## วัตถุประสงค์การเรียนรู้

เมื่อทำใบงานนี้เสร็จสิ้น ผู้เรียนจะสามารถ

1. ตั้งค่า Firebase Project เพื่อเชื่อมต่อกับแอป Flutter ด้วย FlutterFire CLI
2. ใช้งาน Firebase Authentication เพื่อสมัครสมาชิกและเข้าสู่ระบบด้วย Email/Password และ Google Sign-In
3. ออกแบบหน้าจอที่สลับไปมาระหว่างสถานะ "ยังไม่ล็อกอิน" และ "ล็อกอินแล้ว" ด้วย `StreamBuilder` ฟัง Stream ของ Firebase Auth (`AuthGate`)
4. ขยาย Repository Pattern เดิมด้วยการเพิ่ม Implementation ใหม่ (`ItemRepositoryFirestore`) และรวมผลลัพธ์จากหลาย `ItemRepository` เข้าด้วยกันบนหน้า Home โดยไม่แก้ไข Interface เดิม
5. เขียน CRUD (Create, Read, Update, Delete) กับ Cloud Firestore ทั้งแบบอ่านครั้งเดียวและแบบฟังข้อมูล Real-time
6. อัปโหลดไฟล์รูปภาพขึ้น Firebase Storage และเชื่อมโยง URL ที่ได้เข้ากับเอกสารใน Firestore
7. อธิบายได้ว่าทำไม Client-side Validation อย่างเดียวไม่เพียงพอ และ Firebase Security Rules ทำหน้าที่อะไร

## สิ่งที่ต้องเตรียมก่อนเริ่ม

- โปรเจกต์ `campus_marketplace_w7` จากสัปดาห์ที่ 8 ที่มี `MainScaffold` 3 แท็บและ `MyDraftsPage` ทำงานได้ครบแล้ว
- บัญชี Google สำหรับสร้าง Firebase Project ฟรีที่ https://console.firebase.google.com (ใช้บัญชีเดียวกับที่สมัคร Google AI Studio ในสัปดาห์ที่ 7 ก็ได้)
- ติดตั้ง Node.js (เวอร์ชัน LTS ปัจจุบัน) เพื่อใช้คำสั่ง `npm install -g firebase-tools` และ `dart pub global activate flutterfire_cli`
- เครื่อง Android จริงหรือ Emulator ที่มีการตั้งค่า Google Play Services (จำเป็นสำหรับทดสอบ Google Sign-In) หรือ iOS Simulator/เครื่องจริงที่ล็อกอิน Apple ID ไว้แล้ว

> ⚠️ **ข้อควรรู้เรื่องความปลอดภัยของไฟล์ตั้งค่า Firebase**: ไฟล์ `google-services.json` (Android), `GoogleService-Info.plist` (iOS) และ `firebase_options.dart` ที่ได้จากคำสั่ง `flutterfire configure` **ไม่ใช่ความลับแบบเดียวกับ Gemini API Key** ในสัปดาห์ที่ 7 — Google ยืนยันว่าไฟล์เหล่านี้ฝังอยู่ในตัวแอปที่ปล่อยให้ผู้ใช้ดาวน์โหลดได้อย่างปลอดภัย เพราะเป็นเพียงตัวระบุโปรเจกต์ ไม่ใช่กุญแจเข้าถึงข้อมูล **ความปลอดภัยที่แท้จริงของ Firebase อยู่ที่ Security Rules**  ไม่ใช่การซ่อนไฟล์ตั้งค่าเหล่านี้ แต่ถึงอย่างนั้น ทีมพัฒนาส่วนใหญ่ก็ยังนิยม `.gitignore` ไฟล์เหล่านี้ไว้เพื่อป้องกันความสับสนเวลาสมาชิกในทีมใช้ Firebase Project คนละตัวกัน ให้ทำตามนี้ไว้เป็นนิสัยที่ดีเช่นกัน

---
## ขั้นตอนการทดลอง
## ส่วนที่ 1: ตั้งค่า Firebase Project และเชื่อมกับ Flutter

### ขั้นตอนที่ 1.1: 🔧 ทำตามขั้นตอน — สร้าง Firebase Project
**ให้ใช้ gmail account ส่วนตัวเพื่อไม่ใช่ account นักศึกษาของสถาบัน**
เปิด https://console.firebase.google.com กด **Create a new Firebase project** หรือ **Get stared by setting up a Firebase project** ตั้งชื่อโปรเจกต์ **ตั้งชื่อไม่ให้ชื่อซ้ำกับที่มีอยู่ใน Firebase**(เช่น `campus-marketplace-2026-<ชื่อนักศึกษาภาษาอังกฤษ>` ) ปิดการใช้งาน Google Analytics ได้หากไม่ต้องการ (ไม่จำเป็นสำหรับใบงานนี้) 


> ✅ **Checkpoint 1.1** ถ่ายภาพหน้าจอ Firebase Console ที่แสดงหน้า Project Overview ของโปรเจกต์ที่สร้างเสร็จแล้ว

``text
บันทึกรูปผลลัพธ์ที่นี่
<img width="1917" height="958" alt="image" src="https://github.com/user-attachments/assets/b131889f-a67d-49b4-9dc9-2a9f07627e97" />

`

### ขั้นตอนที่ 1.2: 🔧 ทำตามขั้นตอน — ติดตั้งเครื่องมือและเชื่อมโปรเจกต์ด้วย FlutterFire CLI

ติดตั้งเครื่องมือที่จำเป็น (ทำครั้งเดียวต่อเครื่อง)

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

**กรณีใช้  Macbook แล้วติดปัญหาเรื่อง  Permission ให้ใช้คำสั่งดังนี้**
```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

จากนั้นเปิด Terminal ที่โฟลเดอร์ `campus_marketplace_w7` แล้วรัน

```bash
flutterfire configure
```
**หากเกิดปัญหา ระบบไม่รู้จักคำสั่ง flutterfire configure ให้รันคำสั่งส่วนนี้ก่อน**
```bash
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc
```

คำสั่งนี้จะให้เลือก Firebase Project ให้นักศึกษาพิมพ์ชื่อ Project ที่ได้สร้างไปในขั้นตอน 1.1
หลังจากนั้นเลือกแพลตฟอร์มที่ต้องการโดยกดลูกศรและ spacebar และเลือกเฉพาะ Android แพลตฟอร์ม (เพื่อไม่ให้เกิดปัญหา)   **แล้วกดปุ่ม Enter**
 เมื่อเสร็จแล้วจะได้ไฟล์ `lib/firebase_options.dart` ที่สร้างขึ้นอัตโนมัติ **ห้ามแก้ไขไฟล์นี้ด้วยมือ**

### ขั้นตอนที่ 1.3: 🔧 ทำตามขั้นตอน — เพิ่ม Dependencies และเริ่มต้น Firebase ในแอป

เพิ่มใน `pubspec.yaml`

```yaml
dependencies:
  firebase_core: ^4.14.0
  firebase_auth: ^6.6.0
  cloud_firestore: ^6.9.0
  firebase_storage: ^13.5.0
  google_sign_in: ^7.2.0
```

รัน `flutter pub get` แล้วแก้ไขจุดเริ่มต้นของแอป **`lib/main.dart`** ตามโครงสร้างในเนื้อหาสัปดาห์นี้หัวข้อ 9.1 — เพิ่มการเริ่มต้น Firebase ก่อนเรียก `runApp()` เท่านั้น ส่วนโค้ดเดิมจากสัปดาห์ที่ 8 (การสร้าง `AppDatabase`, `ChangeNotifierProvider<CartModel>`, คลาส `MyApp`) ยังอยู่ที่เดิมทุกจุด ไม่ต้องย้ายหรือลบ

ก่อนแก้ (`lib/main.dart`) 

```dart
void main() {
  final db = AppDatabase();
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: MyApp(db: db),
    ),
  );
}
```

**หลังแก้ (เพิ่ม import 2 บรรทัดต่อท้าย import เดิม และ เปลี่ยน void main() เป็น 3 บรรทัดใหม่)**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = AppDatabase();
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: MyApp(db: db),
    ),
  );
}
```

> ⚠️ ใช้ชื่อพารามิเตอร์ `db:` ให้ตรงกับชื่อ field ของ `MyApp` ที่สร้างไว้ตั้งแต่สัปดาห์ที่ 8 (`final AppDatabase db;`) **ถ้าโปรเจกต์ของตัวเองตั้งชื่อ field นี้ไว้ต่างออกไป (เช่น `database`) ให้ใช้ชื่อเดิมของตัวเองต่อไป อย่าเปลี่ยนตาม** และต้องใช้ชื่อเดียวกันนี้ให้ตรงกันทุกจุดในไฟล์ รวมถึงตอนเรียก `FavoritesRepositoryDrift(...)`/`ListingDraftRepositoryDrift(...)` ในขั้นตอนที่ 4.1 ด้านล่างด้วย (เช่น ถ้า field ชื่อ `db` ต้องเขียน `FavoritesRepositoryDrift(db)` ไม่ใช่ `FavoritesRepositoryDrift(database)`) — ชื่อไม่ตรงกันเป็นสาเหตุ Error `undefined name` ที่พบบ่อยที่สุดจุดหนึ่งในใบงานนี้

> 💡 สังเกตว่า `main()` เปลี่ยนจาก `void main()` เป็น `Future<void> main() async` เพราะ `Firebase.initializeApp()` เป็น Asynchronous ต้อง `await` ให้เสร็จก่อน `runApp()` เสมอ ส่วนคลาส `MyApp` ที่อยู่ด้านล่าง (ไฟล์เดียวกัน) ยังไม่ต้องแตะอะไรในขั้นตอนนี้ — การเชื่อม Firebase เข้ากับส่วนที่เหลือของแอปจะทำในส่วนที่ 4

---

## ส่วนที่ 2: Firebase Authentication ด้วย Email และ Password

### ขั้นตอนที่ 2.1: 🔧 ทำตามขั้นตอน — เปิดใช้งาน Sign-in Method ใน Console

(1) เข้าหน้าเว็บ Firebase Console ไปที่เมนู **Security ->Authentication**
(2) ถ้าเข้ามาครั้งแรก ให้เลือก  Get started แล้วเลือก **Sign-in method** เปิดใช้งาน **Email/Password** 
(3)เลือก add provider -> **Google** (จะใช้ Google ในส่วนที่ 3)
กำหนดค่า Public-facing name for project  เป็น campus-marketplace และเลือก Support email for project


### ขั้นตอนที่ 2.2: **สร้างไฟล์เอง** — AuthService

สร้างไฟล์ `lib/services/auth_service.dart` ตามโครงสร้างในเนื้อหาสัปดาห์นี้หัวข้อ 9.3

**ข้อกำหนดที่ต้องมีครบ (ตรวจสอบตก่อนไปต่อในขั้นตอนถัดไป):**

- มีเมธอด `Future<void> signUp({required String email, required String password})`
- มีเมธอด `Future<void> signIn({required String email, required String password})`
- มีเมธอด `Future<void> signOut()`
- ทุกเมธอดที่เรียก Firebase ต้อง `try/catch` ดักจับ `FirebaseAuthException` แล้วแปลแต่ละค่า `code` (เช่น `email-already-in-use`, `weak-password`, `invalid-credential`) ให้เป็นข้อความภาษาไทยที่ผู้ใช้เข้าใจได้ **ห้ามปล่อยให้ Error ดิบจาก Firebase หลุดไปแสดงตรง ๆ**


### ขั้นตอนที่ 2.3: **นักศึกษาเขียน Code เอง** — หน้าจอ Login / Sign Up

สร้างไฟล์ `lib/screens/login_page.dart` เป็นฟอร์มที่มีช่อง Email, Password และปุ่มสลับโหมด "เข้าสู่ระบบ" / "สมัครสมาชิก" เชื่อมกับ `AuthService` ที่สร้างไว้ แสดงสถานะ Loading ระหว่างรอ และแสดงข้อความ Error ที่แปลแล้วเมื่อล้มเหลว

> 🔧 **เชื่อม LoginPage เข้ากับแอปชั่วคราวเพื่อทดสอบ:** `AuthGate` ที่จะสลับหน้าจอ Login/Home ให้อัตโนมัติยังไม่ถูกสร้างจนกว่าจะถึงส่วนที่ 4 ดังนั้นตอนนี้ `LoginPage` ที่เพิ่งสร้างยังไม่มีจุดไหนในแอปเรียกใช้เลย ให้แก้ `lib/main.dart` ในเมธอด `MyApp.build()` ชั่วคราวก่อน เปลี่ยนจาก `home: MainScaffold(...)` เป็น `home: const LoginPage()` 
**comment code `home: MainScaffold(...)` และอย่าลืม import หน้า LoginPage ด้วย**

เพื่อให้รันแอปแล้วเห็นหน้า Login ทันทีและทดสอบ Checkpoint 2.1 กับ Checkpoint 3.1 (ส่วนที่ 3) เมื่อทดสอบทั้งสอง Checkpoint เสร็จแล้ว **ให้เปลี่ยน `home:` กลับเป็น `MainScaffold(...)` เหมือนเดิมก่อนเริ่มส่วนที่ 4** เพราะส่วนที่ 4 จะสร้าง `AuthGate` มาแทนที่บรรทัดนี้แบบถาวร ไม่ต้องสลับไปมาด้วยการแก้ไขโค้ดอีก

> ✅ **Checkpoint 2.1** ทดสอบสมัครสมาชิกด้วย Email ใหม่สำเร็จ ถ่ายภาพหน้าจอ Firebase Console เมนู Authentication → Users ที่แสดงบัญชีที่เพิ่งสมัคร จากนั้นทดสอบกรณีผิดพลาด 2 กรณี คือ (ก) สมัครซ้ำด้วย Email เดิม และ (ข) ใส่รหัสผ่านสั้นเกินไป ถ่ายภาพหน้าจอข้อความ Error ทั้งสองกรณี พร้อมอธิบายว่าโค้ดส่วนใดใน `auth_service.dart` เป็นตัวจัดการแต่ละกรณี

``text
บันทึกรูปผลลัพธ์ที่นี่ และคำอธิบายของแต่ละกรณี



`

---

## ส่วนที่ 3: เข้าสู่ระบบด้วย Google Sign-In

### ขั้นตอนที่ 3.1: 🔧 ทำตามขั้นตอน — ตั้งค่า SHA-1 (Android)

Google Sign-In บน Android ต้องลงทะเบียน SHA-1 Fingerprint ของเครื่องที่ใช้ Debug ไว้ใน Firebase Console ก่อน มิเช่นนั้นแอปจะ Error ทันทีที่กดปุ่มเข้าสู่ระบบด้วย Google ทำตามลำดับนี้

**1) หา SHA-1 Fingerprint ของเครื่อง**

เปิด Terminal ที่ root ของโปรเจกต์ (`campus_marketplace_w7`) แล้วรัน

```bash
cd android && ./gradlew signingReport
```

รอให้ Gradle ประมวลผล (ครั้งแรกอาจใช้เวลาสักครู่) จะได้ผลลัพธ์ออกมาหลายช่วงแยกตาม Variant ประมาณนี้

```
> Task :app:signingReport
Variant: debug
Config: debug
Store: /Users/<ชื่อผู้ใช้>/.android/debug.keystore
Alias: AndroidDebugKey
MD5: ...
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA-256: ...
Valid until: ...

Variant: debugAndroidTest
...

Variant: release
...
```

ให้มองหาช่วงที่ขึ้นต้นด้วย **`Variant: debug`** (ช่วงแรกสุด ไม่ใช่ `debugAndroidTest` หรือ `release`) แล้วคัดลอกค่าทั้งบรรทัดที่อยู่หลัง `SHA1:` (รูปแบบเป็นเลขฐาน 16 คั่นด้วย `:` จำนวน 20 คู่) เก็บไว้

> 💡 ถ้ารันแล้วไม่เจอ `SHA1` ปรากฏเลย (เครื่องนี้ยังไม่เคยสร้าง Debug Keystore) ให้ลองรันแอปบน Emulator/เครื่องจริงสักครั้งก่อนด้วย `flutter run` ระบบจะสร้างไฟล์ `~/.android/debug.keystore` ให้อัตโนมัติ แล้วค่อยกลับมารัน `./gradlew signingReport` ใหม่

**2) นำ SHA-1 ไปลงทะเบียนใน Firebase Console**

เปิด Firebase Console ของโปรเจกต์ที่สร้างไว้ กดไอคอนรูปเฟือง ⚙️ ข้าง "Project Overview" มุมซ้ายบน แล้วเลือก **Project settings** เลื่อนลงมาที่ด้านล่างสุด ที่หัวข้อ **Your apps** จะเห็นการ์ดของแอป Android ที่ลงทะเบียนไว้ตอนรัน `flutterfire configure` (ขั้นตอนที่ 1.2) กดลิงก์ **Add fingerprint** ใต้การ์ดนั้น วาง SHA-1 ที่คัดลอกไว้ลงในช่อง แล้วกด **Save**

**3) ดาวน์โหลด google-services.json ใหม่มาทับไฟล์เดิม**

ในการ์ด Android แอปเดียวกันนั้น จะมีปุ่ม/ลิงก์ดาวน์โหลด **google-services.json** ไฟล์ที่ได้จะมีข้อมูล OAuth Client ของ SHA-1 ที่เพิ่งเพิ่มฝังอยู่ด้วย (ต่างจากไฟล์เดิมที่ได้จาก `flutterfire configure`) นำไฟล์นี้ไปทับไฟล์เดิมที่อยู่ในโฟลเดอร์ `android/app/google-services.json` ของโปรเจกต์ **ชื่อไฟล์ต้องตรงเป๊ะ ไม่ใช่ `google-services (1).json` หรือชื่ออื่น**

> ⚠️ ถ้าทดสอบ Google Sign-In บนหลายเครื่อง (Emulator, เครื่องจริง, หรือเครื่องของเพื่อนร่วมกลุ่ม) อย่าลืมว่า Debug Keystore ของแต่ละเครื่องมี SHA-1 ไม่เหมือนกัน ต้องทำซ้ำขั้นตอนที่ 1-3 นี้เพิ่ม SHA-1 ของทุกเครื่องที่จะใช้ทดสอบเข้าไปใน Firebase Console ได้ (กดปุ่ม "Add fingerprint" เพิ่มได้เรื่อย ๆ ไม่ต้องลบของเดิมออก)

**4) ล้าง Build เดิมแล้วรันแอปใหม่**

```bash
flutter clean
flutter pub get
flutter run
```

เพื่อให้แอป Build ใหม่ด้วยไฟล์ `google-services.json` เวอร์ชันล่าสุดที่เพิ่งทับไป ไม่เช่นนั้นแอปอาจยังใช้ค่าที่ Cache ไว้จากไฟล์เก่า


### ขั้นตอนที่ 3.2: 🔧 ทำตามขั้นตอน — เพิ่มเมธอด signInWithGoogle() ใน AuthService

เพิ่ม Import นี้ไว้ด้านบนของไฟล์ `lib/services/auth_service.dart` (ถ้ายังไม่มี)

```dart
import 'package:google_sign_in/google_sign_in.dart';
```

จากนั้นเพิ่มฟิลด์และเมธอดต่อไปนี้ในคลาส `AuthService` ต่อจาก `signUp`, `signIn`, `signOut` ที่เขียนไว้แล้วในขั้นตอนที่ 2.2 ตามโครงสร้างสมบูรณ์ในเนื้อหาสัปดาห์นี้หัวข้อ 9.4

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
bool _googleReady = false;

Future<void> _ensureGoogleReady() async {
  if (_googleReady) return;
  // initialize() ต้องเรียกครั้งเดียวก่อนใช้งานเมธอดอื่นของ GoogleSignIn เสมอ
  await _googleSignIn.initialize();
  _googleReady = true;
}

Future<void> signInWithGoogle() async {
  try {
    await _ensureGoogleReady();

    // authenticate() เปิดหน้าต่างให้ผู้ใช้เลือกบัญชี Google (แทนที่ signIn() ในเวอร์ชันเก่า)
    final googleUser = await _googleSignIn.authenticate();

    // idToken ได้แบบ synchronous จาก authentication ของบัญชีที่ล็อกอินแล้ว
    final idToken = googleUser.authentication.idToken;

    // accessToken ต้องขอเพิ่มผ่าน authorizationClient แยกต่างหาก
    final authorization = await googleUser.authorizationClient
        .authorizationForScopes(['email']);

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: authorization?.accessToken,
    );

    await _auth.signInWithCredential(credential);
  } on FirebaseAuthException catch (e) {
    throw Exception(_translateErrorCode(e.code)); // ตรวจสอบว่าชื่อ method คือ _translateErrorCode  หรือไม่ หากเป็นชื่ออื่น ให้แก้ไขให้ตรงกับชื่อ method
  }
}
```

> 💡 `try/catch` ดักจับเฉพาะ `FirebaseAuthException` เท่านั้น เหมือนกับที่ `signUp()`/`signIn()` ทำไว้แล้วในขั้นตอน 2.2 ส่วน `authenticate()` ที่ผู้ใช้กดยกเลิกเองจะโยน `GoogleSignInException` ไม่ใช่ `FirebaseAuthException` จึงไม่ถูกจับที่นี่ ปล่อยให้หลุดออกไปตามปกติ เพราะไม่ใช่ Error ที่มาจาก Firebase

> ⚠️ ถ้า `_translateErrorCode()` ที่เขียนไว้ในขั้นตอน 2.2 ยังไม่มี case สำหรับ `invalid-credential` ให้เพิ่มเข้าไปด้วย เพราะเป็น Error ที่พบได้บ่อยเมื่อ Credential จาก Google ไม่ถูกต้องหรือหมดอายุ

```dart
case 'invalid-credential':
  return 'ข้อมูลยืนยันตัวตนจาก Google ไม่ถูกต้องหรือหมดอายุ กรุณาลองเข้าสู่ระบบใหม่';
```

### ขั้นตอนที่ 3.3: 🔧 ทำตามขั้นตอน — เพิ่มปุ่ม "เข้าสู่ระบบด้วย Google" ในหน้า Login

ตอนนี้ `signInWithGoogle()` ใน `AuthService` พร้อมใช้งานแล้วจากขั้นตอนที่ 3.2 เหลือแค่เชื่อมเข้ากับหน้า `LoginPage` ที่สร้างไว้ในขั้นตอนที่ 2.3 ทำตามลำดับนี้

**1) เพิ่มเมธอดจัดการการกดปุ่มใน `_LoginPageState` ในไฟล์ login_page.dart**

เพิ่มเมธอดนี้ไว้ข้าง ๆ เมธอด `_submit()` เดิมที่ใช้กับ Email/Password (ใช้ `_isLoading` และ `_errorMessage` ตัวแปร State ชุดเดียวกับที่ `_submit()` ใช้อยู่แล้ว ถ้าตั้งชื่อไว้ต่างจากนี้ให้ปรับชื่อให้ตรงกับของตัวเอง)

```dart
Future<void> _signInWithGoogle() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    await AuthService().signInWithGoogle();
    // ไม่ต้อง Navigator.push ใด ๆ ที่นี่ — AuthGate ในส่วนที่ 4
    // จะตรวจพบสถานะล็อกอินใหม่จาก authStateChanges() แล้วสลับหน้าจอให้เอง
  } catch (e) {
    setState(() {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    });
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
```

> 💡 สังเกตว่าโค้ดนี้ไม่มี `Navigator.push`/`Navigator.pushReplacement` เลย เหมือนกับที่ `_submit()` ของ Email/Password ไม่มีเช่นกัน เพราะหน้าที่สลับจาก `LoginPage` ไป `MainScaffold` เป็นของ `AuthGate` (`StreamBuilder` ที่ฟัง `authStateChanges()`) ทั้งหมด ไม่ใช่หน้าที่ของ `LoginPage`

**2) เพิ่มปุ่มในส่วน `build()` ต่อจากปุ่มเข้าสู่ระบบ/สมัครสมาชิกเดิม**

ใส่ `Divider` คั่นแล้วตามด้วยปุ่ม Google ต่อท้ายปุ่ม Submit และ TextButton สลับโหมดที่มีอยู่แล้วใน `Column` ของฟอร์ม

```dart
const SizedBox(height: 16),
const Row(
  children: [
    Expanded(child: Divider()),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text('หรือ'),
    ),
    Expanded(child: Divider()),
  ],
),
const SizedBox(height: 16),
OutlinedButton.icon(
  onPressed: _isLoading ? null : _signInWithGoogle,
  icon: const Icon(Icons.g_mobiledata, size: 28),
  label: const Text('เข้าสู่ระบบด้วย Google'),
  style: OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(48),
  ),
),
```

> 💡 ใบงานนี้ไม่บังคับใช้โลโก้ Google ตัวจริงตาม Brand Guidelines (เป็นเรื่องของการขึ้น Production จริงเท่านั้น) ใช้ `Icon(Icons.g_mobiledata)` หรือไอคอนสามัญอื่น ๆ (เช่น `Icons.login`) แทนได้เลยเพื่อความง่าย สิ่งที่ต้องถูกต้องคือ Logic การเรียก `AuthService().signInWithGoogle()` ไม่ใช่หน้าตาไอคอน

**3) ปิดปุ่มระหว่าง Loading เหมือนปุ่ม Email/Password**

ปุ่ม Google ด้านบนใช้เงื่อนไข `onPressed: _isLoading ? null : _signInWithGoogle` อยู่แล้ว เพื่อป้องกันผู้ใช้กดซ้ำซ้อนระหว่างรอผลจาก Google ตรวจสอบว่าปุ่ม Submit เดิมของ Email/Password ก็มีเงื่อนไขแบบเดียวกันครบด้วย (ถ้ายังไม่มีให้เพิ่ม)

**4) ตรวจสอบการแสดง Error**

เนื่องจาก `_signInWithGoogle()` เซ็ตค่าลง `_errorMessage` ตัวแปรเดียวกับที่ใช้แสดง Error ของ Email/Password ส่วนแสดงผล Error เดิมในหน้าจอ (`if (_errorMessage != null) Text(_errorMessage!, ...)`) จะแสดง Error จากทั้งสองช่องทางโดยไม่ต้องเขียนโค้ดแสดง Error เพิ่มอีกชุด


**5) เตรียม Emulator ให้มีบัญชี Google ก่อนทดสอบ (สำคัญ ถ้าทดสอบบน Android Emulator)**

ขั้นตอนนี้มี 2 เงื่อนไขที่ต้องครบทั้งคู่ ถ้าขาดอันใดอันหนึ่งจะเจอ Error `GoogleSignInException(code GoogleSignInExceptionCode.unknownError, No credential available...)` ทันทีตอนกดปุ่ม "เข้าสู่ระบบด้วย Google"

**ก) ต้องใช้ AVD ที่สร้างจาก System Image แท็ก `google_apis_playstore` เท่านั้น (เช็คก่อนเสมอ)**

AVD ที่สร้างไว้ตั้งแต่ใบงานที่ 1/7 ด้วยแท็ก `google_apis` เฉย ๆ **ใช้ไม่ได้** เพราะไม่มีองค์ประกอบ Credential Manager ที่ `google_sign_in` เวอร์ชันนี้ต้องใช้ แม้จะเพิ่มบัญชี Google ได้สำเร็จก็ยัง Error อยู่ดี ตรวจสอบก่อนด้วยคำสั่งนี้

```bash
avdmanager list avd
```

ถ้ายังไม่มี AVD ที่ชื่อ Image ลงท้ายด้วย `google_apis_playstore` ให้สร้างใหม่ตามคำสั่งในหัวข้อ Troubleshooting ท้ายใบงาน หัวข้อ "No credential available" ก่อน แล้วค่อยทำข้อ ข) ต่อ

**ข) เพิ่มบัญชี Google ลงใน AVD ตัวนั้น**

1. เปิด AVD ที่ถูกต้อง (ลงท้ายด้วย `_PlayStore` หรือชื่อที่ตั้งเอง) รอจนบูตเสร็จเห็นหน้า Home จริง ๆ (ไม่มี Notification ค้างอยู่)
2. **ลากจากขอบล่างสุดของหน้าจอ Emulator ขึ้นด้านบน** (swipe up) เพื่อเปิด App Drawer — วิธีนี้ใช้งานได้เสถียรกว่าการลากจากด้านบนลงมา (Quick Settings) มาก แนะนำให้ใช้ท่านี้เป็นหลัก
3. แตะไอคอน **Play Store** (เร็วและชัวร์ที่สุด) แล้วล็อกอินด้วย Gmail ส่วนตัวตรงนั้นได้เลย ระบบจะเพิ่มบัญชีให้อัตโนมัติ — ถ้าไม่มีไอคอน Play Store ให้แตะไอคอน **Settings** แทน แล้วใช้ช่องค้นหาด้านบนของหน้า Settings พิมพ์คำว่า `account` กด **Add account → Google**
4. กดปุ่ม Home แล้วเปิดแอป Campus Marketplace ขึ้นมาใหม่ จากนั้นกดปุ่ม "เข้าสู่ระบบด้วย Google" เพื่อทดสอบ Checkpoint 3.1 ด้านล่าง

> 💡 ถ้าทำตามนี้ครบแล้วแต่ Emulator ยังมีอาการแปลก ๆ (ปุ่ม/ท่าทางบนหน้าจอไม่ตอบสนอง, ค้าง, ADB ค้าง) ให้ปิด Emulator แล้วเปิดใหม่ก่อน ถ้ายังไม่หาย ให้ข้ามไปทดสอบ Checkpoint 3.1 บน**เครื่อง Android จริง**แทนได้เลย (เสียบสาย USB เปิด USB Debugging แล้ว `flutter run` เลือกเครื่องจริง) จะข้ามปัญหาเรื่อง Emulator ทั้งหมดไปได้ทันที

> ✅ **Checkpoint 3.1** ทดสอบกดปุ่มเข้าสู่ระบบด้วย Google ด้วยบัญชี Google จริงของคุณ ถ่ายภาพหน้าจอตอนเลือกบัญชี Google และภาพหน้าจอ Firebase Console ที่แสดงว่ามีผู้ใช้ใหม่ Provider เป็น Google เพิ่มเข้ามา อธิบายว่า `idToken` กับ `accessToken` ที่ได้จาก Google นำไปใช้ทำอะไรต่อในขั้นตอนการยืนยันตัวตนกับ Firebase (อ้างอิงหัวข้อ 9.4)

```text
บันทึกรูปผลลัพธ์ที่นี่ และคำอธิบาย
```

---

## ส่วนที่ 4: AuthGate — สลับหน้าจอตามสถานะผู้ใช้

### ขั้นตอนที่ 4.1: 🔧 ทำตามขั้นตอน — สร้าง AuthGate Widget

สร้างไฟล์ `lib/screens/auth_gate.dart` เป็น `StreamBuilder<User?>` ที่ฟัง `FirebaseAuth.instance.authStateChanges()` ตามโครงสร้างสมบูรณ์ในเนื้อหาสัปดาห์นี้หัวข้อ 9.4 คอยสลับ 3 สถานะ ตาม Pseudocode นี้:

```
class AuthGate extends StatelessWidget:
    รับพารามิเตอร์: itemRepositories (List<ItemRepository>), favoritesRepository, draftRepository

    build(context):
        return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot):
                ถ้า snapshot ยังไม่มีข้อมูล (connectionState == waiting):
                    แสดง CircularProgressIndicator กลางจอ

                ถ้า snapshot.data เป็น null (ยังไม่ล็อกอิน):
                    แสดง LoginPage()

                ถ้า snapshot.data เป็น User จริง (ล็อกอินแล้ว):
                    แสดง MainScaffold(
                        itemRepositories: itemRepositories,
                        favoritesRepository: favoritesRepository,
                        draftRepository: draftRepository,
                    )
        )
```

เขียนเป็น Dart จริงได้ดังนี้ (ปรับ path ของ `import` ให้ตรงกับโครงสร้างโปรเจกต์ของตัวเองถ้าไม่ตรงกัน):

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../repositories/favorites_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/listing_draft_repository.dart';
import '../screens/login_page.dart';
import '../screens/main_scaffold.dart';

class AuthGate extends StatelessWidget {
  final List<ItemRepository> itemRepositories;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository;

  const AuthGate({
    super.key,
    required this.itemRepositories,
    required this.favoritesRepository,
    required this.draftRepository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // สถานะที่ 1: ยังรอผลจาก Stream รอบแรก (ตอนแอปเพิ่งเปิด)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // สถานะที่ 2: มีผลแล้ว แต่เป็น null → ยังไม่ล็อกอิน
        if (snapshot.data == null) {
          return const LoginPage();
        }

        // สถานะที่ 3: มีผลเป็น User จริง → ล็อกอินแล้ว
        return MainScaffold(
          itemRepository: itemRepositories.first, // ชั่วคราว — ดูหมายเหตุ ⚠️ ด้านล่าง
          favoritesRepository: favoritesRepository,
          draftRepository: draftRepository,
        );
      },
    );
  }
}
```

> 💡 `StreamBuilder` เรียก `builder` ใหม่ทุกครั้งที่ `authStateChanges()` ยิงค่าใหม่ออกมา (ล็อกอินสำเร็จ หรือกด "ออกจากระบบ") จึงไม่ต้องเขียน `Navigator.push`/`Navigator.pop` สลับหน้าด้วยมือเลยแม้แต่บรรทัดเดียว — ตรงกับที่ `_signIn`/`_signUp`/`_signInWithGoogle` ใน `LoginPage` (ขั้นตอนที่ 3.3) ไม่มี `Navigator` ใด ๆ อยู่เลยเช่นกัน
>
> ⚠️ ชื่อไฟล์ที่ import (`favorites_repository.dart`, `item_repository.dart`, `listing_draft_repository.dart`, `main_scaffold.dart`) อ้างอิงจากโครงสร้างที่สร้างไว้ตั้งแต่สัปดาห์ที่ 7-8 ถ้าโปรเจกต์ของตัวเองตั้งชื่อไฟล์หรือวางตำแหน่งต่างไปจากนี้ ให้แก้ Path ของ `import` ให้ตรงกับของจริงในเครื่อง ไม่ใช่คัดลอกไปวางตรง ๆ

จากนั้นแก้ `lib/main.dart` ในเมธอด `MyApp.build(context)` ให้เรียก `AuthGate` แทนที่จะเรียก `MainScaffold` ตรง ๆ (ตัวแปร `database` ที่รับมาจาก Constructor ของ `MyApp` ตั้งแต่สัปดาห์ที่ 8 ยังใช้ตัวเดิม ไม่ต้องสร้างใหม่หรือย้ายที่):

ก่อนแก้ (`lib/main.dart` — ภายใน `MyApp.build()`)

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Campus Marketplace',
    debugShowCheckedModeBanner: false,
    home: MainScaffold(
      itemRepository: ItemRepositoryApi(),
      favoritesRepository: FavoritesRepositoryDrift(database),
      draftRepository: ListingDraftRepositoryDrift(database),
    ),
  );
}
```

หลังแก้

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Campus Marketplace',
    debugShowCheckedModeBanner: false,
    home: AuthGate(
      itemRepositories: [ItemRepositoryApi()], // เพิ่ม ItemRepositoryFirestore() เข้าลิสต์นี้ทีหลัง — ดูหมายเหตุ ⚠️ ข้อ 2 ด้านล่าง
      favoritesRepository: FavoritesRepositoryDrift(database),
      draftRepository: ListingDraftRepositoryDrift(database),
    ),
  );
}
```

> ⚠️ **ขั้นตอนนี้ยังไม่สมบูรณ์ 100% ชั่วคราว** เพราะมีอีก 2 จุดที่ต้องย้อนกลับมาแก้ในขั้นตอนถัดไปของใบงาน (ไม่ใช่ความผิดพลาด แค่ยังไม่ถึงช่วงการแก้ไข) — ด้วยการแก้ชั่วคราวตามโค้ดด้านบนนี้ แอปจะ Build และรันผ่านได้ตั้งแต่ตอนนี้ ทดสอบ **Checkpoint 4.1** ได้ทันที ไม่ต้องรอส่วนที่ 5-6 ให้เสร็จก่อน
>
> 1. **`MainScaffold`** ยังรับพารามิเตอร์ `itemRepository` (ตัวเดียว) อยู่ ไม่ใช่ `itemRepositories` (List) จึงเป็นเหตุผลที่โค้ด `AuthGate.build()` ด้านบนใช้ `itemRepository: itemRepositories.first` ไปพลางก่อน การแก้ `MainScaffold`/`HomePage` ให้รองรับ List จริงอยู่ในขั้นตอนที่ 5.3 **เมื่อแก้เสร็จแล้ว อย่าลืมย้อนกลับมาเปลี่ยนบรรทัดนี้ใน `auth_gate.dart` เป็น `itemRepositories: itemRepositories` ด้วย**
> 2. **`main.dart`** ด้านบนยังใส่แค่ `ItemRepositoryApi()` ใน List เพราะ `ItemRepositoryFirestore` (ขั้นตอนที่ 5.2) ต้องพึ่ง `Item.fromFirestore()`/`toFirestore()` ที่เพิ่งจะเขียนในขั้นตอนที่ 6.2 ด้วย ถ้าใส่ `ItemRepositoryFirestore()` เข้าไปตอนนี้โค้ดจะคอมไพล์ไม่ผ่าน ให้เพิ่มเข้าไปในลิสต์นี้หลังทำขั้นตอนที่ 6.2 เสร็จเท่านั้น

### ขั้นตอนที่ 4.2: 🔧 ทำตามขั้นตอน — เพิ่มปุ่มออกจากระบบ

เพิ่มปุ่ม "ออกจากระบบ" ใน AppBar ของ `HomePage` ที่เรียก `AuthService().signOut()`

> ✅ **Checkpoint 4.1** ถ่ายภาพหน้าจอ 3 ภาพเรียงกัน คือ (ก) แอปตอนเพิ่งเปิดขึ้นมาครั้งแรกแบบยังไม่ล็อกอิน แสดงหน้า Login (ข) หลังล็อกอินสำเร็จ แอปสลับไปแสดง `MainScaffold` อัตโนมัติโดยไม่ต้องกดอะไรเพิ่ม และ (ค) หลังกด "ออกจากระบบ" แอปสลับกลับไปหน้า Login เอง อธิบายว่าทำไมการใช้ `StreamBuilder` ฟัง `authStateChanges()` จึงทำให้ไม่ต้องเขียนโค้ดสั่ง Navigate ไปมาเอง


```text
บันทึกรูปผลลัพธ์ที่นี่ (3 ภาพ) และคำอธิบาย
```

---

## ส่วนที่ 5: ขยาย Repository Pattern ด้วย ItemRepositoryFirestore

### ขั้นตอนที่ 5.1: 🧠 คิดเอง

ก่อนเขียนโค้ด ให้ตอบคำถามต่อไปนี้ (อ้างอิง `campus_marketplace_lab_roadmap.md` ข้อ 5.6 และเนื้อหาหัวข้อ 9.5):

1. ทำไมเราจึง "เพิ่ม Implementation ใหม่" (`ItemRepositoryFirestore`) แทนที่จะแก้ไข `ItemRepositoryApi` เดิม หรือเขียนโค้ดเรียก Firestore ตรงจาก `HomePage`?
2. ถ้าในอนาคตอาจารย์สั่งให้เปลี่ยนจาก Fake Store API ไปใช้ API อื่น ต้องแก้ไฟล์กี่ไฟล์ ถ้าทุก Widget เรียกผ่าน Interface `ItemRepository` เท่านั้น?

```text
บันทึกคำตอบของคุณที่นี่
```

### ขั้นตอนที่ 5.2: **นักศึกษาเขียน Code เอง** — ItemRepositoryFirestore

สร้างไฟล์ `lib/repositories/item_repository_firestore.dart` ตามโครงสร้างในเนื้อหาสัปดาห์นี้หัวข้อ 9.5-9.6

**ข้อกำหนดที่ต้องมีครบ (ตรวจสอบตัวเองก่อนไปต่อ):**

- `class ItemRepositoryFirestore implements ItemRepository` — Interface เดิมจากสัปดาห์ที่ 6 **ห้ามแก้ไข**
- `Future<List<Item>> getItems()` อ่านทุกเอกสารใน Collection `items` ครั้งเดียวด้วย `.get()` แล้วแปลงเป็น `List<Item>` (ทำให้ `HomePage` เรียกใช้งานได้เหมือน `ItemRepositoryApi` ทุกประการโดยไม่ต้องรู้ว่าเบื้องหลังเป็น Firestore)
- `Future<void> postItem(Item item)` เขียนเอกสารใหม่ลง Collection `items`
- `Stream<List<Item>> watchMyListings(String sellerId)` ใช้ `.snapshots()` ฟังเฉพาะเอกสารที่ `sellerId` ตรงกับพารามิเตอร์ แบบ Real-time (ไม่ใช่ `.get()` ครั้งเดียว)

### ขั้นตอนที่ 5.3: 🔧 ทำตามขั้นตอน — รวมสินค้าจาก API และ Firestore บนหน้า Home

แก้ `MainScaffold` และ `HomePage` ให้รับ `List<ItemRepository>` แทนตัวเดียว ตามนี้

ก่อนแก้ (`main_scaffold.dart`)

```dart
class MainScaffold extends StatefulWidget {
  final ItemRepository itemRepository;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository;
  const MainScaffold({
    super.key,
    required this.itemRepository,
    required this.favoritesRepository,
    required this.draftRepository,
  });
  ...
}

// ใน build():
final pages = [
  HomePage(repository: widget.itemRepository, favoritesRepository: widget.favoritesRepository),
  SellItemPage(draftRepository: widget.draftRepository),
  FavoritesPage(repository: widget.favoritesRepository),
];
```

หลังแก้

```dart
class MainScaffold extends StatefulWidget {
  final List<ItemRepository> itemRepositories;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository;
  const MainScaffold({
    super.key,
    required this.itemRepositories,
    required this.favoritesRepository,
    required this.draftRepository,
  });
  ...
}

// ใน build():
final pages = [
  HomePage(repositories: widget.itemRepositories, favoritesRepository: widget.favoritesRepository),
  SellItemPage(draftRepository: widget.draftRepository),
  FavoritesPage(repository: widget.favoritesRepository),
];
```

และแก้ `HomePage` ให้เรียก `getItems()` จากทุก Repository ใน List พร้อมกันด้วย `Future.wait(...)` แล้วรวมผลลัพธ์เป็น List เดียวก่อนส่งให้ `ListView.builder` ใส่ Badge หรือไอคอนเล็ก ๆ บน `ItemCard` เพื่อบอกผู้ใช้ว่าแต่ละรายการมาจากแหล่งใด (เช่น 🏪 = จาก API, 🎓 = โพสต์จริงโดยนักศึกษา)

> 🔧 **อย่าลืมแก้ `auth_gate.dart` ด้วย** ตอนนี้ `MainScaffold` รับ `itemRepositories` (List) แล้ว ให้กลับไปเปลี่ยนบรรทัด `itemRepository: itemRepositories.first` ใน `AuthGate.build()` (ขั้นตอนที่ 4.1) เป็น `itemRepositories: itemRepositories` ตามเดิม ไม่เช่นนั้นจะเกิด Error ตรงกันข้ามกับก่อนหน้านี้ (ส่งพารามิเตอร์ชื่อ `itemRepository` ที่ `MainScaffold` ไม่รู้จักอีกต่อไป)

> ✅ **Checkpoint 5.1** ถ่ายภาพหน้าจอ Home ที่แสดงสินค้าจากทั้งสองแหล่งข้อมูลปนกันอยู่ในลิสต์เดียว พร้อม Badge ที่แยกแหล่งที่มาชัดเจน (ถ้ายังไม่เคยมีประกาศจริงใน Firestore เลย ให้ทำส่วนที่ 6 ให้เสร็จก่อนแล้วย้อนกลับมาถ่ายภาพ Checkpoint นี้) อธิบายว่าการออกแบบให้ `HomePage` ไม่รู้จัก `ItemRepositoryApi`/`ItemRepositoryFirestore` โดยตรง แต่รู้จักผ่าน Interface `ItemRepository` เท่านั้น ช่วยให้ทดสอบหรือเปลี่ยนแหล่งข้อมูลในอนาคตง่ายขึ้นอย่างไร

```text
บันทึกรูปผลลัพธ์ที่นี่ และคำอธิบาย
```

---

## ส่วนที่ 6: "โพสต์ขายจริง" — เชื่อม MyDraftsPage เข้ากับ Storage และ Firestore

### ขั้นตอนที่ 6.1: **นักศึกษาเขียน Code เอง** — StorageService

สร้างไฟล์ `lib/services/storage_service.dart` ตามโครงสร้างในหัวข้อ 9.7-9.8

**ข้อกำหนดที่ต้องมีครบ (ตรวจสอบตัวเองก่อนไปต่อ):**

- มีเมธอด `Future<String> uploadListingImage(File imageFile, String sellerId)` คืนค่าเป็น Download URL
- ตั้งชื่อไฟล์บน Storage ให้ไม่ซ้ำกัน (เช่น ใช้ `sellerId` ผสมกับ `DateTime.now().millisecondsSinceEpoch`) ไม่ใช่ใช้ชื่อไฟล์เดิมจากเครื่องผู้ใช้ตรง ๆ
- เรียก `getDownloadURL()` **หลังจาก** `putFile()` อัปโหลดเสร็จสมบูรณ์แล้วเท่านั้น (ต้อง `await` ให้ถูกจุด)

### ขั้นตอนที่ 6.2: 🧠 คิดเอง (มีโครงให้) — เพิ่ม sellerId ให้ Item และแปลงเป็น Firestore ได้

`ListingDraft` จากสัปดาห์ที่ 7 (`title`, `category`, `description`) และตาราง `ListingDrafts` จากสัปดาห์ที่ 8 (`title`, `category`, `description`, `imagePath`) **ไม่มี field ราคาเลย** ส่วนคลาส `Item` ก็ยังไม่มี `sellerId` ใช้ Pseudocode นี้เป็นโครงในการแก้ไข:

```
แก้ไข class Item (lib/models/item.dart):
    เพิ่ม field ใหม่: final String? sellerId   // nullable เพราะสินค้าจาก Fake Store API ไม่มี sellerId

    เพิ่มเมธอด toFirestore() -> Map<String, dynamic>:
        คืนค่า Map ที่มี key ตรงกับชื่อ field ทั้งหมด (title, price, description, category, imageUrl, sellerId)

    เพิ่ม factory Item.fromFirestore(DocumentSnapshot doc):
        อ่านค่าจาก doc.data() เป็น Map แล้วสร้าง Item กลับมา
        ใส่ doc.id เป็น id ของ Item ด้วย (ต่างจาก fromJson ของสัปดาห์ที่ 7 ที่ไม่มี id จาก API)
```

> 🔧 **อย่าลืมแก้ `main.dart` ด้วย** ตอนนี้ `Item.fromFirestore()`/`toFirestore()` มีครบแล้ว ให้กลับไปเพิ่ม `ItemRepositoryFirestore()` เข้าไปในลิสต์ `itemRepositories: [...]` ที่ `AuthGate(...)` ใน `lib/main.dart` (ขั้นตอนที่ 4.1) ให้เป็น `itemRepositories: [ItemRepositoryApi(), ItemRepositoryFirestore()]` ตามที่ตั้งใจไว้ตั้งแต่แรก ไม่เช่นนั้นหน้า Home จะยังแสดงสินค้าจาก Fake Store API อย่างเดียว ไม่เห็นประกาศที่โพสต์ผ่าน Firestore เลย

> 💡 เพราะร่างประกาศ (`ListingDraftRow`) ไม่มีราคาเก็บไว้ ตอนกด "โพสต์ขายจริง" ในขั้นตอนถัดไปจึงต้อง**ถามราคาจากผู้ใช้ก่อนเสมอ** ด้วย Dialog — ไม่ใช่ดึงราคาจากร่างโดยตรงเพราะไม่มีให้ดึง

### ขั้นตอนที่ 6.3: **นักศึกษาเขียน Code เอง** — ปุ่ม "โพสต์ขายจริง" ใน MyDraftsPage

เพิ่มปุ่ม "โพสต์ขายจริง" ใน `ListTile` ของแต่ละร่างในหน้า `MyDraftsPage` (จากสัปดาห์ที่ 8) ที่ทำตามลำดับนี้เมื่อกด

**ข้อกำหนดที่ต้องมีครบ (ตรวจสอบตัวเองก่อนไปต่อ):**

- แสดง Dialog ถามราคาสินค้าก่อนเสมอ (เพราะร่างไม่มีราคาติดมา) ตรวจสอบว่ากรอกเป็นตัวเลขและมากกว่า 0
- อัปโหลดรูปจาก `draft.imagePath` ขึ้น Storage ผ่าน `StorageService().uploadListingImage(...)` **ก่อน** รอรับ Download URL แล้วค่อยเขียนเอกสารลง Firestore พร้อม URL นั้น (ห้ามสลับลำดับ เพราะ Firestore ต้องมี URL ที่ใช้งานได้จริงตั้งแต่ตอนสร้างเอกสาร)
- สร้าง `Item` จากข้อมูลร่าง + ราคาที่กรอก + `sellerId: FirebaseAuth.instance.currentUser!.uid` แล้วเรียก `ItemRepositoryFirestore().postItem(item)`
- หลังโพสต์สำเร็จ เรียก `draftRepository.deleteDraft(draft.id)` ลบร่างออกจาก Local Database แล้ว Refresh รายการร่างบนหน้าจอ (ป้องกันไม่ให้กดโพสต์ซ้ำร่างเดิมสองครั้ง) และแสดง SnackBar ยืนยัน
- ระหว่างอัปโหลดให้แสดง Progress Indicator ตามที่อธิบายไว้ในหัวข้อ 9.7

> ✅ **Checkpoint 6.1** โพสต์ขายจริงอย่างน้อย 2 รายการผ่านแอป ถ่ายภาพหน้าจอ Firebase Console เมนู Firestore Database ที่แสดง Collection `items` มีเอกสารที่โพสต์เข้ามาจริง พร้อม field `sellerId` ที่ตรงกับ `uid` ของบัญชีที่ใช้ทดสอบ และยืนยันว่าร่างทั้งสองรายการหายไปจาก `MyDraftsPage` แล้ว

```text
บันทึกรูปผลลัพธ์ที่นี่
```

> ✅ **Checkpoint 6.2** ถ่ายภาพหน้าจอ Firebase Console เมนู Storage ที่แสดงไฟล์รูปภาพที่อัปโหลดสำเร็จ และภาพหน้าจอ Firestore ที่แสดงว่าเอกสารมี field `imageUrl` เป็น URL จริงที่เปิดดูได้ ถ่ายภาพหน้าจอแอปที่แสดงรูปสินค้านั้นบนหน้า Home ผ่าน `Image.network(imageUrl)` ด้วย (ย้อนกลับไปถ่ายภาพ Checkpoint 5.1 ให้ครบตอนนี้ ถ้ายังไม่ได้ทำ)

```text
บันทึกรูปผลลัพธ์ที่นี่
```

---

## ส่วนที่ 7 (Self-Study): สำรวจ Firebase Security Rules

ส่วนนี้เป็นการศึกษาด้วยตนเองเพิ่มเติมจากที่กล่าวถึงสั้น ๆ ในเนื้อหาหัวข้อ 9.9 ไม่ใช่แกนหลักของใบงาน แต่**สำคัญมากสำหรับการทำแอปจริง**เพราะโค้ด Flutter ทั้งหมดที่เขียนมาในส่วนที่ 1-6 ยังไม่ได้ป้องกันไม่ให้ผู้ใช้คนหนึ่งแก้ไข/ลบประกาศของอีกคนหนึ่งเลย (เพียงแค่ UI ไม่มีปุ่มให้กดเท่านั้น ผู้ที่เขียนโค้ดเรียก Firestore เองโดยตรงยังทำได้อยู่)

### ขั้นตอนที่ 7.1: 🔧 ทำตามขั้นตอน — ทดลองแก้ Rules เบื้องต้น

ใน Firebase Console ไปที่ Firestore Database → Rules แก้ไข Rules ของ Collection `items` ให้เป็น

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /items/{itemId} {
      allow read: if true;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.sellerId;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.sellerId;
    }
  }
}
```

กด **Publish** แล้วใช้แท็บ **Rules Playground** ในหน้าเดียวกันทดลองจำลอง 2 กรณี คือ (ก) ผู้ใช้ที่ล็อกอินพยายามแก้ไขเอกสารที่ตัวเอง `sellerId` ตรงกัน (ควรผ่าน) และ (ข) ผู้ใช้คนเดียวกันพยายามแก้ไขเอกสารของคนอื่น (ควรถูกปฏิเสธ)

> ⚠️ ถ้า Checkpoint 6.1 ยังไม่เคยโพสต์ผ่านมาก่อนเลย ให้ Publish Rules นี้ **หลังจาก** โพสต์ขายจริงสำเร็จไปแล้วอย่างน้อย 1 รายการ เพราะ Rules ชุดนี้บังคับว่าต้องมี `sellerId` ตรงกับผู้เขียนเสมอ ถ้าโค้ดในส่วนที่ 6 ยังไม่แนบ `sellerId` ให้ถูกต้อง การโพสต์ครั้งต่อไปจะล้มเหลวด้วย `permission-denied` ทันที

> ✅ **Checkpoint 7.1 (Self-Study)** ถ่ายภาพหน้าจอผลการทดลองทั้ง 2 กรณีใน Rules Playground เขียนอธิบายสั้น ๆ ว่าทำไม Client-side Validation (การไม่แสดงปุ่มแก้ไขให้เห็น) เพียงอย่างเดียวจึงไม่เพียงพอต่อความปลอดภัยของข้อมูลจริง

```text
บันทึกรูปผลลัพธ์ที่นี่ และคำอธิบาย
```

---

## ส่วนที่ 8: ทดสอบสถานการณ์ Offline และสถานะการล็อกอิน

### ขั้นตอนที่ 8.1: 🔧 ทำตามขั้นตอน

ทดสอบทีละกรณีต่อไปนี้

1. ล็อกอินค้างไว้ แล้วปิดแอปทิ้งไปทั้งหมด (ไม่ใช่แค่ย่อ) จากนั้นเปิดแอปใหม่อีกครั้ง — ควรเข้าหน้า `MainScaffold` ทันทีโดยไม่ต้องล็อกอินซ้ำ (Firebase Auth จำสถานะล็อกอินไว้ให้อัตโนมัติ)
2. ปิด WiFi/Data ของเครื่องให้หมด แล้วลองเปิดแท็บ "รายการโปรด" และ "ร่างของฉัน" — ควรยังใช้งานได้ปกติเพราะเก็บอยู่ใน Local Database (Drift) ไม่ต้องพึ่งเครือข่าย
3. ขณะยังปิดเครือข่ายอยู่ ลองกด "โพสต์ขายจริง" กับร่างสักชิ้น — ควรเกิด Error เพราะ Firestore/Storage ต้องการเครือข่ายเสมอ (ต่างจาก Local Database) ตรวจสอบว่าแอปแสดงข้อความ Error ที่เข้าใจได้ ไม่ Crash
4. เปิดเครือข่ายกลับมา แล้วลองกด "โพสต์ขายจริง" รายการเดิมอีกครั้ง — ควรสำเร็จตามปกติ

> ✅ **Checkpoint 8.1** ถ่ายภาพหน้าจอผลการทดสอบทั้ง 4 ข้อ 

```text
บันทึกรูปผลลัพธ์ที่นี่ 
```

---

## ปัญหาที่พบบ่อยและวิธีแก้ไข (Troubleshooting)

**Error `[core/no-app]` หรือ `Firebase has not been correctly initialized`** มักเกิดจากลืมเรียก `await Firebase.initializeApp(...)` ก่อน `runApp()` หรือลืม `WidgetsFlutterBinding.ensureInitialized()` ที่บรรทัดแรกสุดของ `main()` ตรวจสอบลำดับโค้ดในขั้นตอน 1.3 อีกครั้ง

**รัน `./gradlew signingReport` แล้ว Build Failed ด้วย `IllegalArgumentException` ตามด้วยตัวเลขแปลก ๆ (เช่น `26.0.2`) โดยไม่มีคำอธิบายอื่นเลย** ไม่เกี่ยวกับ Flutter หรือ Firebase โดยตรง แต่เกิดจากเครื่องใช้ JDK เวอร์ชันใหม่เกินไป (เช่น Java 26 รุ่นทดลอง) ที่ตัว Kotlin Compiler ซึ่งฝังมากับ Gradle ยัง Parse เลขเวอร์ชันแบบนี้ไม่ได้ แก้โดยสั่งให้ Gradle ของโปรเจกต์นี้ใช้ JDK 17 แยกต่างหาก (ใบงานนี้ไม่ได้ติดตั้ง Android Studio ตามใบงานที่ 1 จึงใช้ JDK ที่ติดตั้งแยกแทน) ติดตั้งด้วย

```bash
# macOS
brew install --cask temurin@17

# Windows
winget install Microsoft.OpenJDK.17
```

จากนั้นเพิ่มบรรทัดนี้ต่อท้ายไฟล์ `android/gradle.properties` ให้ตรงกับ Path จริงในเครื่อง

```
org.gradle.java.home=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
```

(Mac ที่ติดตั้งผ่าน Homebrew Path มักอยู่ที่ `/opt/homebrew/opt/openjdk@17` หรือ `/usr/local/opt/openjdk@17` ถ้าไม่แน่ใจใช้คำสั่ง `/usr/libexec/java_home -V` เพื่อดู Path JDK ทั้งหมดที่ติดตั้งไว้ในเครื่อง ส่วน Windows มักอยู่ที่ `C:\Program Files\Eclipse Adoptium\jdk-17...` — ถ้าเครื่องไหนบังเอิญมี Android Studio ติดตั้งอยู่ด้วย ใช้ `.../Android Studio.app/Contents/jbr/Contents/Home` แทนก็ได้เช่นกัน) จากนั้นรัน `./gradlew signingReport` ใหม่อีกครั้ง

**Google Sign-In ขึ้น Error `ApiException: 10` บน Android** เกือบทุกครั้งเกิดจากยังไม่ได้เพิ่ม SHA-1 Fingerprint ใน Firebase Console หรือเพิ่มแล้วแต่ยังไม่ได้ดาวน์โหลด `google-services.json` ใหม่มาทับไฟล์เดิม ให้ทำซ้ำขั้นตอนที่ 3.1 อย่างครบถ้วน และรัน `flutter clean` ก่อนรันแอปใหม่

**กดปุ่ม "เข้าสู่ระบบด้วย Google" แล้วขึ้น `GoogleSignInException(code GoogleSignInExceptionCode.unknownError, No credential available...)` บน Emulator ทั้งที่เพิ่มบัญชี Google ผ่าน Settings ไปแล้ว (เพิ่มซ้ำแล้วระบบบอกว่ามีบัญชีนี้อยู่แล้วด้วย)** ไม่ได้เกี่ยวกับ SHA-1 หรือโค้ดเลย แต่เกิดจาก AVD (Android Virtual Device) ที่ใช้สร้างจาก System Image แบบ **"Google APIs"** (ไม่ใช่ "Google Play") Image แบบนี้ให้เพิ่มบัญชี Google ผ่าน Settings ได้จริง (สำหรับ Sync อีเมล/ปฏิทินทั่วไป) แต่ **ไม่มีองค์ประกอบ Credential Manager** ที่ `google_sign_in` เวอร์ชัน 7.x ใช้แสดงหน้าต่างเลือกบัญชี ซึ่งผูกอยู่กับ Google Play Services เวอร์ชันที่มากับ Image แบบ Google Play เท่านั้น ต่อให้มีบัญชีในเครื่องจริงก็ยังเจอ Error นี้อยู่ดี แก้โดยสร้าง AVD ใหม่:

ใบงานนี้ (เหมือนใบงานที่ 1 และ 7) ตั้งใจใช้ **Android SDK Command-line Tools** แทน Android Studio เพื่อประหยัดพื้นที่เครื่อง ดังนั้นให้สร้าง AVD ใหม่ด้วย `avdmanager` ผ่าน Terminal ใน VS Code เหมือนเดิม แต่เปลี่ยนแท็ก System Image จาก `google_apis` เป็น **`google_apis_playstore`** (ตัวที่มี Play Store/Credential Manager ติดมาด้วย):

```bash
# Windows หรือ Mac ชิป Intel (x86_64)
sdkmanager "system-images;android-34;google_apis_playstore;x86_64"
avdmanager create avd --name "Pixel7_API34_PlayStore" --package "system-images;android-34;google_apis_playstore;x86_64" --device "pixel_7"

# Mac ชิป Apple Silicon (arm64) — ใช้ตัวนี้แทน
sdkmanager "system-images;android-34;google_apis_playstore;arm64-v8a"
avdmanager create avd --name "Pixel7_API34_PlayStore" --package "system-images;android-34;google_apis_playstore;arm64-v8a" --device "pixel_7"
```

เปิด AVD ตัวใหม่นี้แทนตัวเดิม

```bash
emulator -avd Pixel7_API34_PlayStore
```

แล้วทำ Add account → Google ใหม่อีกครั้งบนเครื่องนี้ (ดูขั้นตอนที่ 3.3 ข้อ 5) — AVD ตัวนี้จะมีแอป Play Store ติดมาด้วย ล็อกอินผ่าน Play Store โดยตรงก็ได้เช่นกัน

> 💡 ถ้าไม่อยากเสียเวลาสร้าง AVD ใหม่ ทดสอบ Checkpoint 3.1 บน**เครื่อง Android จริง**แทนได้เลย (เสียบสาย USB เปิด USB Debugging) เพราะเครื่องจริงมี Google Play Services เต็มรูปแบบอยู่แล้ว ไม่ต้องกังวลเรื่อง Image แบบไหนเลย


**เข้าสู่ระบบด้วย Google สำเร็จ แต่ `FirebaseAuth.instance.signInWithCredential()` โยน Error `invalid-credential`** ตรวจสอบว่าเปิดใช้งาน Google เป็น Sign-in Method ใน Firebase Console แล้วจริง (ขั้นตอน 2.1) และตรวจสอบว่าดึง `idToken` มาจาก `googleUser.authentication.idToken` ไม่ใช่ดึงผิดตัวจาก `authorizationClient`

**Error `permission-denied` ตอนกด "โพสต์ขายจริง"** ถ้ายังไม่ได้แก้ Rules ตามส่วนที่ 7 ค่าเริ่มต้นของ Firestore Project ใหม่มักตั้งเป็นโหมด Test Mode ที่หมดอายุใน 30 วัน หรือโหมด Locked ที่ปฏิเสธทุกคำขอ แต่ถ้าแก้ Rules ไปแล้วยัง Error อยู่ ให้ตรวจสอบว่าโค้ดในขั้นตอน 6.3 แนบ `sellerId: FirebaseAuth.instance.currentUser!.uid` ไปกับทุกเอกสารที่สร้างจริงหรือไม่

**กด "โพสต์ขายจริง" ซ้ำสองครั้งแล้วได้สินค้าซ้ำกันสองชิ้นใน Firestore** มักเกิดจากลืมเรียก `draftRepository.deleteDraft(draft.id)` หลังโพสต์สำเร็จ หรือเรียกแล้วแต่ไม่ได้ Refresh รายการบนหน้าจอ ทำให้ผู้ใช้มองไม่เห็นว่าร่างหายไปแล้วและกดปุ่มซ้ำ

**รูปภาพอัปโหลดขึ้น Storage สำเร็จ แต่ `Image.network(imageUrl)` ไม่แสดงผลในแอป** ตรวจสอบว่าโค้ดเรียก `getDownloadURL()` **หลังจาก** `putFile()` อัปโหลดเสร็จสมบูรณ์แล้วจริง (ต้อง `await` ให้ถูกจุด) ไม่ใช่เรียกคู่ขนานกันไป

**แอป Crash ตอนเปิดหน้า "ร่างของฉัน" หรือหน้าดูประกาศของตัวเอง ด้วย Error เกี่ยวกับ Index** Firestore ต้องการ Composite Index เมื่อ Query ที่ซับซ้อน (เช่น `where` ร่วมกับ `orderBy` มากกว่า 1 field) ข้อความ Error จาก Firestore มักแนบลิงก์ให้กดสร้าง Index อัตโนมัติมาด้วยเสมอ ให้กดลิงก์นั้นแล้วรอสักครู่ให้ Index สร้างเสร็จ

---
