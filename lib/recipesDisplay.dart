import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:recipes_app/recipesDetailed.dart';

class RecipesDisplay extends StatefulWidget {
  const RecipesDisplay({super.key});

  @override
  _RecipesDisplayState createState() => _RecipesDisplayState();
}

class _RecipesDisplayState extends State<RecipesDisplay> {
  List recipes = [];
  List<dynamic> recipesTags = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRecipes();
    fetchRecipesTags();
  }

  Future<void> fetchRecipes({String query = ''}) async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = query.isEmpty
          ? 'https://dummyjson.com/recipes'
          : 'https://dummyjson.com/recipes/search?q=$query';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recipes = data['recipes']
              ?.map((recipe) => {
            'id': recipe['id'],
            'name': recipe['name'],
            'tags': recipe['tags'],
          })
              .toList() ??
              [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      rethrow;
    }
  }

  Future<void> fetchRecipesTags() async {
    try {
      final response = await http.get(Uri.parse('https://dummyjson.com/recipes/tags'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recipesTags = data;
        });
      } else {
        throw Exception('Failed to load recipes tags');
      }
    } catch (e) {
      setState(() {
        recipesTags = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes Display'),
        centerTitle: true,
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            AppBar(
              title: const Text('Recipes Tags'),
              automaticallyImplyLeading: false,
            ),
            Expanded(
              child: recipesTags.isEmpty
                  ? const Center(child: Text('No recipes tags found'))
                  : ListView.builder(
                itemCount: recipesTags.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(recipesTags[index]),
                    onTap: () {
                      fetchRecipes(query: recipesTags[index]);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for recipes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (value) {
                fetchRecipes(query: value);
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : recipes.isEmpty
                ? const Center(child: Text('No recipes found'))
                : ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(recipes[index]['name']),
                  subtitle: Text('Tags: ${recipes[index]['tags'].join(', ')}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RecipesDetailed(recipeId: recipes[index]['id']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
