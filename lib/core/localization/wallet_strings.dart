/// Persian copy for the wallet UI. Bank identifiers and sample amounts stay
/// separate from the labels displayed to the user.
abstract final class WalletStrings {
  static const wallet = 'کیف پول';
  static const withdraw = 'برداشت';
  static const balance = 'موجودی';
  static const topUp = 'افزایش موجودی';
  static const topUpTitle = topUp;
  static const chargeAmount = 'مبلغ افزایش موجودی';
  static const paymentMethod = 'روش پرداخت';
  static const transfer = 'انتقال';
  static const request = 'درخواست وجه';
  static const payment = 'پرداخت';
  static const transactions = 'تراکنش‌ها';
  static const today = 'امروز';
  static const yesterday = 'دیروز';
  static const withdrawalAmount = 'مبلغ برداشت';
  static const pendingAmount = 'مبلغ در انتظار برداشت';
  static const accountNumber = 'شماره حساب';
  static const accountHint = '1234-5678-9012-3456';
  static const password = 'رمز یک‌بارمصرف';
  static const otp = 'رمز پویا';
  static const securityHelp =
      'برای حفظ امنیت شما، لازم است این برداشت را تأیید کنیم.';
  static const done = 'تأیید';
  static const illustration = 'تصویر برداشت وجه';

  static String bankName(String bank) => switch (bank) {
    'melli' => 'بانک ملی ایران',
    'mellat' => 'بانک ملت',
    'saman' => 'بانک سامان',
    _ => bank,
  };
  static String transactionTitle(String title) =>
      title == 'Home Cleaning' ? 'نظافت منزل' : title;
  static String ownerLabel(String owner) =>
      owner == 'Mojtaba.z' ? 'مجتبی.ز' : owner;
}
