import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recipes_app/recipesDetailed.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class RecipesDisplay extends StatefulWidget {
  const RecipesDisplay({super.key});

  @override
  State<RecipesDisplay> createState() => _RecipesDisplayState();
}

class _RecipesDisplayState extends State<RecipesDisplay> {
  List recipes = [];
  List<dynamic> recipesTags = [];
  bool isLoading = true;
  String selectedTag = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? tagListener;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print('Flutter UI Error: ${details.exception}');
    };
    fetchRecipesTags();
    checkSelectedTag();
    startTagListener();
  }

  void startTagListener() {
    tagListener = Timer.periodic(const Duration(seconds: 2), (timer) {
      listenForTagChange();
    });
  }

  Future<void> listenForTagChange() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTag = prefs.getString('selected_tag');

    print("Tag check: $storedTag");

    if (storedTag != null && storedTag != selectedTag) {
      print("New tag detected: $storedTag");

      setState(() {
        selectedTag = storedTag;
        _searchController.clear();
      });

      await prefs.remove('selected_tag');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Filtering by tag: '$storedTag'")),
        );
      }

      fetchRecipesByTag(storedTag);
    }
  }

  Future<void> checkSelectedTag() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTag = prefs.getString('selected_tag');

    if (storedTag != null && storedTag.isNotEmpty) {
      setState(() => selectedTag = storedTag);
      await prefs.remove('selected_tag');
      fetchRecipesByTag(storedTag);
    } else {
      fetchRecipes();
    }
  }

  Future<void> fetchRecipesTags() async {
    try {
      final response = await http.get(Uri.parse('https://dummyjson.com/recipes/tags'));
      if (response.statusCode == 200) {
        setState(() {
          recipesTags = json.decode(response.body);
        });
      }
    } catch (_) {}
  }

  Future<void> fetchRecipes() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://dummyjson.com/recipes'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recipeList = List<Map<String, dynamic>>.from(data['recipes']);
        setState(() {
          recipes = recipeList;
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchRecipesByTag(String tag) async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://dummyjson.com/recipes'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allRecipes = List<Map<String, dynamic>>.from(data['recipes']);

        final filtered = allRecipes
            .where((recipe) => recipe['tags'].contains(tag))
            .toList();

        print("Filtered ${filtered.length} recipes with tag '$tag'");

        setState(() {
          recipes = filtered;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching recipes by tag: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    tagListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWearOS = defaultTargetPlatform == TargetPlatform.android &&
        MediaQuery.of(context).size.width < 200;

    if (isWearOS) {
      return Scaffold(
        body: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: recipesTags.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(
                recipesTags[index],
                textAlign: TextAlign.center,
              ),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selected_tag', recipesTags[index]);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Tag '${recipesTags[index]}' selected")),
                );
              },
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Recipes")),
      endDrawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(child: Text("Recipe Tags")),
            Expanded(
              child: recipesTags.isEmpty
                  ? const Center(child: Text("No tags found"))
                  : ListView.builder(
                itemCount: recipesTags.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(recipesTags[index]),
                  onTap: () {
                    setState(() => selectedTag = recipesTags[index]);
                    fetchRecipesByTag(selectedTag);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (val) {
                setState(() => selectedTag = '');
                fetchRecipes();
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : recipes.isEmpty
                ? const Center(child: Text("No recipes found"))
                : ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) => ListTile(
                leading: CachedNetworkImage(
                  imageUrl: recipes[index]['image'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                  const CircularProgressIndicator(),
                  errorWidget: (context, url, error) =>
                  const Icon(Icons.image_not_supported),
                ),
                title: Text(recipes[index]['name']),
                subtitle: Text(
                    'Tags: ${recipes[index]['tags'].join(', ')}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipesDetailed(
                        recipeId: recipes[index]['id'],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
