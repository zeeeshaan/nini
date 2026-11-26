import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/home_strings.dart';

/// Persian interface copy for profile tabs and post editing.
abstract final class ProfilePostStrings {
  static const tabs = 'دسته‌ها';
  static const back = 'بازگشت';
  static const undo = 'واگرد';
  static const redo = 'از نو';
  static const unitNames = {
    'piece': 'عدد',
    'item': 'قلم',
    'hour': 'ساعت',
    'day': 'روز',
    'session': 'جلسه',
    'project': 'پروژه',
    'meter': 'متر',
    'centimeter': 'سانتی‌متر',
    'kilogram': 'کیلوگرم',
    'set': 'ست',
  };
  static String preparationDays(int days) =>
      '${AppStrings.persianDigits(days)} روز';
  static const all = 'همه';
  static const addTab = 'افزودن دسته';
  static const editTab = 'ویرایش دسته';
  static const deleteTab = 'حذف دسته';
  static const tabName = 'نام دسته';
  static const cancel = 'لغو';
  static const done = 'انجام شد';
  static const delete = 'حذف';
  static const retry = 'تلاش مجدد';
  static const category = 'دسته پروفایل';
  static const allOnly = 'فقط همه (بدون دسته)';
  static const manageTabs = 'مدیریت دسته‌ها';
  static const noTabs = 'هنوز دسته‌ای نیست. برای سازمان‌دهی پست‌ها یکی اضافه کنید.';
  static const noPosts = 'در این دسته هنوز پستی نیست.';
  static const noPublishedPosts = 'هنوز پستی منتشر نشده است';
  static const publicProfile = 'پروفایل در دسترس نیست';
  static const publicIdentityMissing =
      'این پست نام کاربری در دسترس در بک‌اند ندارد.';
  static const publicUnavailable = 'این پروفایل در دسترس نیست.';
  static const publicLoadFailed =
      'بارگذاری این پروفایل ممکن نشد. دوباره تلاش کنید.';
  static const publicConnectionFailed =
      'اتصال برقرار نشد. اتصال خود را بررسی کنید و دوباره تلاش کنید.';
  static const publicTimeout =
      'درخواست پروفایل زمان‌بر شد. دوباره تلاش کنید.';
  static const publicSessionFailed =
      'جلسه شما تأیید نشد. لطفاً دوباره وارد شوید.';
  static const publicSessionChanged =
      'حساب شما تغییر کرد. برای ادامه این پروفایل را دوباره بارگذاری کنید.';
  static const publicPostsUnavailable =
      'پست‌ها و خدمات این کاربر هنوز اینجا در دسترس نیست.';
  static const followUnavailable =
      'دنبال کردن و لغو دنبال هنوز در دسترس نیست.';
  static const loadFailed = 'بارگذاری دسته‌ها ممکن نشد. دوباره تلاش کنید.';
  static const saveFailed = 'ذخیره تغییرات ممکن نشد. دوباره تلاش کنید.';
  static const changesSaved = 'پست با موفقیت ویرایش شد.';
  static const changesSubmittedForReview = 'پست با موفقیت ویرایش شد.';
  static const nameRequired = 'نام دسته را وارد کنید.';
  static const nameTooLong = 'نام دسته حداکثر ۴۰ نویسه باشد.';
  static const nameTooShort = 'نام دسته حداقل ۲ نویسه باشد.';
  static const categoryLimit = 'حداکثر ۲۰ دسته پروفایل می‌توانید داشته باشید.';
  static const categoryConflict =
      'این نام قبلاً استفاده شده یا به سقف ۲۰ دسته رسیده‌اید. دسته‌ها را دوباره بارگذاری کنید و تلاش کنید.';
  static const categoryInvalid =
      'درخواست دسته نامعتبر است. نام یا ترتیب دسته‌ها را بررسی کنید.';
  static const categoryResponseInvalid =
      'پاسخ دسته تأیید نشد. قبل از تلاش دوباره دسته‌ها را بارگذاری کنید.';
  static const categoryTimeout =
      'درخواست دسته زمان‌بر شد. دوباره تلاش کنید.';
  static const categoryConnectionFailed =
      'اتصال به سرویس دسته‌ها ممکن نشد. دوباره تلاش کنید.';
  static const categorySessionExpired =
      'جلسه شما منقضی شده است. لطفاً دوباره وارد شوید.';
  static const categoryAccountChanged =
      'حساب شما تغییر کرد. برای ادامه دسته‌ها را دوباره بارگذاری کنید.';
  static const categoryUnavailable =
      'این دسته پروفایل دیگر در دسترس نیست. دسته‌ها را دوباره بارگذاری کنید و تلاش کنید.';
  static const categoryOrderInvalid =
      'ترتیب دسته‌ها باید هر دسته فعلی را دقیقاً یک‌بار شامل شود.';
  static const categoryLegacyUnavailable =
      'شناسه‌های قدیمی محلی برای عملیات دسته بک‌اند قابل استفاده نیستند.';
  static const publicCategoriesLoading = 'در حال بارگذاری دسته‌های پروفایل…';
  static const publicCategoriesFailed =
      'بارگذاری دسته‌های پروفایل این کاربر ممکن نشد. پروفایل را دوباره باز کنید.';
  static const duplicateName = 'دسته‌ای با این نام از قبل وجود دارد.';
  static const reservedName =
      '«همه» بخش دائمی است. نام دیگری انتخاب کنید.';
  static const editPost = 'ویرایش پست';
  static const deletePost = 'حذف پست';
  static const deletePostQuestion = 'این پست حذف شود؟';
  static const deletePostHelp =
      'این پست و رسانه‌های آن برای همیشه از پست‌های شما حذف می‌شود.';
  static const deleting = 'در حال حذف…';
  static const deleteFailed = 'حذف پست ممکن نشد. دوباره تلاش کنید.';
  static const addMedia = 'افزودن رسانه';
  static const removeMedia = 'حذف رسانه';
  static const mediaRequired =
      'حداقل یک عکس، ویدیو یا فایل انتخاب کنید.';
  static const mediaUnavailable =
      'برخی رسانه‌ها در دسترس نیست. دوباره انتخاب کنید.';
  static const saveChanges = 'ذخیره تغییرات';
  static const saving = 'در حال ذخیره…';
  static const postMissing = 'این پست دیگر در دسترس نیست.';
  static const media = 'رسانه';
  static const replaceMedia = 'جایگزینی رسانه';
  static const next = 'بعدی';
  static const title = 'عنوان';
  static const caption = 'توضیحات';
  static const captionHint = 'توضیحات را بنویسید';
  static const type = 'نوع پست';
  static const product = 'محصول';
  static const service = 'خدمات';
  static const price = 'قیمت (تومان)';
  static const discount = 'تخفیف (%)';
  static const stock = 'موجودی';
  static const unit = 'واحد';
  static const preparation = 'زمان آماده‌سازی';
  static const noPreparation = 'بدون زمان آماده‌سازی';
  static const sameDay = 'همان روز';
  static const inventory = 'وضعیت موجودی';
  static const inStock = 'موجود';
  static const outOfStock = 'ناموجود';
  static const preOrder = 'پیش‌سفارش';
  static const tags = 'برچسب‌ها (با ویرگول جدا کنید)';
  static const address = 'آدرس';
  static const latitude = 'عرض جغرافیایی';
  static const longitude = 'طول جغرافیایی';
  static const features = 'ویژگی‌ها';
  static const featureName = 'نام مشخصه';
  static const featureValue = 'مقدار مشخصه';
  static const addFeature = 'افزودن ویژگی';
  static const removeFeature = 'حذف مشخصه';
  static const schedule = 'زمان‌بندی';
  static const start = 'شروع';
  static const end = 'پایان';
  static const clearSchedule = 'حذف زمان‌بندی';
  static const altText = 'متن جایگزین';
  static const required = 'این فیلد را تکمیل کنید.';
  static const invalidNumber =
      'عدد معتبر بزرگ‌تر یا مساوی صفر وارد کنید.';
  static const invalidDiscount = 'عددی بین ۰ تا ۱۰۰ وارد کنید.';
  static const invalidStock =
      'عدد صحیح بزرگ‌تر یا مساوی صفر وارد کنید.';
  static const invalidLocation =
      'آدرس و عرض و طول جغرافیایی معتبر وارد کنید.';
  static const invalidFeatures =
      'برای هر مشخصه نام و مقدار وارد کنید.';
  static const invalidSchedule =
      'زمان شروع آینده و زمان پایان بعد از شروع را انتخاب کنید.';
  static const unsavedTitle = 'تغییرات نادیده گرفته شود؟';
  static const unsavedHelp = 'تغییرات ذخیره‌نشده از بین می‌رود.';
  static const keepEditing = 'ادامه ویرایش';
  static const discard = 'نادیده گرفتن';
  static String deleteQuestion(String name) => 'دسته «$name» حذف شود؟';
  static const deleteHelp =
      'پست‌های این دسته همچنان زیر بخش همه قابل مشاهده هستند.';

  static String categoryName(String id, String name) => switch ((id, name)) {
    ('web-development', 'Web Development') => 'توسعه وب',
    ('electrical-wiring', 'Electrical Wiring') => 'سیم‌کشی برق',
    ('products', 'Products') => 'محصولات',
    ('photography', 'Photography') => 'عکاسی',
    _ => HomeStrings.postCategory(name),
  };
}
