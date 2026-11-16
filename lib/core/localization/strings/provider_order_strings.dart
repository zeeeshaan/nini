abstract final class ProviderOrderStrings {
  static const accept = "پذیرش";
  static const accepted = "سفارش پذیرفته شد.";
  static const messageBuyer = "پیام به خریدار";
  static const messageProvider = "پیام به ارائه‌دهنده";
  static const unavailable = "این سفارش برای پروفایل شما در دسترس نیست.";
  static const cancellation = "لغو سفارش";
  static const cancellationHeading = "چرا این سفارش را لغو می‌کنید؟";
  static const cancellationHint = "دلیل لغو سفارش را توضیح دهید.";
  static const reasonRequired = "دلیل لغو را وارد کنید.";
  static const cancelOrder = "ثبت لغو سفارش";
  static const cancelled = "سفارش لغو شد و دلیل آن در این دستگاه ذخیره شد.";
  static const cancellationReason = "لغو توسط ارائه‌دهنده";
  static const localNotice =
      "در این دستگاه ذخیره شد. بازپرداخت خودکار یا اعلان از راه دور ارسال نمی‌شود.";
  static const startPreparing = "شروع آماده‌سازی";
  static const markShipped = "ثبت ارسال";
  static const schedule = "ثبت زمان‌بندی";
  static const startService = "شروع خدمت";
  static const updated = "وضعیت سفارش به‌روزرسانی شد.";
  static const awaitingProvider = "در انتظار پذیرش سفارش توسط ارائه‌دهنده.";
  static const awaitingFulfillment =
      "پس از ارسال محصولات یا شروع خدمت توسط ارائه‌دهنده، تأیید تکمیل سفارش فعال می‌شود.";
  static const awaitingDelivery =
      "پس از دریافت محصولات یا خدمت، تکمیل سفارش را تأیید کنید.";
  static const buyerDispute = "خریدار مشکلی درباره این سفارش گزارش کرده است.";
  static const acceptedNotice = "سفارش شما پذیرفته شد.";
  static const placedNotice = "سفارش شما ثبت شد. پرداخت موفق بود.";
  static const completedNotice = "سفارش شما تکمیل شده است.";
  static const buyerCompletedNotice = "خریدار تکمیل سفارش را تأیید کرد.";
  static const manageSale = "مدیریت فروش";
  static const buyerInvoice = "مشاهده صورتحساب خریدار";
  static const canceledNotice = "ارائه‌دهنده سفارش شما را لغو کرد.";
  static String statusNotice(String status) => 'وضعیت سفارش: $status';
}
