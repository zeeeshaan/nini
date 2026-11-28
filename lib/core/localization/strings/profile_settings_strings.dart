import 'package:hywork/core/localization/app_string/app_string.dart';

/// Persian labels shared by Profile Settings and its detail screens.
abstract final class ProfileSettingsStrings {
  static const title = 'تنظیمات';
  static const logout = 'خروج';
  static const logoutTitle = 'خارج می‌شوید؟';
  static const logoutConfirmation = 'مطمئن هستید که می‌خواهید خارج شوید؟';
  static const loggingOut = 'در حال خروج…';
  static const logoutFailed = 'خروج ممکن نشد. دوباره تلاش کنید.';
  static const logoutTimeout =
      'خروج به‌خاطر پایان مهلت درخواست تأیید نشد. دوباره تلاش کنید.';
  static const logoutConnectionFailed =
      'اتصال برای خروج برقرار نشد. اینترنت خود را بررسی کنید و دوباره تلاش کنید.';
  static const logoutServerFailed =
      'سرور خروج را تأیید نکرد. دوباره تلاش کنید.';
  static const logoutCleanupFailed =
      'جلسه سرور پایان یافته، اما ورود ذخیره‌شده حذف نشد. برای تکمیل خروج دوباره تلاش کنید.';
  static const general = 'عمومی';
  static const myTeam = 'تیم من';
  static const profile = 'تنظیمات پروفایل';
  static const locations = 'موقعیت‌ها';
  static const wallet = 'کیف پول';
  static const saved = 'ذخیره‌شده‌ها';
  static const notifications = 'اعلان‌ها';
  static const trending = 'پرطرفدار';
  static const insights = 'آمار';
  static const scheduledContent = 'محتوای زمان‌بندی‌شده';
  static const blocked = 'مسدودشده‌ها';
  static const comments = 'نظرات';
  static const language = 'زبان';
  static const devicePermissions = 'مجوزهای دستگاه';
  static const accessibility = 'دسترسی‌پذیری';
  static const posts = 'پست‌ها';
  static const myMedia = 'رسانه‌های من';
  static const tags = 'برچسب‌ها و کلیدواژه‌ها';
  static const archive = 'بایگانی';
  static const searchHint = 'جستجو';
  static const noResults = 'نتیجه‌ای یافت نشد';
  static const tryAnotherSearch = 'جستجوی دیگری را امتحان کنید.';
  static const localActivity = 'فعالیت ثبت‌شده روی این دستگاه';
  static const noTrending = 'هنوز پست پرطرفداری نیست';
  static const trendingHelp =
      'پست‌های منتشرشده شما وقتی بازدید یا تعامل داشته باشند اینجا ظاهر می‌شوند. این رتبه‌بندی سراسری نیست.';
  static const noScheduled = 'محتوای زمان‌بندی‌شده‌ای نیست';
  static const scheduledHelp =
      'در ویرایشگر پست زمان‌بندی اضافه کنید تا اینجا نمایش داده شود.';
  static const scheduleNotice =
      'این‌ها زمان‌بندی‌های ذخیره‌شده پست هستند. انتشار خودکار متصل نیست.';
  static const viewPost = 'مشاهده پست';
  static const editPost = 'ویرایش پست';
  static const noBlocked = 'کاربر مسدودشده‌ای نیست';
  static const blockedHelp =
      'افرادی که مسدود می‌کنید اینجا ظاهر می‌شوند. هر زمان می‌توانید رفع مسدودیت کنید.';
  static const blockedConversation = 'کاربر مسدودشده';
  static const unblock = 'رفع مسدودیت';
  static const sessionBlocks =
      'حساب‌های مسدودشده در پروفایل های‌ورک شما ذخیره می‌شوند.';
  static const blockedLoadFailed =
      'بارگذاری کاربران مسدودشده ممکن نشد. دوباره تلاش کنید.';
  static const blockedSignInRequired =
      'برای مدیریت کاربران مسدودشده وارد شوید.';
  static const unblockFailed =
      'رفع مسدودیت این کاربر ممکن نشد. دوباره تلاش کنید.';
  static const unblockSuccess = 'رفع مسدودیت انجام شد.';
  static const noCommentHistory = 'تاریخچه نظری ذخیره نشده';
  static const commentsHelp =
      'برگه نظر فعلی پست پیش‌نمایش موقت است. منبع تاریخچه نظر هنوز متصل نیست.';
  static const english = 'انگلیسی';
  static const persian = 'فارسی';
  static const languageHelp = 'انگلیسی برای آزمایش برنامه فعال است.';
  static const notAvailable = 'هنوز در دسترس نیست';
  static const photoLibrary = 'عکس‌ها و ویدیوها';
  static const location = 'موقعیت';
  static const microphone = 'میکروفون';
  static const permissionHelp =
      'دسترسی را در تنظیمات دستگاه مدیریت کنید. برای تازه‌سازی وضعیت به اینجا برگردید.';
  static const openDeviceSettings = 'باز کردن تنظیمات دستگاه';
  static const permissionFailed =
      'خواندن مجوزهای دستگاه ممکن نشد. دوباره تلاش کنید.';
  static const settingsFailed = 'باز کردن تنظیمات دستگاه ممکن نشد.';
  static const granted = 'مجاز';
  static const denied = 'مجاز نیست';
  static const restricted = 'محدودشده توسط دستگاه';
  static const limited = 'دسترسی محدود';
  static const unknown = 'وضعیت در دسترس نیست';
  static const noMedia = 'هنوز رسانه‌ای آپلود نشده';
  static const mediaHelp =
      'عکس‌ها، ویدیوها و فایل‌های پیوست‌شده به پست‌های شما اینجا ظاهر می‌شوند.';
  static const mediaNotice =
      'پیوست‌ها را در ویرایشگر پست مدیریت کنید. فایل‌های رسانه از این صفحه حذف نمی‌شوند.';
  static const noTags = 'هنوز برچسب یا کلیدواژه‌ای نیست';
  static const tagsHelp = 'در ایجاد پست یا ویرایش پست موجود برچسب اضافه کنید.';
  static const tagsNotice =
      'روی یک کلیدواژه بزنید تا پست‌هایش را ببینید و برچسب‌ها را ویرایش کنید.';
  static const noArchive = 'بایگانی متصل نیست';
  static const archiveHelp =
      'در نسخه فعلی برنامه پست‌ها بایگانی نمی‌شوند. منبع داده و عملیات بایگانی/بازیابی لازم است تا موردی اینجا ظاهر شود.';
  static const postStatistics = 'آمار پست‌ها و خدمات';
  static const customerStatistics = 'آمار کاربران و مشتریان';
  static const alerts = 'هشدارها و یادآورها';
  static const totalPosts = 'کل پست‌ها';
  static const views = 'بازدیدها';
  static const interactions = 'تعاملات';
  static const bookings = 'رزروها';
  static const sales = 'فروش';
  static const trendingServices = 'خدمات پرطرفدار';
  static const newFollowers = 'دنبال‌کنندگان جدید';
  static const topCustomers = 'برترین مشتریان';
  static const feedback = 'بازخورد';
  static const usageReminder = 'یادآور محدودیت استفاده';
  static const unansweredMessages = 'پیام‌های بی‌پاسخ';
  static const backendRequired = 'نیاز به بک‌اند متصل';
  static const analyticsFailed = 'بارگذاری تاریخچه آمار محلی ممکن نشد.';
  static const analyticsHelp =
      'شمارش‌ها از پست‌های منتشرشده، رویدادهای محلی ثبت‌شده و سفارش‌های غیرنمایشی استفاده می‌کنند. آمار سراسری سرور نیستند.';
  static String tagPosts(int count) => '${AppStrings.persianDigits(count)} پست';
}
