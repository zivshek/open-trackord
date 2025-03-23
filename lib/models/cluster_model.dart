class ClusterModel {
  final int? id;
  final String name;
  final int order;

  ClusterModel({required this.id, required this.name, required this.order});

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'order': order,
    };
  }

  factory ClusterModel.fromMap(Map<String, dynamic> map) {
    return ClusterModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      order: map['order'] as int,
    );
  }

  ClusterModel copyWith({
    int? id,
    String? name,
    int? order,
  }) {
    return ClusterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClusterModel &&
          runtimeType == other.runtimeType &&
          id == other.id);

  @override
  int get hashCode => id.hashCode;
}
