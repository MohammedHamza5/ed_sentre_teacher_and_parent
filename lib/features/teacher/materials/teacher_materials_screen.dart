import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/providers/center_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../core/widgets/genius/glass_card.dart';
import 'widgets/smart_material_tile.dart';
import 'widgets/upload_material_dialog.dart';

/// 🎨 Teacher Materials Screen - Forest Dark Edition
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
      backgroundColor: AppColors.forestDeep,
      body: _error != null && !_isLoading
          ? _buildErrorWidget()
          : RefreshIndicator(
              onRefresh: () => _loadData(reset: true),
              backgroundColor: AppColors.accentVivid,
              color: AppColors.darkSurface,
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
                    SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadOptions(context),
        backgroundColor: AppColors.accentVivid,
        elevation: 0,
        icon: const Icon(
          Icons.cloud_upload_rounded,
          color: AppColors.forestDeep,
        ),
        label: const Text(
          'رفع جديد',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.forestDeep,
          ),
        ),
      ).animate().scale(delay: 300.ms),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.h,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.forestPrimary,
      iconTheme: const IconThemeData(color: AppColors.textDisplay),
      title: Text(
        'المكتبة الرقمية',
        style: TextStyle(
          color: AppColors.textDisplay,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned(
              right: -50.w,
              top: -50.h,
              child: Container(
                width: 200.w,
                height: 200.w,
                decoration: BoxDecoration(
                  color: AppColors.accentVivid.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -30.w,
              bottom: -20.h,
              child: Container(
                width: 150.w,
                height: 150.w,
                decoration: BoxDecoration(
                  color: AppColors.infoPurple.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                ).copyWith(bottom: 20.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.accentVivid.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppColors.accentVivid.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.video_library_rounded,
                            color: AppColors.accentVivid,
                            size: 28.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'محتواك التعليمي',
                                style: TextStyle(
                                  color: AppColors.textDisplay,
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'إدارة الملفات والمرفقات',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: AppColors.textDisplay),
          onPressed: () {},
        ),
        Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: const SizedBox.shrink(),
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
              color: AppColors.forestPrimary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorderHighlight),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 56.sp,
              color: AppColors.errorRed,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          SizedBox(height: 24.h),
          Text(
            'عذراً، حدث خطأ ما',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textDisplay,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              _error ?? '',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
          ),
          SizedBox(height: 32.h),
          ElevatedButton.icon(
            onPressed: () => _loadData(reset: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'إعادة المحاولة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentVivid,
              foregroundColor: AppColors.forestDeep,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final total = _stats['total_materials'] ?? 0;
    final downloads = _stats['total_downloads'] ?? 0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              color: AppColors.forestPrimary,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.infoPurple.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.infoPurple.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.library_books_rounded,
                      color: AppColors.infoPurple,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDisplay,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'المواد التعليمية',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: GlassCard(
              color: AppColors.forestPrimary,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.warmAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.warmAmber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.cloud_download_rounded,
                      color: AppColors.warmAmber,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '$downloads',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDisplay,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'إجمالي التحميلات',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.sp,
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
      {'id': 'all', 'label': 'الكل', 'icon': Icons.apps_rounded},
      {'id': 'pdf', 'label': 'PDF', 'icon': Icons.picture_as_pdf_rounded},
      {'id': 'video', 'label': 'فيديو', 'icon': Icons.videocam_rounded},
      {'id': 'image', 'label': 'صور', 'icon': Icons.image_rounded},
      {'id': 'link', 'label': 'روابط', 'icon': Icons.link_rounded},
    ];
    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                color: isSelected
                    ? AppColors.accentVivid.withValues(alpha: 0.15)
                    : AppColors.darkSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentVivid
                      : AppColors.glassBorderHighlight,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    t['icon'] as IconData,
                    size: 18.sp,
                    color: isSelected
                        ? AppColors.accentVivid
                        : AppColors.textMuted,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    t['label']! as String,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.accentVivid
                          : AppColors.textDisplay,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      fontSize: 13.sp,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                backgroundColor: AppColors.accentVivid,
              ),
              SizedBox(height: 16.h),
              Text(
                'جاري التحميل...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
              ),
            ],
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
                  color: AppColors.forestPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.glassBorderHighlight),
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 56.sp,
                  color: AppColors.infoPurple,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'المكتبة فارغة',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDisplay,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'ابدأ برفع المحتوى التعليمي لطلابك',
                style: TextStyle(fontSize: 14.sp, color: AppColors.textMuted),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
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
      child: Center(
        child: CircularProgressIndicator(
          backgroundColor: AppColors.accentVivid,
        ),
      ),
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
          const SnackBar(
            content: Text(
              'تم رفع المحتوى بنجاح',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.emeraldGreen,
          ),
        );
        _loadData(reset: true);
      }
    } catch (e) {
      debugPrint('Error uploading: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل الرفع: $e',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.errorRed,
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
        backgroundColor: AppColors.forestPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'حذف المحتوى',
          style: TextStyle(
            color: AppColors.textDisplay,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${material['title']}"؟',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text(
              'حذف',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = context.read<SupabaseRepository>();
        await repo.deleteStudyMaterial(material['id']);
        _loadData(reset: true);
      } catch (e) {
        debugPrint('Delete error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل الحذف: $e'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }
}
