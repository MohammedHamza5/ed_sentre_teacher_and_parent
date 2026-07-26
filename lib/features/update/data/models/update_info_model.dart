/// Model representing version details from Supabase app_versions table
class UpdateInfoModel {
  final String version;
  final String platform;
  final bool isMandatory;
  final String downloadUrl;
  final String? checksum;
  final int fileSize;
  final String? changelogAr;
  final String? changelogEn;
  final bool isPatch;

  const UpdateInfoModel({
    required this.version,
    required this.platform,
    required this.isMandatory,
    required this.downloadUrl,
    this.checksum,
    required this.fileSize,
    this.changelogAr,
    this.changelogEn,
    this.isPatch = false,
  });

  factory UpdateInfoModel.fromJson(Map<String, dynamic> json) {
    return UpdateInfoModel(
      version: json['version'] as String? ?? '1.0.0',
      platform: json['platform'] as String? ?? 'android',
      isMandatory: json['is_mandatory'] as bool? ?? false,
      downloadUrl: json['download_url'] as String? ?? '',
      checksum: json['checksum'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      changelogAr: json['changelog_ar'] as String?,
      changelogEn: json['changelog_en'] as String?,
      isPatch: json['is_patch'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'platform': platform,
      'is_mandatory': isMandatory,
      'download_url': downloadUrl,
      'checksum': checksum,
      'file_size': fileSize,
      'changelog_ar': changelogAr,
      'changelog_en': changelogEn,
      'is_patch': isPatch,
    };
  }
}
