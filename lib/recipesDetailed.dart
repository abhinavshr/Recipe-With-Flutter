import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipesDetailed extends StatefulWidget {
  final int recipeId;

  const RecipesDetailed({super.key, required this.recipeId});

  @override
  _RecipesDetailedState createState() => _RecipesDetailedState();
}

class _RecipesDetailedState extends State<RecipesDetailed> {
  Map<String, dynamic>? recipeData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecipe();
  }

  Future<void> fetchRecipe() async {
    final response = await http.get(
      Uri.parse('https://dummyjson.com/recipes/${widget.recipeId}'),
    );

    if (response.statusCode == 200) {
      setState(() {
        recipeData = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load recipe');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recipe Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recipeData == null
          ? const Center(child: Text("Failed to load recipe"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(recipeData!['image'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover),
            ),
            const SizedBox(height: 10),

            // Recipe Name
            Text(recipeData!['name'],
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            // Rating and Review Count
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 5),
                Text('${recipeData!['rating']} '
                    '(${recipeData!['reviewCount']} reviews)'),
              ],
            ),

            const SizedBox(height: 10),

            // Cuisine and Difficulty
            Text("Cuisine: ${recipeData!['cuisine']}"),
            Text("Difficulty: ${recipeData!['difficulty']}"),

            const SizedBox(height: 10),

            // Meal Type
            Text("Meal Type: ${recipeData!['mealType'].join(', ')}"),

            const SizedBox(height: 10),

            // Prep & Cook Time
            Text("Prep Time: ${recipeData!['prepTimeMinutes']} min"),
            Text("Cook Time: ${recipeData!['cookTimeMinutes']} min"),

            const SizedBox(height: 10),

            // Calories
            Text("Calories per Serving: ${recipeData!['caloriesPerServing']} kcal",
                style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            // Ingredients
            const Text("Ingredients:",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            ...recipeData!['ingredients'].map<Widget>((ingredient) =>
                Text("- $ingredient", style: const TextStyle(fontSize: 16))),

            const SizedBox(height: 10),

            // Instructions
            const Text("Instructions:",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            ...recipeData!['instructions'].map<Widget>(
                  (instruction) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text("• $instruction",
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
