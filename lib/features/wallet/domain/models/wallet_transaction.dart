enum WalletTransactionType { credit, debit, pending }

/// One sample transaction row; amounts stay display-only in this UI preview.
class WalletTransaction {
  const WalletTransaction({
    required this.amount,
    this.type = WalletTransactionType.credit,
    this.title = 'Home Cleaning',
    this.date = '1403/07/12  6:30PM',
  });
  final String amount, title, date;
  final WalletTransactionType type;
}
