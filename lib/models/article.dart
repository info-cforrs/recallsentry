class Article {
  final int id;
  final String title;
  final String slug;
  final String imageUrl;
  final String articleUrl;
  final String tags;
  final List<String> tagsList;
  final DateTime postedDate;
  final DateTime createdAt;

  Article({
    required this.id,
    required this.title,
    required this.slug,
    required this.imageUrl,
    required this.articleUrl,
    required this.tags,
    required this.tagsList,
    required this.postedDate,
    required this.createdAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      articleUrl: json['article_url'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      tagsList: (json['tags_list'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      postedDate: DateTime.parse(json['posted_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'image_url': imageUrl,
      'article_url': articleUrl,
      'tags': tags,
      'tags_list': tagsList,
      'posted_date': postedDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool hasTag(String tag) {
    return tagsList.any((t) => t.toUpperCase() == tag.toUpperCase());
  }
}
