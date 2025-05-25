class PaymentInfo {
  final String? method;
  final String? transactionId;
  final String? bankCode;
  final String? payDate;

  PaymentInfo({
    this.method,
    this.transactionId,
    this.bankCode,
    this.payDate,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      method: json['method'],
      transactionId: json['transactionId'],
      bankCode: json['bankCode'],
      payDate: json['payDate'],
    );
  }
}
