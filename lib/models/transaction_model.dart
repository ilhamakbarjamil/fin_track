class TransactionModel {
  final int? id;
  final int walletId;
  final int? categoryId;
  final int amount;
  final String description;
  final String date;
  final int type; // 1 = Masuk, 2 = Keluar

  TransactionModel({
    this.id,
    required this.walletId,
    this.categoryId,
    required this.amount,
    required this.description,
    required this.date,
    required this.type,
  });

  // Mengubah data dari Database (Map) ke Class Dart
  factory TransactionModel.fromMap(Map<String, dynamic> json) => TransactionModel(
        id: json['id'],
        walletId: json['wallet_id'],
        categoryId: json['category_id'],
        amount: json['amount'],
        description: json['description'],
        date: json['date'],
        type: json['type'],
      );

  // Mengubah Class Dart ke format Database (Map)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wallet_id': walletId,
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'date': date,
      'type': type,
    };
  }
}