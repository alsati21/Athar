import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

import 'quran_service.dart';

class FfmpegService {
  Future<String> createReel({
    required File backgroundVideo,
    required List<ReelSegment> segments,
    String? fontFilePath,
  }) async {
    if (segments.isEmpty) {
      throw ArgumentError('يجب اختيار آية واحدة على الأقل');
    }

    final directory = await getTemporaryDirectory();
    await directory.create(recursive: true);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final audioListFile = File('${directory.path}/quran_audio_$timestamp.txt');
    final combinedAudioFile = File(
      '${directory.path}/quran_audio_$timestamp.mp3',
    );
    final outputFile = File('${directory.path}/quran_reel_$timestamp.mp4');

    final audioList = StringBuffer();
    var startTime = 0.0;
    final textFilters = <String>[];
    final font = (fontFilePath != null && fontFilePath.isNotEmpty)
        ? ':fontfile=${_escapeFilterValue(fontFilePath)}'
        : '';

    for (final segment in segments) {
      if (!await segment.audioFile.exists()) {
        throw Exception('ملف صوت الآية ${segment.ayahNumber} غير موجود');
      }

      final probeSession = await FFprobeKit.getMediaInformation(
        segment.audioFile.path,
      );
      final duration = double.tryParse(
        probeSession.getMediaInformation()?.getDuration() ?? '',
      );
      if (duration == null || !duration.isFinite || duration <= 0) {
        throw Exception('تعذر تحديد مدة صوت الآية ${segment.ayahNumber}');
      }

      final textFile = File(
        '${directory.path}/quran_ayah_${timestamp}_${segment.ayahNumber}.txt',
      );
      await textFile.writeAsString(_wrapArabicText(segment.text), flush: true);
      if (await textFile.length() == 0) {
        throw Exception('نص الآية ${segment.ayahNumber} فارغ');
      }

      final endTime = startTime + duration;
      textFilters.add(
        'drawtext=textfile=${_escapeFilterValue(textFile.path)}$font'
        ':fontcolor=white:fontsize=54:line_spacing=14'
        ':borderw=3:bordercolor=black@0.75'
        ':x=(w-text_w)/2:y=(h-text_h)/2'
        ':enable=\'between(t\\,${startTime.toStringAsFixed(3)}\\,${endTime.toStringAsFixed(3)})\'',
      );
      audioList.writeln("file '${_escapeConcatPath(segment.audioFile.path)}'");
      startTime = endTime;
    }

    await audioListFile.writeAsString(audioList.toString(), flush: true);
    await _execute([
      '-y',
      '-f',
      'concat',
      '-safe',
      '0',
      '-i',
      audioListFile.path,
      '-c:a',
      'copy',
      combinedAudioFile.path,
    ], 'تعذر دمج تلاوة الآيات');

    final videoFilter = [
      'scale=1080:1920:force_original_aspect_ratio=increase',
      'crop=1080:1920',
      ...textFilters,
    ].join(',');
    final isImage = _isImage(backgroundVideo.path);
    await _execute([
      '-y',
      if (isImage) ...[
        '-loop',
        '1',
        '-framerate',
        '25',
      ] else ...[
        '-stream_loop',
        '-1',
      ],
      '-i',
      backgroundVideo.path,
      '-i',
      combinedAudioFile.path,
      '-vf',
      videoFilter,
      '-map',
      '0:v:0',
      '-map',
      '1:a:0',
      '-shortest',
      '-c:v',
      'libx264',
      '-preset',
      'veryfast',
      '-c:a',
      'aac',
      '-pix_fmt',
      'yuv420p',
      outputFile.path,
    ], 'تعذر إنشاء الفيديو');

    return outputFile.path;
  }

  Future<void> _execute(List<String> arguments, String errorMessage) async {
    final session = await FFmpegKit.executeWithArguments(arguments);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw Exception('$errorMessage: ${logs ?? 'خطأ غير معروف'}');
    }
  }

  bool _isImage(String path) {
    final extension = path.split('.').last.toLowerCase();
    return const {'jpg', 'jpeg', 'png', 'webp', 'bmp'}.contains(extension);
  }

  String _escapeConcatPath(String path) {
    return path.replaceAll('\\', '/').replaceAll("'", r"'\''");
  }

  String _wrapArabicText(String text, {int maxLineLength = 38}) {
    final lines = <String>[];
    var line = '';
    for (final word in text.trim().split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      if (line.isNotEmpty && line.length + word.length + 1 > maxLineLength) {
        lines.add(line);
        line = word;
      } else {
        line = line.isEmpty ? word : '$line $word';
      }
    }
    if (line.isNotEmpty) lines.add(line);
    return lines.join('\n');
  }

  String _escapeFilterValue(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(':', r'\:')
        .replaceAll(',', r'\,')
        .replaceAll("'", r"\'")
        .replaceAll('[', r'\[')
        .replaceAll(']', r'\]');
  }
}
