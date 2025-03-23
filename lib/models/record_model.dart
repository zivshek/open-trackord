class RecordModel {
  final int? id; // Make id nullable
  final int categoryId;
  final double value;
  final DateTime date;

  RecordModel({
    this.id,
    required this.categoryId,
    required this.value,
    required this.date,
  });

  factory RecordModel.fromMap(Map<String, dynamic> map) {
    return RecordModel(
      id: map['id'],
      categoryId: map['category_id'],
      value: map['value'],
      date: DateTime.parse(map['date']),
    );
  }

  RecordModel copyWith({
    int? id,
    int? categoryId,
    double? value,
    DateTime? date,
  }) {
    return RecordModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      value: value ?? this.value,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'value': value,
      'date': date.toIso8601String().split('T')[0], // Store only the date part
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordModel &&
          runtimeType == other.runtimeType &&
          id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return "Record $id, $date";
  }
}
