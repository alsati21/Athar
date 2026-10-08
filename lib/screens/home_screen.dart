import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../services/ffmpeg_service.dart';
import '../services/quran_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _surahNames = <String>[
    'الفاتحة',
    'البقرة',
    'آل عمران',
    'النساء',
    'المائدة',
    'الأنعام',
    'الأعراف',
    'الأنفال',
    'التوبة',
    'يونس',
    'هود',
    'يوسف',
    'الرعد',
    'إبراهيم',
    'الحجر',
    'النحل',
    'الإسراء',
    'الكهف',
    'مريم',
    'طه',
    'الأنبياء',
    'الحج',
    'المؤمنون',
    'النور',
    'الفرقان',
    'الشعراء',
    'النمل',
    'القصص',
    'العنكبوت',
    'الروم',
    'لقمان',
    'السجدة',
    'الأحزاب',
    'سبأ',
    'فاطر',
    'يس',
    'الصافات',
    'ص',
    'الزمر',
    'غافر',
    'فصلت',
    'الشورى',
    'الزخرف',
    'الدخان',
    'الجاثية',
    'الأحقاف',
    'محمد',
    'الفتح',
    'الحجرات',
    'ق',
    'الذاريات',
    'الطور',
    'النجم',
    'القمر',
    'الرحمن',
    'الواقعة',
    'الحديد',
    'المجادلة',
    'الحشر',
    'الممتحنة',
    'الصف',
    'الجمعة',
    'المنافقون',
    'التغابن',
    'الطلاق',
    'التحريم',
    'الملك',
    'القلم',
    'الحاقة',
    'المعارج',
    'نوح',
    'الجن',
    'المزمل',
    'المدثر',
    'القيامة',
    'الإنسان',
    'المرسلات',
    'النبأ',
    'النازعات',
    'عبس',
    'التكوير',
    'الانفطار',
    'المطففين',
    'الانشقاق',
    'البروج',
    'الطارق',
    'الأعلى',
    'الغاشية',
    'الفجر',
    'البلد',
    'الشمس',
    'الليل',
    'الضحى',
    'الشرح',
    'التين',
    'العلق',
    'القدر',
    'البينة',
    'الزلزلة',
    'العاديات',
    'القارعة',
    'التكاثر',
    'العصر',
    'الهمزة',
    'الفيل',
    'قريش',
    'الماعون',
    'الكوثر',
    'الكافرون',
    'النصر',
    'المسد',
    'الإخلاص',
    'الفلق',
    'الناس',
  ];

  static const _ayahCounts = <int>[
    7,
    286,
    200,
    176,
    120,
    165,
    206,
    75,
    129,
    109,
    123,
    111,
    43,
    52,
    99,
    128,
    111,
    110,
    98,
    135,
    112,
    78,
    118,
    64,
    77,
    227,
    93,
    88,
    69,
    60,
    34,
    30,
    73,
    54,
    45,
    83,
    182,
    88,
    75,
    85,
    54,
    53,
    89,
    59,
    37,
    35,
    38,
    29,
    18,
    45,
    60,
    49,
    62,
    55,
    78,
    96,
    29,
    22,
    24,
    13,
    14,
    11,
    11,
    18,
    12,
    12,
    30,
    52,
    52,
    44,
    28,
    28,
    20,
    56,
    40,
    31,
    50,
    40,
    46,
    42,
    29,
    19,
    36,
    25,
    22,
    17,
    19,
    26,
    30,
    20,
    15,
    21,
    11,
    8,
    8,
    19,
    5,
    8,
    8,
    11,
    11,
    8,
    3,
    9,
    5,
    4,
    7,
    3,
    6,
    3,
    5,
    4,
    5,
    6,
  ];

  static const _reciters = <int, String>{
    7: 'مشاري راشد العفاسي',
    1: 'عبد الباسط عبد الصمد',
    2: 'محمد صديق المنشاوي',
    3: 'عبدالرحمن السديس',
  };

  final _quran = QuranService();
  final _ffmpeg = FfmpegService();
  int _surah = 1;
  int _ayahNumber = 1;
  int _endAyahNumber = 1;
  int _reciter = 7;
  QuranAyah? _ayah;
  File? _backgroundVideo;
  VideoPlayerController? _video;
  bool _backgroundIsImage = false;
  bool _loadingAyah = true;
  bool _selectingBackground = false;
  bool _exporting = false;
  double _progress = 0;
  String? _message;
  String? _outputPath;

  @override
  void initState() {
    super.initState();
    _loadAyah();
  }

  @override
  void dispose() {
    _video?.dispose();
    _quran.dispose();
    super.dispose();
  }

  Future<void> _loadAyah() async {
    setState(() {
      _loadingAyah = true;
      _message = null;
      _ayah = null;
    });
    try {
      final ayah = await _quran.fetchAyah(
        surahNumber: _surah,
        ayahNumber: _ayahNumber,
        reciterId: _reciter,
      );
      if (!mounted) return;
      setState(() {
        _ayah = ayah;
        _loadingAyah = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingAyah = false;
        _message = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<File> _downloadAudio(QuranAyah ayah) async {
    final response = await http.get(Uri.parse(ayah.audioUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('تعذر تنزيل صوت الآية ${ayah.ayahNumber}');
    }
    final directory = await getTemporaryDirectory();
    return File(
      '${directory.path}/quran_${ayah.surahNumber}_${ayah.ayahNumber}_${DateTime.now().microsecondsSinceEpoch}.mp3',
    ).writeAsBytes(response.bodyBytes, flush: true);
  }

  Future<List<ReelSegment>> _downloadAyahs(List<QuranAyah> ayahs) async {
    final segments = <ReelSegment>[];
    const batchSize = 4;
    for (var start = 0; start < ayahs.length; start += batchSize) {
      final batch = ayahs.skip(start).take(batchSize).toList();
      final audioFiles = await Future.wait(batch.map(_downloadAudio));
      for (var index = 0; index < batch.length; index++) {
        segments.add(
          ReelSegment(
            ayahNumber: batch[index].ayahNumber,
            text: batch[index].text,
            audioFile: audioFiles[index],
          ),
        );
      }
      if (mounted) {
        setState(() {
          _progress = .15 + .4 * segments.length / ayahs.length;
        });
      }
    }
    return segments;
  }

  // ← جديد: تحميل الخط العربي من الـ assets إلى ملف مؤقت ليستخدمه FFmpeg
  Future<String> _prepareFont() async {
    final data = await rootBundle.load('asset/fonts/Amiri-Regular.ttf');
    final file = File('${(await getTemporaryDirectory()).path}/Amiri.ttf');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return file.path;
  }

  Future<void> _selectBackgroundVideo() async {
    if (_selectingBackground || _exporting) return;
    setState(() {
      _selectingBackground = true;
      _message = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.media);
      if (!mounted || result == null) return;
      final path = result.files.single.path;
      if (path == null) {
        throw Exception('تعذر الوصول إلى ملف الفيديو المحدد');
      }
      final video = File(path);
      if (!await video.exists()) {
        throw Exception('ملف الفيديو المحدد غير موجود');
      }
      setState(() {
        _backgroundVideo = video;
        _backgroundIsImage = _isImage(path);
      });
      await _setPreview(video);
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _selectingBackground = false);
    }
  }

  Future<void> _exportVideo() async {
    final background = _backgroundVideo;
    if (_ayah == null || background == null || _exporting) return;
    setState(() {
      _exporting = true;
      _progress = .05;
      _message = null;
      _outputPath = null;
    });
    try {
      setState(() => _progress = .1);
      final ayahs = await _quran.fetchAyahRange(
        surahNumber: _surah,
        startAyah: _ayahNumber,
        endAyah: _endAyahNumber,
        reciterId: _reciter,
      );
      final segments = await _downloadAyahs(ayahs);
      if (mounted) setState(() => _progress = .6);
      final fontPath = await _prepareFont();
      final output = await _ffmpeg.createReel(
        backgroundVideo: background,
        segments: segments,
        fontFilePath: fontPath,
      );
      await Gal.putVideo(output, album: 'Quran Reels');
      if (!mounted) return;
      setState(() {
        _progress = 1;
        _outputPath = output;
        _message = 'تم حفظ ${ayahs.length} آيات في المعرض داخل ألبوم ';
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _setPreview(File file) async {
    await _video?.dispose();
    _video = null;
    if (_isImage(file.path)) {
      if (mounted) setState(() {});
      return;
    }
    final controller = VideoPlayerController.file(file);
    setState(() => _video = controller);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _message = 'تعذر تشغيل فيديو المعاينة');
    }
  }

  bool _isImage(String path) {
    final extension = path.split('.').last.toLowerCase();
    return const {'jpg', 'jpeg', 'png', 'webp', 'bmp'}.contains(extension);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 76,
          titleSpacing: 20,
          title: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xff176b5b),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'مقاطع قرآنية',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'QURAN REELS STUDIO',
                    style: TextStyle(fontSize: 9, letterSpacing: 1.2),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 14),
              child: IconButton.filledTonal(
                onPressed: _loadingAyah ? null : _loadAyah,
                tooltip: 'تحديث الآية',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final preview = _buildPreview(context);
              final controls = _buildControls(context);
              final wide = constraints.maxWidth >= 850;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth < 500 ? 18 : 32,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsetsDirectional.only(
                            bottom: 22,
                            start: 4,
                            end: 4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 6),
                              Text(
                                'اختر آية واحدة أو نطاقًا من الآيات، ثم أنشئ مقطعك وشاركه بسهولة.',
                                style: TextStyle(
                                  color: Color(0xff718078),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: preview),
                              const SizedBox(width: 28),
                              SizedBox(width: 410, child: controls),
                            ],
                          )
                        else
                          Column(
                            children: [
                              preview,
                              const SizedBox(height: 22),
                              controls,
                            ],
                          ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'بكل آيةٍ نرتقي',
                            style: TextStyle(
                              color: Color(0xff829087),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final controller = _video;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 12, start: 2),
          child: Row(
            children: [
              const Text(
                'معاينة المقطع',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffe3eee7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Color(0xff2f8a62), size: 8),
                    SizedBox(width: 6),
                    Text(
                      'عمودي 9:16',
                      style: TextStyle(color: Color(0xff426454), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xff10231f),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x180c2c23),
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_backgroundIsImage && _backgroundVideo != null)
                      Image.file(_backgroundVideo!, fit: BoxFit.cover)
                    else if (controller?.value.isInitialized == true)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller!.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      )
                    else
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Color(0xff244d40),
                              Color(0xff10231f),
                              Color(0xff091512),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.movie_creation_outlined,
                            size: 58,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x22000000),
                            Color(0x11000000),
                            Color(0x88000000),
                          ],
                        ),
                      ),
                    ),
                    if (_loadingAyah)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    else if (_ayah != null)
                      Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                                vertical: 72,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SizedBox(
                                  width: constraints.maxWidth - 50,
                                  child: Text(
                                    _ayah!.text,
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      height: 1.9,
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black87,
                                          blurRadius: 12,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    PositionedDirectional(
                      top: 16,
                      start: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .35),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          '${_surahNames[_surah - 1]}  •  الآيات $_ayahNumber–$_endAyahNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const PositionedDirectional(
                      bottom: 17,
                      start: 0,
                      end: 0,
                      child: Text(
                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xffe5f0e9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xff176b5b),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات المقطع',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'خصص الآية والصوت والخلفية',
                        style: TextStyle(
                          color: Color(0xff78847d),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'الخلفية',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            Material(
              color: const Color(0xfff5f8f4),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: _selectingBackground || _exporting
                    ? null
                    : _selectBackgroundVideo,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xffe1e9e2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xffe5f0e9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _selectingBackground
                            ? const Padding(
                                padding: EdgeInsets.all(13),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _backgroundVideo == null
                                    ? Icons.add_photo_alternate_outlined
                                    : Icons.check_rounded,
                                color: const Color(0xff176b5b),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectingBackground
                                  ? 'جارٍ اختيار الخلفية...'
                                  : _backgroundVideo == null
                                  ? 'اختر صورة أو فيديو'
                                  : 'تم اختيار الخلفية',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _backgroundVideo == null
                                  ? 'ستظهر خلفية للمقطع العمودي'
                                  : _backgroundVideo!.path
                                        .split(Platform.pathSeparator)
                                        .last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xff78847d),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xff718078),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'الآيات والتلاوة',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _surah,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'السورة',
                prefixIcon: Icon(Icons.menu_book_rounded),
              ),
              items: List.generate(_surahNames.length, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _surahNames[index],
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xff89948d),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _surah = value;
                  _ayahNumber = 1;
                  _endAyahNumber = 1;
                });
                _loadAyah();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _ayahNumber,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'من آية',
                      prefixIcon: Icon(Icons.first_page_rounded),
                    ),
                    items: List.generate(
                      _ayahCounts[_surah - 1],
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _ayahNumber = value;
                        if (_endAyahNumber < value) _endAyahNumber = value;
                      });
                      _loadAyah();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _endAyahNumber,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'إلى آية',
                      prefixIcon: Icon(Icons.last_page_rounded),
                    ),
                    items: List.generate(
                      _ayahCounts[_surah - 1] - _ayahNumber + 1,
                      (index) => DropdownMenuItem(
                        value: index + _ayahNumber,
                        child: Text('${index + _ayahNumber}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _endAyahNumber = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                _ayahNumber == _endAyahNumber
                    ? 'سيتم تضمين آية واحدة'
                    : 'سيتم تضمين ${_endAyahNumber - _ayahNumber + 1} آيات بالترتيب',
                style: const TextStyle(color: Color(0xff718078), fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _reciter,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'القارئ',
                prefixIcon: Icon(Icons.record_voice_over_rounded),
              ),
              items: _reciters.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _reciter = value);
                _loadAyah();
              },
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _ayah == null || _backgroundVideo == null || _exporting
                  ? null
                  : _exportVideo,
              icon: _exporting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.movie_creation_outlined),
              label: Text(
                _exporting ? 'جارٍ إنشاء المقطع...' : 'إنشاء وحفظ في المعرض',
              ),
            ),
            if (_exporting) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 6),
              Text(
                '${(_progress * 100).round()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xff718078), fontSize: 12),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: _outputPath == null
                      ? const Color(0xfffff0ed)
                      : const Color(0xffe8f4eb),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(
                      _outputPath == null
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: _outputPath == null
                          ? theme.colorScheme.error
                          : const Color(0xff28734f),
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _outputPath == null
                              ? theme.colorScheme.error
                              : const Color(0xff28734f),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
