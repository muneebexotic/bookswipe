import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

/// Book model matching the Supabase books table
@freezed
class Book with _$Book {
  const factory Book({
    required String isbn,
    required String title,
    String? author,
    @JsonKey(name: 'cover_url') String? coverUrl,
    String? description,
    @JsonKey(name: 'page_count') int? pageCount,
    @JsonKey(name: 'publish_year') int? publishYear,
    @JsonKey(name: 'spice_rating') int? spiceRating,
    @Default([]) List<String> tropes,
    @Default([]) List<String> moods,
    @JsonKey(name: 'trigger_warnings')
    @Default([])
    List<String> triggerWarnings,
    @JsonKey(name: 'generated_hook') String? generatedHook,
    @JsonKey(name: 'is_enriched') @Default(0) int isEnriched,
    @JsonKey(name: 'popularity_score') @Default(0) int popularityScore,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}
