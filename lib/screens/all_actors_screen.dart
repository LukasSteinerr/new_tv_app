import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart'; // For TMDB image URLs

class AllActorsScreen extends StatelessWidget {
  final Movie movie;

  const AllActorsScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Cast for ${movie.name}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          movie.cast == null || movie.cast!.isEmpty
              ? const Center(
                child: Text(
                  'No cast information available.',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Adjust as needed for desired layout
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.6, // Adjust for image/text ratio
                ),
                itemCount: movie.cast!.length,
                itemBuilder: (context, index) {
                  final actor = movie.cast![index];
                  final profileUrl =
                      actor.profilePath != null
                          ? TMDBService.getPosterUrl(actor.profilePath!)
                          : null;

                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            profileUrl != null
                                ? NetworkImage(profileUrl)
                                : null,
                        onBackgroundImageError:
                            profileUrl != null
                                ? (exception, stackTrace) =>
                                    const Icon(Icons.person, size: 40)
                                : null,
                        backgroundColor: Colors.grey[800],
                        child:
                            profileUrl == null
                                ? const Icon(Icons.person, size: 40)
                                : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        actor.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        actor.character,
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
    );
  }
}
