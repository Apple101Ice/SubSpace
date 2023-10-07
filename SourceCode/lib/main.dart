import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:subspace_app/blog_post_adapter.dart';
import 'package:subspace_app/boxes.dart';
import 'package:subspace_app/favorites_adapter.dart';
import 'package:subspace_app/http_services.dart';

const blogsBox = 'blog_box';
const favoritesBox = 'favorite_box';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(BlogPostAdapter());
  Hive.registerAdapter(FavoritesAdapter());

  await Hive.openBox<BlogPost>(blogsBox);
  await Hive.openBox<String>(favoritesBox);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  int selectedIndex = 0;
  int? prevIndex;

  BlogPost? selectedBlog;

  void togglePage(int index) {
    if (index == 1) {
      prevIndex = 0;
    } else {
      prevIndex = selectedIndex;
    }
    selectedIndex = index;
    notifyListeners();
  }

  void setBlogPreview(BlogPost blog) {
    selectedBlog = blog;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isDataLoading = false;
  bool get isDataLoading => _isDataLoading;

  Future<void> fetchData() async {
    setState(() {
      _isDataLoading = true;
    });
    try {
      final response = await HttpServices().fetchData();

      if (response != null) {
        final jsonDataList = json.decode(response as String)['blogs'];

        final List<BlogPost> blogPosts = jsonDataList.map<BlogPost>((json) {
          return BlogPost.fromJson(json);
        }).toList();

        await boxBlogs.clear();
        await boxBlogs.addAll(blogPosts);
      }
    } catch (e) {
      rethrow;
    } finally {
      setState(() {
        _isDataLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    boxBlogs = Hive.box<BlogPost>(blogsBox);
    boxFavorites = Hive.box<String>(favoritesBox);
    if (boxBlogs.isEmpty) {
      fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var selectedIndex = appState.selectedIndex;
    var prevIndex = appState.prevIndex;

    Widget page;
    String? pageTitle;
    switch (selectedIndex) {
      case 0:
        page = const BlogList();
        pageTitle = 'Blogs';
        break;
      case 1:
        page = const FavoritesPage();
        pageTitle = 'Favorites';
        break;
      case 2:
        page = const BlogPreviewPage();
        pageTitle = 'Preview';
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: selectedIndex != 0
            ? IconButton(
                tooltip: 'Back',
                onPressed: () {
                  appState.togglePage(prevIndex!);
                },
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: Text(pageTitle),
        actions: [
          if (selectedIndex != 1)
            TextButton.icon(
                onPressed: () {
                  appState.togglePage(1);
                },
                icon: const Icon(Icons.favorite_sharp),
                label: const Text('Favorites')),
          IconButton(
            onPressed: () {
              fetchData();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isDataLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : boxBlogs.isEmpty
              ? const Center(
                  child: Text('No blogs available.'),
                )
              : page,
    );
  }
}

class BlogList extends StatelessWidget {
  const BlogList({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: boxBlogs.listenable(),
        builder: (context, box, child) {
          return ListView.builder(
              itemCount: boxBlogs.length,
              itemBuilder: (context, index) {
                final blog = boxBlogs.getAt(index);
                return Card(
                  child: BlogContent(blog: blog),
                );
              });
        });
  }
}

class BlogContent extends StatelessWidget {
  final BlogPost? blog;
  const BlogContent({super.key, required this.blog});

  void onFavoritePress(String id) {
    if (boxFavorites.containsKey(id)) {
      boxFavorites.delete(id);
    } else {
      boxFavorites.put(id, id);
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return GestureDetector(
      onTap: () {
        appState.setBlogPreview(blog!);
        appState.togglePage(2);
      },
      child: ValueListenableBuilder(
          valueListenable: boxFavorites.listenable(),
          builder: ((context, value, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 21 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(blog?.imageUrl ??
                            'https://example.com/default_image.jpg'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Positioned(
                            top: 8.0,
                            right: 8.0,
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                        boxFavorites.containsKey(blog?.id)
                                            ? Icons.favorite
                                            : Icons.favorite_border),
                                    onPressed: () {
                                      onFavoritePress(blog!.id);
                                    },
                                    color: Colors.red,
                                    iconSize: 24.0,
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        blog!.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          })),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: boxFavorites.listenable(),
        builder: (context, box, child) {
          if (boxFavorites.isEmpty) {
            return const Center(
              child: Text('No favorites yet,'),
            );
          }

          final favoriteBlogKeys = box.keys.toList();
          final favoriteBlogs = boxBlogs.values
              .where((blog) => favoriteBlogKeys.contains(blog.id))
              .toList();
          return ListView.builder(
            itemCount: favoriteBlogs.length,
            itemBuilder: (context, index) {
              final blog = favoriteBlogs[index];
              return Card(
                child: BlogContent(blog: blog),
              );
            },
          );
        });
  }
}

class BlogPreviewPage extends StatelessWidget {
  const BlogPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var blog = appState.selectedBlog;

    if (blog == null) {
      return const Center(
        child: Text('No Preview'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 21 / 9,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(blog.imageUrl),
                fit: BoxFit.cover,
              ),
              // borderRadius: const BorderRadius.only(
              //   topLeft: Radius.circular(12.0),
              //   topRight: Radius.circular(12.0),
              // ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                blog.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
