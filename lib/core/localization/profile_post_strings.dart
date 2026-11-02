import 'package:nini/core/localization/app_strings.dart';

/// Persian copy for profile tabs and post editing. Model IDs and serialized
/// enum names stay independent of the labels displayed in the UI.
abstract final class ProfilePostStrings {
  static const tabs = 'دسته‌بندی‌ها';
  static const back = AppStrings.back;
  static const undo = AppStrings.undo;
  static const redo = AppStrings.redo;
  static const unitNames = {
    'piece': AppStrings.unitPiece,
    'item': AppStrings.unitItem,
    'hour': AppStrings.unitHour,
    'day': AppStrings.unitDay,
    'session': AppStrings.unitSession,
    'project': AppStrings.unitProject,
    'meter': AppStrings.unitMeter,
    'centimeter': AppStrings.unitCentimeter,
    'kilogram': AppStrings.unitKilogram,
    'set': AppStrings.unitSet,
  };
  static String preparationDays(int days) =>
      '${AppStrings.persianDigits(days)} روز';
  static const all = AppStrings.all;
  static const addTab = 'افزودن دسته‌بندی';
  static const editTab = 'ویرایش دسته‌بندی';
  static const deleteTab = 'حذف دسته‌بندی';
  static const tabName = 'نام دسته‌بندی';
  static const cancel = AppStrings.cancel;
  static const done = AppStrings.done;
  static const delete = AppStrings.delete;
  static const retry = AppStrings.retry;
  static const category = 'دسته‌بندی پروفایل';
  static const allOnly = 'فقط در «همه» (بدون دسته‌بندی)';
  static const manageTabs = 'مدیریت دسته‌بندی‌ها';
  static const noTabs =
      'هنوز دسته‌بندی‌ای ندارید. برای مرتب کردن پست‌ها، یک دسته‌بندی اضافه کنید.';
  static const noPosts = 'هنوز پستی در این دسته‌بندی وجود ندارد.';
  static const loadFailed =
      'بارگذاری دسته‌بندی‌ها انجام نشد. دوباره تلاش کنید.';
  static const saveFailed = 'ذخیره تغییرات انجام نشد. دوباره تلاش کنید.';
  static const nameRequired = 'نام دسته‌بندی را وارد کنید.';
  static const nameTooLong = 'نام دسته‌بندی باید حداکثر ۵۰ نویسه داشته باشد.';
  static const duplicateName = 'دسته‌بندی‌ای با این نام وجود دارد.';
  static const reservedName = '«همه» یک بخش دائمی است. نام دیگری انتخاب کنید.';
  static const editPost = 'ویرایش پست';
  static const deletePost = 'حذف پست';
  static const deletePostQuestion = 'این پست حذف شود؟';
  static const deletePostHelp =
      'این پست و رسانه‌های آن از پست‌های شما حذف می‌شوند. این کار قابل بازگشت نیست.';
  static const deleting = 'در حال حذف…';
  static const deleteFailed = 'حذف پست انجام نشد. دوباره تلاش کنید.';
  static const addMedia = 'افزودن رسانه';
  static const removeMedia = 'حذف رسانه';
  static const mediaRequired = 'حداقل یک عکس، ویدیو یا فایل انتخاب کنید.';
  static const mediaUnavailable =
      'یکی از رسانه‌ها در دسترس نیست. دوباره آن را انتخاب کنید.';
  static const saveChanges = 'ذخیره تغییرات';
  static const saving = 'در حال ذخیره…';
  static const postMissing = 'این پست دیگر در دسترس نیست.';
  static const media = 'رسانه‌ها';
  static const replaceMedia = 'جایگزینی رسانه‌ها';
  static const next = AppStrings.next;
  static const title = 'عنوان';
  static const caption = AppStrings.postCaption;
  static const captionHint = AppStrings.writeCaption;
  static const type = AppStrings.postType;
  static const product = AppStrings.product;
  static const service = AppStrings.services;
  static const price = 'قیمت (تومان)';
  static const discount = 'تخفیف (٪)';
  static const stock = 'موجودی';
  static const unit = AppStrings.unit;
  static const preparation = AppStrings.preparationTime;
  static const noPreparation = 'بدون زمان آماده‌سازی';
  static const sameDay = 'همان روز';
  static const inventory = 'وضعیت موجودی';
  static const inStock = AppStrings.stockAvailable;
  static const outOfStock = AppStrings.stockUnavailable;
  static const preOrder = AppStrings.preOrder;
  static const tags = 'برچسب‌ها (با ویرگول جدا کنید)';
  static const address = AppStrings.address;
  static const latitude = 'عرض جغرافیایی';
  static const longitude = 'طول جغرافیایی';
  static const features = AppStrings.featuresHeading;
  static const featureName = 'نام ویژگی';
  static const featureValue = AppStrings.featureValue;
  static const addFeature = AppStrings.addFeature;
  static const removeFeature = 'حذف ویژگی';
  static const schedule = 'زمان‌بندی';
  static const start = 'شروع';
  static const end = 'پایان';
  static const clearSchedule = AppStrings.removeSchedule;
  static const altText = AppStrings.altText;
  static const required = 'این قسمت را تکمیل کنید.';
  static const invalidNumber =
      'یک عدد معتبر برابر یا بزرگ‌تر از صفر وارد کنید.';
  static const invalidDiscount = 'عددی بین ۰ تا ۱۰۰ وارد کنید.';
  static const invalidStock = 'یک عدد صحیح برابر یا بزرگ‌تر از صفر وارد کنید.';
  static const invalidLocation =
      'نشانی و طول و عرض جغرافیایی معتبر را وارد کنید.';
  static const invalidFeatures = 'برای هر ویژگی، نام و مقدار را وارد کنید.';
  static const invalidSchedule =
      'زمان شروعی در آینده و زمان پایانی پس از شروع انتخاب کنید.';
  static const unsavedTitle = 'تغییرات کنار گذاشته شوند؟';
  static const unsavedHelp = 'تغییرات ذخیره‌نشده شما از بین می‌روند.';
  static const keepEditing = 'ادامه ویرایش';
  static const discard = 'کنار گذاشتن';
  static String deleteQuestion(String name) =>
      'از حذف دسته‌بندی «$name» مطمئن هستید؟';
  static const deleteHelp =
      'پست‌های این دسته‌بندی حفظ می‌شوند و در بخش «همه» قابل مشاهده خواهند بود.';

  /// Translate only the original bundled names. Custom user names stay intact,
  /// including renamed default tabs and names written in other languages.
  static String categoryName(String id, String name) => switch ((id, name)) {
    ('web-development', 'Web Development') => AppStrings.webDevelopment,
    ('electrical-wiring', 'Electrical Wiring') => AppStrings.electricalWiring,
    ('products', 'Products') => AppStrings.products,
    ('photography', 'Photography') => AppStrings.photography,
    _ => name,
  };
}
