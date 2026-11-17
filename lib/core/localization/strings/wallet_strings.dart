/// English interface copy for the wallet UI. Bank identifiers and sample amounts stay
/// separate from the labels displayed to the user.
abstract final class WalletStrings {
  static const wallet = "Wallet";
  static const withdraw = "Withdraw";
  static const balance = "Balance";
  static const topUp = "Top Up";
  static const topUpTitle = topUp;
  static const chargeAmount = "Top-up amount";
  static const paymentMethod = "Payment method";
  static const transfer = "Transfer";
  static const request = "Request";
  static const payment = "Payment";
  static const transactions = "Transactions";
  static const today = "Today";
  static const yesterday = "Yesterday";
  static const withdrawalAmount = "Withdrawal amount";
  static const pendingAmount = "Amount pending withdrawal";
  static const accountNumber = "Account number";
  static const accountHint = '1234-5678-9012-3456';
  static const password = "One-time password";
  static const otp = "OTP";
  static const securityHelp =
      "For your security, we need to verify this withdrawal.";
  static const withdrawAmountHint = "Enter the amount you want to withdraw.";
  static const reviewCarefully = "Please review carefully";
  static const withdrawalReview =
      "After you request a withdrawal, the amount is reserved from your available balance. You may not be able to cancel once processing begins.";
  static const withdrawalComplete = "Withdrawal completed successfully.";
  static const previewOnly = "Demo preview only";
  static const enterValidAmount = "Enter a valid amount greater than zero.";
  static const done = "Done";
  static const illustration = "Withdrawal illustration";

  static String bankName(String bank) => switch (bank) {
    'melli' => 'Bank Melli',
    'mellat' => 'Bank Mellat',
    'saman' => 'Saman Bank',
    _ => bank,
  };
  static String transactionTitle(String title) =>
      title == 'Home Cleaning' ? 'Home Cleaning' : title;
  static String transactionDate(String value) => value;

  static String ownerLabel(String owner) =>
      owner == 'Mojtaba.z' ? 'Mojtaba.z' : owner;
}
