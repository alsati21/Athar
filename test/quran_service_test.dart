import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:untitled4/services/quran_service.dart';

void main() {
  test('fetches the selected ayah range across API pages in order', () async {
    final requestedPages = <int>[];
    final service = QuranService(
      client: MockClient((request) async {
        final page = int.parse(request.url.queryParameters['page']!);
        requestedPages.add(page);
        final firstAyah = (page - 1) * 50 + 1;
        final verses = List.generate(50, (index) {
          final ayahNumber = firstAyah + index;
          return {
            'verse_number': ayahNumber,
            'text_uthmani': 'نص الآية $ayahNumber',
            'audio': {
              'url':
                  'Alafasy/mp3/002${ayahNumber.toString().padLeft(3, '0')}.mp3',
            },
          };
        });
        return http.Response.bytes(
          utf8.encode(jsonEncode({'verses': verses})),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final ayahs = await service.fetchAyahRange(
      surahNumber: 2,
      startAyah: 49,
      endAyah: 52,
      reciterId: 7,
    );

    expect(requestedPages, [1, 2]);
    expect(ayahs.map((ayah) => ayah.ayahNumber), [49, 50, 51, 52]);
    expect(ayahs.first.text, 'نص الآية 49');
    expect(ayahs.last.audioUrl, startsWith('https://audio.qurancdn.com/'));
  });

  test('rejects an invalid ayah range', () {
    final service = QuranService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    expect(
      service.fetchAyahRange(
        surahNumber: 1,
        startAyah: 5,
        endAyah: 4,
        reciterId: 7,
      ),
      throwsArgumentError,
    );
  });
}
