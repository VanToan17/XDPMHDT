import 'package:flutter/material.dart';
import '/models/film_model.dart';
import '/api_service.dart';
import '/app.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Film> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchFilms() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    setState(() => _isLoading = true);

    final results = await ApiService.searchFilms(keyword);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FrameScreen(
      showDefaultBottomBar: true,
      showAppBar: true,
      title: 'Tìm kiếm phim',
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập tên phim hoặc thể loại...',
                hintStyle: const TextStyle(
                  color: Color.fromARGB(200, 255, 255, 255),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _searchFilms,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF7fff00)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF7fff00),
                    width: 2,
                  ),
                ),
              ),
              style: const TextStyle(color: Colors.white),

              onSubmitted: (_) => _searchFilms(),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: _searchResults.isEmpty
                        ? const Center(child: Text('Không tìm thấy phim'))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 12,
                                runSpacing: 12,
                                children: _searchResults.map((film) {
                                  return GestureDetector(
                                    onTap: () {
                                      context.push('/movie/${film.id}');
                                    },
                                    child: SizedBox(
                                      width: 120,
                                      height: 220,
                                      child: Card(
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Image.network(
                                          'http://10.0.2.2:8000/storage/${film.img}',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, _) =>
                                              const Center(
                                                child: Icon(Icons.broken_image),
                                              ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
