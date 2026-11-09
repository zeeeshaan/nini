import '../domain/wallet_transaction.dart';

/// Static preview values matching the reference; no financial operations.
abstract final class WalletSampleData {
  static const balance = '50,000,000';
  static const owner = 'Mojtaba.z';
  static const withdrawalAmount = '45,000,000';
  static const pendingAmount = '35,000,000';
  static const presets = ['800,000', '600,000', '400,000', '200,000'];
  static const today = [
    WalletTransaction(amount: '+230,000'),
    WalletTransaction(amount: '+230,000'),
    WalletTransaction(amount: '+230,000'),
    WalletTransaction(amount: '+230,000'),
  ];
  static const yesterday = [
    WalletTransaction(amount: '-190,000', type: WalletTransactionType.debit),
    WalletTransaction(amount: '+230,000'),
    WalletTransaction(amount: '230,000', type: WalletTransactionType.pending),
    WalletTransaction(amount: '+230,000'),
  ];
}
