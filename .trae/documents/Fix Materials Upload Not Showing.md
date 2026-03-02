## سبب المشكلة
- شاشة رفع الملزمات تحفظ `teacher_id` بقيمة `users.id` (`teacherProfile.userId`) بدل `teachers.id` (`teacherProfile.id`).
- شاشة عرض الملزمات تجلب البيانات بتصفية `study_materials.teacher_id = teachers.id` (بعد استخراج `teachers.id` من `user_id`).
- النتيجة: الرفع يتم بنجاح لكن السجل لا يطابق فلتر العرض، فلا يظهر.

## التعديلات المطلوبة في الكود
1) تعديل رفع الملزمة
- في [teacher_materials_screen.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_techer_and_parent/lib/features/teacher/materials/teacher_materials_screen.dart#L495-L525)
- استبدال:
  - `final teacherId = authProvider.teacherProfile?.userId;`
  - إلى: `final teacherId = authProvider.teacherProfile?.id;`
- يظل `center_id` كما هو، ثم `addStudyMaterial(fullData)` ثم `_loadData()`.

2) (اختياري لكن موصى به) حماية ضد تكرار الخطأ
- في `addStudyMaterial` داخل [materials_repository_mixin.dart](file:///c:/Users/KimoStore/StudioProjects/ed_sentre_techer_and_parent/lib/shared/data/mixins/materials_repository_mixin.dart)
- إذا وصل `teacher_id` فارغ/غير صحيح، يتم اشتقاق `teachers.id` من `currentUserId` وتعبئته قبل الإدراج.

## إصلاح البيانات القديمة (مهم ليظهر ما تم رفعه سابقًا)
- تشغيل SQL مرة واحدة على Supabase لتصحيح السجلات التي تم إدراجها بـ `teacher_id = users.id`:
```sql
update study_materials sm
set teacher_id = t.id
from teachers t
where sm.teacher_id = t.user_id;
```
- بعد تنفيذها: الملزمات القديمة ستظهر مباشرة مع نفس فلتر الشاشة.

## التحقق بعد الإصلاح
- رفع ملف جديد: يجب أن يظهر فورًا بعد رسالة النجاح.
- فتح صفحة الملزمات مع تغيير الفلاتر (إن وجدت) للتأكد أن `file_type` لا يسبب إخفاء.
- التحقق من كون `study_materials.teacher_id` صار يساوي `teachers.id` في السجلات الجديدة.

إذا وافقت، سأطبق تعديل الكود + (إن رغبت) أضيف الحماية الاختيارية وأجهز لك استعلام SQL لإصلاح القديم.