import 'dart:io';

void main() {
  final studentBase = r'c:\Users\KimoStore\StudioProjects\ed_sentre_system\ed_sentre_student';
  final teacherBase = r'c:\Users\KimoStore\StudioProjects\ed_sentre_system\ed_sentre_techer_and_parent';

  // Copy launcher icons for all densities
  final sizes = ['mipmap-mdpi', 'mipmap-hdpi', 'mipmap-xhdpi', 'mipmap-xxhdpi', 'mipmap-xxxhdpi'];
  for (final size in sizes) {
    final src = '$studentBase\\android\\app\\src\\main\\res\\$size\\ic_launcher.png';
    final dst = '$teacherBase\\android\\app\\src\\main\\res\\$size\\ic_launcher.png';
    try {
      File(src).copySync(dst);
      print('✅ Copied $size/ic_launcher.png');
    } catch (e) {
      print('❌ Failed $size: $e');
    }
  }

  // Copy app_icon.png to assets
  final logoSrc = '$studentBase\\assets\\icons\\app_icon.png';
  final logoDst = '$teacherBase\\assets\\icons\\app_icon.png';
  try {
    File(logoSrc).copySync(logoDst);
    print('✅ Copied app_icon.png to assets/icons/');
  } catch (e) {
    print('❌ Failed app_icon.png: $e');
  }

  print('\n🎉 Done!');
}
