/// Category data for push subscription.
class CategoryData {
  final String? name;
  final String? title;
  final bool? steady;
  final bool? active;

  const CategoryData({
    this.name,
    this.title,
    this.steady,
    this.active,
  });

  Map<String, dynamic> toMap() {
    return {
      if (name != null) 'name': name,
      if (title != null) 'title': title,
      if (steady != null) 'steady': steady,
      if (active != null) 'active': active,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      name: json['name'] as String?,
      title: json['title'] as String?,
      steady: json['steady'] as bool?,
      active: json['active'] as bool?,
    );
  }
}
