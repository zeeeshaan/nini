abstract final class OrderInformationStrings {
  static const title = "اطلاعات سفارش";
  static const amountPayable = "مبلغ قابل پرداخت";
  static const personalInformation = "اطلاعات شخصی";
  static const name = "نام";
  static const surname = "نام خانوادگی";
  static const mobile = "شماره همراه";
  static const city = "شهر";
  static const province = "استان";
  static const address = "نشانی";
  static const postalCode = "کد پستی";
  static const chooseAddress = "انتخاب نشانی روی نقشه";
  static const invalidMobile = "شماره همراه معتبر وارد کنید.";
  static const invalidPostalCode = "کد پستی معتبر وارد کنید.";
  static const cartChanged =
      "سبد خرید تغییر کرده است. به اطلاعات سفارش بازگردید و مبلغ نهایی را بررسی کنید.";
  static const emptyCheckout = "هیچ موردی برای پرداخت انتخاب نشده است.";
  static String requiredField(String label) => '$label را وارد کنید.';
}
