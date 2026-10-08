import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class QuranAyah {
  const QuranAyah({
    required this.text,
    required this.audioUrl,
    required this.surahNumber,
    required this.ayahNumber,
  });

  final String text;
  final String audioUrl;
  final int surahNumber;
  final int ayahNumber;
}

class ReelSegment {
  const ReelSegment({
    required this.ayahNumber,
    required this.text,
    required this.audioFile,
  });

  final int ayahNumber;
  final String text;
  final File audioFile;
}

class QuranService {
  QuranService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<QuranAyah> fetchAyah({
    required int surahNumber,
    required int ayahNumber,
    required int reciterId,
  }) async {
    final uri = Uri.https(
      'api.quran.com',
      '/api/v4/verses/by_key/$surahNumber:$ayahNumber',
      <String, String>{'audio': '$reciterId', 'fields': 'text_uthmani'},
    );
    final response = await _client.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('تعذر جلب الآية (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final verse = data['verse'] as Map<String, dynamic>?;
    final audio = verse?['audio'] as Map<String, dynamic>?;
    final text = verse?['text_uthmani'] as String?;
    final audioUrl = audio?['url'] as String?;

    if (text == null || audioUrl == null) {
      throw Exception('استجابة Quran.com لا تحتوي على بيانات الآية كاملة');
    }

    return QuranAyah(
      text: text,
      audioUrl: _absoluteUrl(audioUrl),
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
  }

  Future<List<QuranAyah>> fetchAyahRange({
    required int surahNumber,
    required int startAyah,
    required int endAyah,
    required int reciterId,
  }) async {
    if (startAyah < 1 || endAyah < startAyah) {
      throw ArgumentError('نطاق الآيات غير صالح');
    }

    const perPage = 50;
    final firstPage = ((startAyah - 1) ~/ perPage) + 1;
    final lastPage = ((endAyah - 1) ~/ perPage) + 1;
    final ayahs = <QuranAyah>[];

    for (var page = firstPage; page <= lastPage; page++) {
      final uri = Uri.https(
        'api.quran.com',
        '/api/v4/verses/by_chapter/$surahNumber',
        <String, String>{
          'audio': '$reciterId',
          'fields': 'text_uthmani',
          'per_page': '$perPage',
          'page': '$page',
        },
      );
      final response = await _client.get(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('تعذر جلب الآيات (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final verses = data['verses'] as List<dynamic>?;
      if (verses == null) {
        throw Exception('استجابة Quran.com لا تحتوي على قائمة الآيات');
      }

      for (final item in verses) {
        final verse = item as Map<String, dynamic>;
        final ayahNumber = verse['verse_number'] as int?;
        if (ayahNumber == null ||
            ayahNumber < startAyah ||
            ayahNumber > endAyah) {
          continue;
        }

        final text = verse['text_uthmani'] as String?;
        final audio = verse['audio'] as Map<String, dynamic>?;
        final audioUrl = audio?['url'] as String?;
        if (text == null || audioUrl == null) {
          throw Exception(
            'استجابة Quran.com لا تحتوي على بيانات الآية $ayahNumber كاملة',
          );
        }

        ayahs.add(
          QuranAyah(
            text: text,
            audioUrl: _absoluteUrl(audioUrl),
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
          ),
        );
      }
    }

    if (ayahs.length != endAyah - startAyah + 1) {
      throw Exception('تعذر جلب جميع الآيات المحددة');
    }
    return ayahs;
  }

  String _absoluteUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return 'https://audio.qurancdn.com/$value';
  }

  void dispose() => _client.close();
}
