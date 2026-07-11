from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: expected one match, found {count}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def patch_home() -> None:
    path = Path("lib/features/home/presentation/home_page.dart")
    text = path.read_text(encoding="utf-8")
    text = text.replace(
        "import '../../../core/router/app_router.dart';\n",
        "import '../../../core/router/app_router.dart';\n"
        "import '../../../core/storage/mobile_tab_memory.dart';\n",
        1,
    )
    text = text.replace(
        "import '../../../shared/widgets/loading_indicator.dart';\n",
        "import '../../../shared/utils/responsive_snackbar.dart';\n"
        "import '../../../shared/widgets/loading_indicator.dart';\n",
        1,
    )
    old = """class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistListProvider(null));
    final normalAsync = ref.watch(playlistListProvider('normal'));
    final radioAsync = ref.watch(playlistListProvider('radio'));
    final normalCount = normalAsync.value?.totalCount ?? 0;
    final radioCount = radioAsync.value?.totalCount ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(playlistListProvider(null));
          ref.invalidate(playlistListProvider('normal'));
          ref.invalidate(playlistListProvider('radio'));
        },
        child: CustomScrollView(
          slivers: [
"""
    new = """class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: MobileTabMemory.homeScrollOffset,
    )..addListener(_rememberScrollOffset);
  }

  void _rememberScrollOffset() {
    if (_scrollController.hasClients) {
      MobileTabMemory.homeScrollOffset = _scrollController.offset;
    }
  }

  Future<void> _refreshHome() async {
    ref.invalidate(playlistListProvider(null));
    ref.invalidate(playlistListProvider('normal'));
    ref.invalidate(playlistListProvider('radio'));
    await Future.wait([
      ref.read(playlistListProvider(null).future),
      ref.read(playlistListProvider('normal').future),
      ref.read(playlistListProvider('radio').future),
    ]);
    if (!mounted) return;
    ResponsiveSnackBar.showSuccess(context, message: '首页内容已刷新');
  }

  @override
  void dispose() {
    _scrollController.removeListener(_rememberScrollOffset);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistListProvider(null));
    final normalAsync = ref.watch(playlistListProvider('normal'));
    final radioAsync = ref.watch(playlistListProvider('radio'));
    final normalCount = normalAsync.value?.totalCount ?? 0;
    final radioCount = radioAsync.value?.totalCount ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refreshHome,
        child: CustomScrollView(
          key: const PageStorageKey<String>('home-scroll'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
"""
    if old not in text:
        raise RuntimeError("HomePage block not found")
    text = text.replace(old, new, 1)
    path.write_text(text, encoding="utf-8")


def patch_library() -> None:
    path = Path("lib/features/library/presentation/library_page.dart")
    text = path.read_text(encoding="utf-8")
    text = text.replace(
        "import '../../../core/theme/app_dimensions.dart';\n",
        "import '../../../core/storage/mobile_tab_memory.dart';\n"
        "import '../../../core/theme/app_dimensions.dart';\n",
        1,
    )
    text = text.replace(
        "  final _scrollController = ScrollController();\n"
        "  final _searchController = TextEditingController();\n"
        "  Timer? _debounceTimer;\n",
        "  late final ScrollController _scrollController;\n"
        "  final _searchController = TextEditingController();\n"
        "  Timer? _debounceTimer;\n"
        "  bool _showIntroHeader = true;\n",
        1,
    )
    text = text.replace(
        """  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(songsListProvider.notifier).loadSongs();
    });
  }
""",
        """  void initState() {
    super.initState();
    final rememberedSearch = ref.read(songsListProvider).keyword;
    _searchController.text = rememberedSearch;
    MobileTabMemory.librarySearch = rememberedSearch;
    _scrollController = ScrollController(
      initialScrollOffset: MobileTabMemory.libraryScrollOffset,
    )..addListener(_onScroll);
    _showIntroHeader = MobileTabMemory.libraryScrollOffset < 72;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(songsListProvider);
      if (current.songs.isEmpty && !current.isLoading) {
        ref.read(songsListProvider.notifier).loadSongs();
      }
    });
  }
""",
        1,
    )
    old_scroll = """  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(songsListProvider.notifier).loadMore();
    }
  }
"""
    new_scroll = """  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    MobileTabMemory.libraryScrollOffset = position.pixels;
    final showHeader = position.pixels < 72;
    if (showHeader != _showIntroHeader && mounted) {
      setState(() => _showIntroHeader = showHeader);
    }
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(songsListProvider.notifier).loadMore();
    }
  }
"""
    text = text.replace(old_scroll, new_scroll, 1)
    text = text.replace(
        """  void _onSearchChanged(String value) {
    setState(() {});
    _debounceTimer?.cancel();
""",
        """  void _onSearchChanged(String value) {
    MobileTabMemory.librarySearch = value;
    setState(() {});
    _debounceTimer?.cancel();
""",
        1,
    )
    text = text.replace(
        """          if (!state.isSelectionMode) _buildLibraryHeader(context, state),
          SongFilterBar(
""",
        """          if (!state.isSelectionMode)
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child:
                  _showIntroHeader
                      ? _buildLibraryHeader(context, state)
                      : const SizedBox.shrink(),
            ),
          SongFilterBar(
""",
        1,
    )
    text = text.replace(
        "onRefresh: () => ref.read(songsListProvider.notifier).refresh(),",
        "onRefresh: _refreshLibrary,",
        1,
    )
    text = text.replace(
        """    return ListView.builder(
      controller: _scrollController,
""",
        """    return ListView.builder(
      key: const PageStorageKey<String>('library-song-list'),
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
""",
        1,
    )
    insert_marker = "  Widget _buildSongList(BuildContext context, SongsListState state) {\n"
    refresh_method = """  Future<void> _refreshLibrary() async {
    await ref.read(songsListProvider.notifier).refresh();
    if (!mounted) return;
    final state = ref.read(songsListProvider);
    if (state.error == null) {
      ResponsiveSnackBar.showSuccess(context, message: '歌曲库已刷新');
    }
  }

"""
    if refresh_method.strip() not in text:
        text = text.replace(insert_marker, refresh_method + insert_marker, 1)
    path.write_text(text, encoding="utf-8")


def patch_playlists() -> None:
    path = Path("lib/features/playlist/presentation/playlists_page.dart")
    text = path.read_text(encoding="utf-8")
    text = text.replace(
        "import '../../../config/constants.dart';\n",
        "import '../../../config/constants.dart';\n"
        "import '../../../core/storage/mobile_tab_memory.dart';\n",
        1,
    )
    text = text.replace(
        "  String? _selectedType;\n",
        "  String? _selectedType = MobileTabMemory.playlistType;\n",
        1,
    )
    text = text.replace(
        "  final _searchController = TextEditingController();\n"
        "  Timer? _searchDebounce;\n"
        "  String _searchQuery = '';\n",
        "  final _searchController = TextEditingController(\n"
        "    text: MobileTabMemory.playlistsSearch,\n"
        "  );\n"
        "  Timer? _searchDebounce;\n"
        "  String _searchQuery = MobileTabMemory.playlistsSearch;\n",
        1,
    )
    text = text.replace(
        """  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }
""",
        """  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: MobileTabMemory.playlistsScrollOffset,
    )..addListener(_onScroll);
  }
""",
        1,
    )
    text = text.replace(
        """    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
""",
        """    final position = _scrollController.position;
    MobileTabMemory.playlistsScrollOffset = position.pixels;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
""",
        1,
    )
    text = text.replace(
        """      if (!mounted) return;
      setState(() => _searchQuery = query);
""",
        """      if (!mounted) return;
      MobileTabMemory.playlistsSearch = query;
      setState(() => _searchQuery = query);
""",
        1,
    )
    text = text.replace(
        """    _searchController.clear();
    setState(() => _searchQuery = '');
""",
        """    _searchController.clear();
    MobileTabMemory.playlistsSearch = '';
    setState(() => _searchQuery = '');
""",
        1,
    )
    text = text.replace(
        """    setState(() {
      _selectedType = type;
      _selectedPlaylistIds.clear();
    });
""",
        """    MobileTabMemory.playlistType = type;
    setState(() {
      _selectedType = type;
      _selectedPlaylistIds.clear();
    });
""",
        1,
    )
    text = text.replace(
        """                onRefresh: () async {
                  ref.invalidate(playlistListProvider(_selectedType));
                },
""",
        """                onRefresh: _refreshPlaylists,
""",
        1,
    )
    text = text.replace(
        """                    child: CustomScrollView(
                      controller: _scrollController,
""",
        """                    child: CustomScrollView(
                      key: const PageStorageKey<String>('playlists-scroll'),
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
""",
        1,
    )
    marker = "  Widget _buildSearchBar() {\n"
    method = """  Future<void> _refreshPlaylists() async {
    ref.invalidate(playlistListProvider(_selectedType));
    await ref.read(playlistListProvider(_selectedType).future);
    if (!mounted) return;
    ResponsiveSnackBar.showSuccess(context, message: '歌单已刷新');
  }

"""
    if method.strip() not in text:
        text = text.replace(marker, method + marker, 1)
    path.write_text(text, encoding="utf-8")


def patch_player() -> None:
    path = Path("lib/features/player/presentation/widgets/mobile_player.dart")
    text = path.read_text(encoding="utf-8")
    text = text.replace(
        "  int _currentPage = 0;\n",
        "  int _currentPage = 0;\n"
        "  double _dragOffset = 0;\n"
        "  bool _isDragging = false;\n",
        1,
    )
    marker = "  @override\n  Widget build(BuildContext context) {\n"
    methods = """  void _closePlayer() {
    ref.read(playerStateProvider.notifier).closeFullPlayer();
    Navigator.of(context).pop();
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _handleVerticalDragUpdate(
    DragUpdateDetails details,
    double maxOffset,
  ) {
    final next = (_dragOffset + details.delta.dy).clamp(0.0, maxOffset);
    if (next != _dragOffset) {
      setState(() => _dragOffset = next.toDouble());
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldClose = _dragOffset > 110 || velocity > 700;
    if (shouldClose) {
      _closePlayer();
      return;
    }
    setState(() {
      _isDragging = false;
      _dragOffset = 0;
    });
  }

"""
    if methods.strip() not in text:
        text = text.replace(marker, methods + marker, 1)
    text = text.replace(
        """    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
""",
        """    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: _handleVerticalDragStart,
      onVerticalDragUpdate:
          (details) => _handleVerticalDragUpdate(details, size.height * 0.45),
      onVerticalDragEnd: _handleVerticalDragEnd,
      child: AnimatedContainer(
        duration:
            _isDragging ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _dragOffset, 0),
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Stack(
""",
        1,
    )
    text = text.replace(
        """        ],
      ),
    );
  }

  /// 构建页面指示器（小圆点）
""",
        """          ],
        ),
      ),
    );
  }

  /// 构建页面指示器（小圆点）
""",
        1,
    )
    text = text.replace(
        """            onPressed: () {
              notifier.closeFullPlayer();
              Navigator.of(context).pop();
            },
""",
        """            onPressed: _closePlayer,
""",
        1,
    )
    path.write_text(text, encoding="utf-8")


def main() -> None:
    memory = Path("lib/core/storage/mobile_tab_memory.dart")
    memory.write_text(
        """/// 进程内保存手机端一级页面的临时现场。\n"
        "///\n"
        "/// 仅用于标签页切换时恢复滚动、搜索和筛选，不写入磁盘。\n"
        "class MobileTabMemory {\n"
        "  MobileTabMemory._();\n\n"
        "  static double homeScrollOffset = 0;\n"
        "  static double libraryScrollOffset = 0;\n"
        "  static double playlistsScrollOffset = 0;\n\n"
        "  static String librarySearch = '';\n"
        "  static String playlistsSearch = '';\n"
        "  static String? playlistType;\n"
        "}\n""",
        encoding="utf-8",
    )
    patch_home()
    patch_library()
    patch_playlists()
    patch_player()
    print("Applied mobile polish round 1")


if __name__ == "__main__":
    main()
