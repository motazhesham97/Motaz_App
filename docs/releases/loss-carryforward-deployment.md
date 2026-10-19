# إصلاح التحليل وخطوات ترحيل الخسائر والنشر والبناء

تاريخ التحقق: 2026-10-19. مجلد المشروع: `D:\dev\Motaz_App`.

هذه أوامر لتنفذها يدويًا. لم أنفذ commit أو push أو نشر Railway أو ترحيل Neon أو بناء EXE/APK في هذا الإصلاح. لا تنفذ كل البدائل معًا، وتوقف عند فشل أي خطوة.

## 1. ما أصلحته وما اختبرته

- إضافة الأقواس للمواضع الخمسة المذكورة في التحليل.
- استخدام عنصر Map واعٍ بـ null في معامل `afterId`، دون تغيير معنى ترقيم صفحات السحب.
- إضافة `await` لفحص تبعية المستفيد داخل `try` حتى تصل الأخطاء غير المتزامنة إلى `catch` المقصود.
- نجاح 13 اختبارًا مركّزًا للتوزيع والمزامنة، ثم نجاح مجموعة Flutter كاملة: 88 اختبارًا.
- نجاح 19 اختبارًا لخدمات الخادم والعقود دون قاعدة إنتاج. لم أعد تشغيل اختبارات PostgreSQL في هذه الجولة؛ سبق نجاح مجموعة الخادم كاملة (26) وتطبيق الترحيل على قاعدة الاختبار المحلية في الجولة السابقة.
- نجاح `git diff --check`. لم أشغّل analyze أو format بحسب طلبك؛ أعد تشغيل التحليل للتأكد من اختفاء الملاحظات.
- عبارة `packages have newer versions` ليست فشلًا؛ لا نحتاج ترقية الاعتمادات لإتمام هذه الإضافة.

## 2. إعادة التحليل يدويًا

نفّذ من PowerShell، ولا تكمل النشر إذا بقي warning أو error غير مفهوم:

```powershell
Set-Location D:\dev\Motaz_App\motaz_app\motaz_app_server
dart analyze
Set-Location ..\motaz_app_client
dart analyze
Set-Location ..\motaz_app_flutter
flutter analyze --no-pub
```

إذا أردت تنسيق المواضع التي أصلحتها فقط:

```powershell
Set-Location D:\dev\Motaz_App
dart format motaz_app/motaz_app_server/lib/src/services/sync_service.dart motaz_app/motaz_app_flutter/lib/features/profit_distribution/data/distribution_repository.dart motaz_app/motaz_app_flutter/lib/features/sync/application/outbox_processor.dart motaz_app/motaz_app_flutter/test/features/sync/monthly_settlement_sync_test.dart
```

## 3. التحضير قبل نشر الخادم

1. أغلق النسختين القديمتين على الهاتف والكمبيوتر إلى أن يُحدَّث الخادم وتُثبت النسختان الجديدتان. لا تمسح بيانات الجهازين ولا تحذف التطبيق.
2. إذا دخلت بيانات مهمة منذ تفريغ القاعدة، صدّر نسخة محلية من كل جهاز وأنشئ فرع احتياط في Neon من فرع الإنتاج الحالي. فرع Neon نسخة مستقلة؛ إنشاء فرع لا يطبق ترحيلًا على فرع الإنتاج. لا ترسل كلمات المرور هنا.
3. راجع Railway > خدمة `Motaz_App` > Settings > Source: المستودع الصحيح والفرع المتابع. الفرع المحلي الحالي هو `009-hardening-release` وليس `main`.
4. احتفظ بإعداد Root Directory الخاص بخدمة المشروع `motaz_app` وDockerfile `motaz_app_server/Dockerfile` كما في الإعداد العامل. لا تجعل مجلد Flutter هو جذر خدمة الخادم.
5. في Variables تأكد من `runmode=production` إن كان محددًا، ومن أن `SERVERPOD_DATABASE_HOST/NAME/USER` وكلمة مرور قاعدة البيانات تخص فرع Neon المطلوب. استخدم اتصال Neon المباشر للترحيل كما ينص config/production.yaml في هذا المشروع، وليس اسم المضيف المحتوي على `-pooler`. لا تغيّر أسرار JWT أو pepper أو serviceSecret عند هذا التحديث.
6. تأكد من عدم وجود Start Command مخصص يلغي `--apply-migrations`. الإعداد الافتراضي في Dockerfile وentrypoint يمرّر العلم تلقائيًا؛ لا تضف عملية ترحيل ثانية متزامنة أو شغّل خادم إنتاج آخر على الكمبيوتر.

## 4. الرفع إلى GitHub

نفّذ بعد نجاح التحليل. الأوامر التالية تضم تغييرات التطبيق والخادم والاختبارات والمواصفة والترحيل، ولا تستخدم `git add .`؛ تترك تغييرات الأدوات المحلية و`skills-lock.json` وSQL مسح البيانات خارج هذا الالتزام. راجع أي ملفات سبق لك staging لها؛ `git commit` يتضمن كل ما في staging وليس هذه القائمة فقط.

```powershell
Set-Location D:\dev\Motaz_App
git branch --show-current
git status --short
git add -- .specify/memory/constitution.md docs specs/006-expenses-profit/spec.md specs/010-loss-carryforward
git add -- motaz_app/motaz_app_client/lib motaz_app/motaz_app_flutter/lib motaz_app/motaz_app_flutter/test motaz_app/motaz_app_flutter/analysis_options.yaml
git add -- motaz_app/motaz_app_server/lib motaz_app/motaz_app_server/migrations motaz_app/motaz_app_server/test
git diff --cached --check
git diff --cached --stat
git commit -m "feat: add monthly loss carryforward and fix sync analysis warnings"
git push -u origin 009-hardening-release
git log -1 --oneline
```

تأكد أن الفرع المطبوع هو `009-hardening-release` قبل commit/push. لا تستخدم force-push. إذا رُفض push بسبب تحديث بعيد، توقف وراجع الفرق بدل reset أو الكتابة فوق عمل آخر.

إذا كانت Railway تتبع هذا الفرع، فالـ push يشغّل نشره تلقائيًا عند تفعيل Autodeploy. إذا كانت تتبع `main`، فلن يكفي رفع فرع 009: إما اختيار فرع 009 صراحة في خدمة Railway، أو إنشاء PR إلى main ومراجعته ودمجه. مثال اختياري لإنشاء PR باستخدام GitHub CLI المثبتة:

```powershell
gh auth status
gh pr create --base main --head 009-hardening-release --title "Add monthly loss carryforward" --body "Monthly loss settlements, explicit chronological reapproval, sync safeguards and regression tests."
```

لا تنفذ أمر إنشاء PR إذا كان هناك PR للفرع نفسه بالفعل. ملفات CI القديمة تحتاج المواءمة المذكورة في القسم 9 قبل الاعتماد على checks لها؛ لم أدّع نجاح GitHub CI.

## 5. ترحيل Neon عبر نشر Railway

لا تحتاج إنشاء migration جديدة. الترحيل الموجود والمسجل هو:

```text
motaz_app/motaz_app_server/migrations/20261018235919937-loss-carryforward/
```

السلوك المتوقع بعد نشر الـ commit الصحيح هو: Railway تبني صورة Docker الجديدة، ثم entrypoint يشغّل خادم Serverpod مع `--apply-migrations`. يطبق Serverpod الترحيل المعلّق على قاعدة Neon المحددة في Variables ثم يبدأ الخدمة. هذا يعتمد على إعداد الخدمة الفعلي؛ لم أتحقق من لوحة حسابك في هذه الجولة.

إذا لم يبدأ النشر تلقائيًا، استخدم لوحة أوامر Railway واختر **Deploy Latest Commit** للخدمة المرتبطة بالفرع الصحيح. راجع SHA في تفاصيل النشر مقابل `git log -1`. مجرد Restart أو Redeploy لنشر قديم ليس وسيلة لرفع الكود المحلي الجديد.

راقب Build Logs وDeploy Logs حتى تصبح الخدمة Active/Online دون أخطاء ترحيل. لا تتجاوز فشل migration أو تغيّر سجل الإصدارات يدويًا. لا تستخدم `reset_neon_data.sql` ولا DROP/TRUNCATE هنا.

للتأكد، افتح Neon > SQL Editor وحدد المشروع وفرع الإنتاج المرتبطين بـ Railway، ثم شغّل هذين الاستعلامين للقراءة فقط:

```sql
SELECT current_database() AS database_name, module, version, timestamp
FROM public.serverpod_migrations
WHERE module = 'motaz_app';

SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'monthly_distribution'
  AND column_name IN (
    'netSales', 'operationalExpenses', 'productionExpenses',
    'profitBeforeCarry', 'currentMonthLoss', 'carriedLossIn', 'carriedLossOut'
  )
ORDER BY column_name;
```

المتوقع: الإصدار `20261018235919937-loss-carryforward`، وسبعة أعمدة bigint غير قابلة لـ NULL بقيمة افتراضية صفر. مجرد ظهور Online لا يغني عن فحص الإصدار والقاعدة المستهدفة.

Railway CLI وpsql ليستا ظاهرتين في PATH حاليًا، ولا تحتاج تثبيتهما لهذا المسار. الرفع من GitHub يضمن تضمين ملفات الخادم المتتبعة، حتى مثل `config/production.yaml` التي تطابق أيضًا نمط تجاهل محليًا. لا تستخدم `railway up --no-gitignore` كحل لأنه قد يرفع أسرارًا محلية؛ مسار GitHub أعلاه هو المعتمد في هذا الدليل.

## 6. بناء Windows وAndroid

الأوامر التالية تولّد نسخًا تعمل من الأيقونة دون `flutter run`. ملف `assets/config.json` في المشروع مضبوط حاليًا على `https://motazapp-production.up.railway.app` للمنصتين، لذلك لا حاجة إلى dart-define إضافي غير مستخدم في التطبيق.

```powershell
Set-Location D:\dev\Motaz_App\motaz_app\motaz_app_flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build windows --release
flutter build apk --release
```

لا حاجة إلى `flutter clean` عادة؛ لا تستخدمه بشكل روتيني. لا يلزم توليد Serverpod مجددًا ما دامت نماذجه المولدة الحالية والترحيل مشمولة في commit ولم تتغير ملفات spy.yaml.

النسخة المحددة في pubspec حاليًا `1.0.0+1`. لتغيير رقم إصدار النشر، ارفع الرقم إلى قيمة أعلى من أي نسخة وزعتها. مثال اختياري فقط، وليس خطوة أخرى مطلوبة بعد البناء السابق:

```powershell
flutter build windows --release --build-name=1.0.1 --build-number=2
flutter build apk --release --build-name=1.0.1 --build-number=2
```

لا تستخدم المثال إذا سبق لك توزيع رقم بناء 2 أو أعلى. لا أستطيع معرفة أعلى رقم مثبت على هاتفك من pubspec وحده.

## 7. استخراج النسخ وتثبيتها

### Windows

```powershell
Set-Location D:\dev\Motaz_App\motaz_app\motaz_app_flutter
explorer .\build\windows\x64\runner\Release
Compress-Archive -Path .\build\windows\x64\runner\Release\* -DestinationPath .\build\Motaz_App-Windows.zip -Force
```

المشغّل هو `build\windows\x64\runner\Release\motaz_app_flutter.exe` في بناء x64. إذا طبع Flutter مسار معمارية مختلفًا فاتبع المسار المطبوع. انقل مجلد Release كاملًا، بما فيه DLL وdata؛ لا تنقل exe وحده. فك ZIP في مجلد ثابت ثم أنشئ اختصارًا للمشغّل على سطح المكتب. هذه نسخة portable وليست Setup installer؛ لم أجهز MSIX/Inno Setup.

راجع وجود `config.json` بجوار exe أو في مجلد تشغيله، ومتغيرات `MOTAZ_API_URL` و`MOTAZ_API_URL_ANDROID` و`MOTAZ_RUN_MODE`: قد تتجاوز إعداد Railway المضمن وتعيدك إلى localhost. لا تحذف ملفًا محليًا قبل مراجعة غرضه.

### Android

```powershell
Set-Location D:\dev\Motaz_App\motaz_app\motaz_app_flutter
explorer .\build\app\outputs\flutter-apk
```

الملف هو `build\app\outputs\flutter-apk\app-release.apk`. انقله للهاتف وافتحه للتثبيت، واسمح بالتثبيت من المصدر الذي استخدمته عند طلب النظام. ثبّت فوق التطبيق القديم مع الاحتفاظ بالبيانات؛ لا تحذف التطبيق لمعالجة تعارض توقيع دون نسخة احتياطية وخطة استعادة.

**تنبيه توقيع مهم:** `android/app/build.gradle.kts` يربط release حاليًا بمفتاح debug. الأوامر تنتج APK بوضع release لكنها لا تحوله إلى إصدار موقّع بمفتاح إنتاج خاص. يمكن استعماله شخصيًا وفق الإعداد الحالي، لكن تجهيز مفتاح إصدار دائم وربطه وحفظ نسخة آمنة منه مهمة متبقية قبل التوزيع الرسمي أو المتجر. تغيير المفتاح أو applicationId قد يمنع تحديث النسخة المثبتة؛ لا تغيّرهما عشوائيًا.

## 8. التحقق بعد التحديث

1. تحقق من إصدار الترحيل في Neon ومن SHA الخادم المنشور، ثم ثبت النسختين الجديدتين قبل المزامنة.
2. شغّل التطبيق من exe ومن أيقونة الهاتف، وتأكد أن بياناتك المحلية باقية وأن المزامنة تصل إلى نفس الخادم.
3. اختبر دورة حفظ محلي ثم إغلاق/فتح ثم إعادة اتصال، واختبر إعادة اعتماد شهر قديم على بيئة اختبار. لا تدخل بيانات اختبار مالية في إنتاج بدأت تدخل فيه بيانات حقيقية.
4. بعد نجاح ذلك لا تحتاج Docker أو خادم Serverpod يدويًا للاستعمال اليومي؛ تحتاجهما فقط للتطوير/اختبارات محلية. المزامنة تحتاج خادم Railway متاحًا؛ العمل المحلي يبقى offline-first.

## 9. المتبقي غير المنفذ

- إعادة analyze بعد هذا الإصلاح، وتنفيذ أوامر الرفع والنشر والتحقق من Neon الفعلية.
- إنشاء APK/Windows release بالخطوات أعلاه، وتثبيت النسختين وتجربة الأجهزة فعليًا.
- توقيع Android بإعداد إنتاج دائم قبل التوزيع الرسمي، ومثبت Windows إن أردت Setup بدل portable.
- مواءمة GitHub CI: الملفات الحالية تستخدم Flutter 3.32.8، بينما التحقق المحلي كان على 3.47.3؛ workflow الاختبارات يشغّل compose القديمة دون profile test ولا يولد Drift، وأمر تحليل حزمتي Dart يحتاج فصلًا. ينبغي تحديث البيئة والخطوات ثم إثبات نجاحها على GitHub، لا اعتبار الاختبارات المحلية دليلًا على نجاح CI. إذا كان Railway ينتظر CI ففشلها قد يمنع النشر.
- اختبار ضغط التزامن متعدد الاتصالات، وتجربة offline/reconnect بين الجهازين؛ لم يُدَّع إنجازهما.

## مراجع

- [Railway GitHub Autodeploys](https://docs.railway.com/deployments/github-autodeploys)
- [Railway CLI Deploying](https://docs.railway.com/cli/deploying)
- [Neon Branching](https://neon.com/docs/introduction/branching)
- [Flutter Android Release](https://docs.flutter.dev/deployment/android)
- [Flutter Windows Distribution](https://docs.flutter.dev/platform-integration/windows/building)
