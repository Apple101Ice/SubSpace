import 'package:hive/hive.dart';

part 'blog_post_adapter.g.dart';

@HiveType(typeId: 0)
class BlogPost {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String imageUrl;

  BlogPost(this.id, this.title, this.imageUrl);

  // Add your toJson and fromJson methods if you haven't already
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
    };
  }

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      json['id'] as String,
      json['title'] as String,
      json['image_url'] as String,
    );
  }
}
