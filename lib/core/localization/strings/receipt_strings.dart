import 'package:nini/core/localization/app_string/app_string.dart';

abstract final class ReceiptStrings {
  static const demoPayment = "پرداخت آزمایشی";
  static const demoNotice = "این یک پیش‌نمایش است و مبلغی برداشت نشده است.";
  static const completeDemoPayment = "تکمیل پرداخت آزمایشی";
  static const paymentDone = "پرداخت انجام شد";
  static const paymentSuccessful = "پرداخت موفق";
  static const paymentNotSaved =
      "ذخیره پرداخت انجام نشد. سبد خرید شما حفظ شده است. دوباره تلاش کنید.";
  static const backToCart = "بازگشت به سبد خرید";
  static const backToMyTeam = "بازگشت به تیم‌های من";
  static const viewInvoice = "مشاهده صورتحساب";
  static const invoice = "صورتحساب";
  static const invoiceDate = "تاریخ صورتحساب";
  static const orderId = "شناسه سفارش";
  static const transactionId = "شناسه تراکنش";
  static const paymentMethod = "روش پرداخت";
  static const paymentDate = "تاریخ پرداخت";
  static const paymentTime = "زمان پرداخت";
  static const currency = "واحد پول";
  static const copied = "شماره صورتحساب کپی شد";
  static const problem = "گزارش مشکل";
  static const confirm = "تأیید";
  static const confirmCompletion = "تأیید تکمیل سفارش";
  static const confirmCompletionHelp =
      "دریافت محصولات یا تکمیل خدمات را تأیید کنید.";
  static const completed = "تکمیل سفارش در این دستگاه ثبت شد.";
  static const dispute = "اعتراض";
  static const viewDispute = "مشاهده اعتراض";
  static const problemHeading = "مشکلی دارم.";
  static const describeProblem = "مشکل خود را توضیح دهید.";
  static const descriptionRequired = "پیش از ارسال، مشکل را توضیح دهید.";
  static const disputeSaved = "اعتراض در این دستگاه ذخیره شد.";
  static const disputeLocalNotice =
      "اعتراض‌ها در این دستگاه ذخیره می‌شوند. ارسال به پشتیبانی هنوز فعال نیست.";
  static const saveFailed = "ذخیره تغییرات انجام نشد. دوباره تلاش کنید.";
  static const file = "فایل";
  static const image = "تصویر";
  static const attach = "پیوست فایل یا تصویر";
  static const removeAttachment = "حذف پیوست";
  static const attachFailed = "پیوست فایل انجام نشد. دوباره تلاش کنید.";
  static const unavailable = "این سفارش ذخیره‌شده در دسترس نیست.";
  static String moreItems(int count) =>
      '+ ${AppStrings.persianDigits(count)} مورد دیگر';
}
