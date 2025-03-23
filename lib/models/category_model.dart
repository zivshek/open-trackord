class CategoryModel {
  final int? id;
  final int clusterId;
  final String name;
  final String unit;
  final String valueType;
  final int order;
  final String? notes;

  CategoryModel({
    this.id,
    required this.clusterId,
    required this.name,
    required this.unit,
    required this.valueType,
    required this.order,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'cluster_id': clusterId,
      'name': name,
      'unit': unit,
      'value_type': valueType,
      'order': order,
      'notes': notes,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      clusterId: map['cluster_id'] as int,
      name: map['name'] as String,
      unit: map['unit'] as String,
      valueType: map['value_type'] as String,
      order: map['order'] as int,
      notes: map['notes'] as String?,
    );
  }

  CategoryModel copyWith({
    int? id,
    int? clusterId,
    String? name,
    String? unit,
    String? valueType,
    int? order,
    String? notes,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      clusterId: clusterId ?? this.clusterId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      valueType: valueType ?? this.valueType,
      order: order ?? this.order,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id);

  @override
  int get hashCode => id.hashCode;
}
