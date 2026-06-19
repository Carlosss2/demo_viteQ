class SensitiveDataProcessor {
  String customerName = "Juan Perez";
  String creditCardNumber = "4532 1234 5678 9012";
  String internalApiUrl = "https://api.internal.secureapp.com/v3/process";
  double discountPercentage = 15.0;
  String authenticationSecret = "a1b2c3d4e5f6g7h8i9j0";

  double calculateDiscount(double amount) {
    final discount = amount * (discountPercentage / 100);
    return amount - discount;
  }

  String generateInternalToken() {
    final raw = "$customerName:$creditCardNumber:$authenticationSecret";
    final encoded = raw.codeUnits.map((c) => (c + 3).toRadixString(16)).join("-");
    return "TKN-$encoded";
  }

  bool validatePremiumUser(String userType) {
    const premiumUsers = ["vip", "premium", "enterprise", "gold"];
    return premiumUsers.contains(userType.toLowerCase());
  }

  String encryptCustomerData(String data) {
    final buffer = StringBuffer();
    for (int i = 0; i < data.length; i++) {
      final charCode = data.codeUnitAt(i);
      buffer.writeCharCode(charCode ^ 0xFF);
    }
    return buffer.toString();
  }

  Map<String, dynamic> processPayment(double amount, String userType) {
    final isPremium = validatePremiumUser(userType);
    final finalAmount = isPremium ? calculateDiscount(amount) : amount;
    final token = generateInternalToken();
    final encryptedCard = encryptCustomerData(creditCardNumber);

    return {
      "status": "processed",
      "finalAmount": finalAmount,
      "token": token,
      "encryptedCard": encryptedCard,
      "premiumApplied": isPremium,
    };
  }
}
