import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/home_strings.dart';

/// Persian copy for the Profile tab / seller profile UI only.
abstract final class ProfileScreenStrings {
  static const profile = 'پروفایل';
  static const profileImage = 'تصویر پروفایل';
  static const moreOptions = 'گزینه‌های بیشتر';
  static const posts = 'پست‌ها';
  static const sales = 'فروش';
  static const customers = 'مشتریان';
  static const followers = 'دنبال‌کنندگان';
  static const following = 'دنبال‌شونده';
  static const follow = 'دنبال کردن';
  static const unfollow = 'دنبال‌شده';
  static const message = 'پیام';
  static const all = 'همه';
  static const manageTabs = 'مدیریت دسته‌ها';
  static const noPublishedPosts = 'هنوز پستی منتشر نشده است';
  static const noPosts = 'در این دسته هنوز پستی نیست.';
  static const noSellerPosts = 'هنوز پستی نیست';
  static const postsLoading = 'در حال بارگذاری پست‌ها…';
  static const postsLoadFailed = 'بارگذاری پست‌ها ممکن نشد.';
  static const savedPostsLoadFailed = 'بارگذاری پست‌های ذخیره‌شده ممکن نشد.';
  static const retry = 'تلاش مجدد';
  static const stockAvailable = 'موجود';
  static const stockUnavailable = 'ناموجود';
  static const postUnrated = 'هنوز امتیاز داده نشده';
  static String postRating(String value) =>
      'امتیاز ${AppStrings.persianDigits(value)} از ۵';
  static String inStock(int count) =>
      '${AppStrings.persianDigits(count)} عدد موجود';
  static String postCategory(String category) =>
      HomeStrings.postCategory(category);
  static const followUnavailable = 'دنبال کردن هنوز در دسترس نیست.';
  static const cannotFollowSelf = 'نمی‌توانید پروفایل خود را دنبال کنید.';
  static const followStatusUnconfirmed =
      'وضعیت دنبال کردن تأیید نشد. پروفایل را تازه کنید.';
  static const followStatusCheckProfile =
      'وضعیت دنبال کردن تأیید نشد. قبل از تلاش دوباره این پروفایل را بررسی کنید.';
  static const cannotFollowUser = 'حساب شما نمی‌تواند این کاربر را دنبال کند.';
  static const signInToFollow = 'برای دنبال کردن این کاربر وارد شوید.';
  static const followUpdateFailed =
      'به‌روزرسانی وضعیت دنبال کردن ممکن نشد. دوباره تلاش کنید.';
  static const signInRequired = 'برای ادامه وارد شوید.';
  static const cannotBlockSelf = 'نمی‌توانید حساب خود را مسدود کنید.';
  static const cannotUpdateBlock = 'حساب شما نمی‌تواند این مسدودیت را به‌روز کند.';
  static const userUnavailable = 'این کاربر در دسترس نیست.';
  static const blockUpdateFailed =
      'به‌روزرسانی وضعیت مسدودیت ممکن نشد. دوباره تلاش کنید.';
  static const blockPerson = 'مسدود کردن کاربر';
  static const unblockPerson = 'رفع مسدودیت کاربر';
  static const blockQuestion = 'این کاربر مسدود شود؟';
  static const blockHelp =
      'پست‌ها و پیام‌های این کاربر دیگر به شما نشان داده نمی‌شود.';
  static const personBlocked = 'کاربر مسدود شد';
  static const back = 'بازگشت';
  static const done = 'انجام شد';
  static const cancel = 'لغو';
  static const toman = AppStrings.tomanPersian;
}
