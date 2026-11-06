/// Display data supplied by a checkout. Monetary values use hundredths of toman.
class PaymentDetails {
  const PaymentDetails({
    required this.total,
    required this.summary,
    this.scheduledAt,
    this.address,
    this.phone,
  });
  final int total;
  final List<(String, String)> summary;
  final DateTime? scheduledAt;
  final String? address, phone;
}
