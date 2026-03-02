import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/providers/center_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/widgets/premium_widgets.dart';
import 'widgets/smart_material_tile.dart';
import 'widgets/upload_material_dialog.dart';

class TeacherMaterialsScreen extends StatefulWidget {
  const TeacherMaterialsScreen({super.key});

  @override
  State<TeacherMaterialsScreen> createState() => _TeacherMaterialsScreenState();
}

class _TeacherMaterialsScreenState extends State<TeacherMaterialsScreen> {
  String _selectedCategory = 'all';
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _materials = [];
  Map<String, dynamic> _stats = {};

  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    await _loadData();
  }

  Future<void> _loadData({bool reset = false}) async {
    if (!mounted) return;
    setState(() {
      if (reset) {
        _isLoading = true;
        _materials = [];
        _currentPage = 0;
        _hasMore = true;
      }
      _error = null;
    });

    try {
      final repository = context.read<SupabaseRepository>();
      final centerProvider = context.read<CenterProvider>();
      final centerId = centerProvider.currentCenterId;

      if (centerId == null) {
        setState(() {
          _error = 'لم يتم تحديد السنتر';
          _isLoading = false;
        });
        return;
      }

      final materials = await repository.getTeacherMaterials(
        centerId: centerId,
        fileType: _selectedCategory == 'all' ? null : _selectedCategory,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      final stats = reset
          ? await repository.getTeacherMaterialsStats(centerId)
          : _stats;

      if (mounted) {
        setState(() {
          if (reset) {
            _materials = materials;
          } else {
            _materials.addAll(materials);
          }
          _stats = stats;
          _currentPage += 1;
          _hasMore = materials.length == _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading materials: $e");
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: _error != null && !_isLoading
          ? _buildErrorWidget()
          : RefreshIndicator(
              onRefresh: () => _loadData(reset: true),
              color: AppColors.primary,
              backgroundColor: AppColors.darkCard,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                  SliverToBoxAdapter(child: _buildStatsHeader()),
                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                  SliverToBoxAdapter(child: _buildFilters()),
                  SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                  _buildMaterialsGrid(),
                  if (_isLoadingMore)
                    SliverToBoxAdapter(child: _buildLoadMoreIndicator()),
                  if (!_isLoading)
                    SliverToBoxAdapter(child: SizedBox(height: 80.h)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadOptions(context),
        backgroundColor: AppColors.primary,
        elevation: 0,
        icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
        label: const Text(
          'رفع جديد',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ).animate().scale(delay: 300.ms),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140.h,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.darkSurface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.oceanGradient),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 20.w, bottom: 16.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.library_books_rounded,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'المكتبة الرقمية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'إدارة المحتوى التعليمي',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.errorSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48.sp,
              color: AppColors.error,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'عذراً، حدث خطأ ما',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              _error ?? '',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textOnDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24.h),
          GradientButton(
            text: 'إعادة المحاولة',
            icon: Icons.refresh_rounded,
            onPressed: _loadData,
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildStatsHeader() {
    final total = _stats['total_materials'] ?? 0;
    final downloads = _stats['total_downloads'] ?? 0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: PremiumCard(
              padding: EdgeInsets.symmetric(vertical: 18.h),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.library_books_rounded,
                      color: const Color(0xFF0EA5E9),
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'المواد التعليمية',
                    style: TextStyle(
                      color: AppColors.textOnDarkSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: PremiumCard(
              padding: EdgeInsets.symmetric(vertical: 18.h),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_download_rounded,
                      color: AppColors.warning,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    '$downloads',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'إجمالي التحميلات',
                    style: TextStyle(
                      color: AppColors.textOnDarkSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildFilters() {
    final types = [
      {'id': 'all', 'label': 'الكل', 'icon': Icons.apps},
      {'id': 'pdf', 'label': 'PDF', 'icon': Icons.picture_as_pdf},
      {'id': 'video', 'label': 'فيديو', 'icon': Icons.videocam},
      {'id': 'image', 'label': 'صور', 'icon': Icons.image},
      {'id': 'link', 'label': 'روابط', 'icon': Icons.link},
    ];
    return SizedBox(
      height: 42.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (c, i) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final t = types[index];
          final isSelected = _selectedCategory == t['id'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = t['id']! as String);
              _loadData(reset: true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.darkCard,
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.darkBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    t['icon'] as IconData,
                    size: 16.sp,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textOnDarkSecondary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    t['label']! as String,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textOnDarkSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaterialsGrid() {
    if (_isLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: PremiumCard(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  'جاري التحميل...',
                  style: TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_materials.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(28.w),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 56.sp,
                  color: AppColors.textOnDarkHint,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'المكتبة فارغة',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'ابدأ برفع المحتوى التعليمي لطلابك',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textOnDarkHint,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final material = _materials[index];
          return SmartMaterialTile(
            material: material,
            onTap: () => _openMaterial(material),
            onMenuAction: (action) => _handleMenuAction(action, material),
          );
        }, childCount: _materials.length),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  void _showUploadOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UploadMaterialDialog(
        onUpload: (data) async {
          Navigator.pop(context);
          await _processUpload(data);
        },
      ),
    );
  }

  Future<void> _processUpload(Map<String, dynamic> data) async {
    setState(() => _isLoading = true);
    try {
      final centerProvider = context.read<CenterProvider>();
      final authProvider = context.read<AuthProvider>();
      final repository = context.read<SupabaseRepository>();

      final teacherId = authProvider.teacherProfile?.id;
      final centerId = centerProvider.currentCenterId;

      if (teacherId == null || centerId == null) {
        throw Exception('بيانات المعلم أو المركز مفقودة');
      }

      final fullData = {
        ...data,
        'teacher_id': teacherId,
        'center_id': centerId,
      };

      await repository.addStudyMaterial(fullData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم رفع المحتوى بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      debugPrint('Error uploading: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الرفع: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _openMaterial(Map<String, dynamic> material) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('فتح ${material['title']}')));
  }

  void _handleMenuAction(String action, Map<String, dynamic> material) {
    if (action == 'delete') {
      _deleteMaterial(material);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم اختيار $action')));
    }
  }

  Future<void> _deleteMaterial(Map<String, dynamic> material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkElevated,
        title: Text(
          'حذف المحتوى',
          style: TextStyle(color: AppColors.textOnDark),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${material['title']}"؟',
          style: TextStyle(color: AppColors.textOnDarkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(color: AppColors.textOnDarkSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = context.read<SupabaseRepository>();
        await repo.deleteStudyMaterial(material['id']);
        _loadData();
      } catch (e) {
        debugPrint('Delete error: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
      }
    }
  }
}
