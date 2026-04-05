import re

with open('lib/features/teacher/assignments/teacher_assignments_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace GlassMorphismCard with StaggeredListAnimator wrapped GlassCard
content = re.sub(r'GlassMorphismCard\(', r'GlassCard(', content)
content = re.sub(r'animationDelay:\s*\d+\s*\*\s*index,', r'', content)
# Wait, let me replace GradientButton
content = re.sub(r'GradientButton\(', r'GeniusButton(', content)

# Theme to AppColors
content = re.sub(r'Theme\.of\(context\)\.cardTheme\.color \?\?[\s\n]*Theme\.of\(context\)\.colorScheme\.surface', r'AppColors.darkSurface', content)
content = re.sub(r'Theme\.of\(context\)\.colorScheme\.surface', r'AppColors.darkSurface', content)
content = re.sub(r'Theme\.of\(context\)\.colorScheme\.onSurface\.withOpacity\((.*?)\)', r'AppColors.textDisplay.withValues(alpha: \1)', content)
content = re.sub(r'Theme\.of\(context\)\.colorScheme\.onSurface', r'AppColors.textDisplay', content)
content = re.sub(r'Theme\.of\(context\)\.colorScheme\.outline\.withOpacity\((.*?)\)', r'AppColors.glassBorderHighlight', content)
content = re.sub(r'Theme\.of\(context\)\.colorScheme\.primary\.withValues\(alpha: (.*?)\)', r'AppColors.accentVivid.withValues(alpha: \1)', content)
content = re.sub(r'Theme\.of\(context\)\.colorScheme\.primary\.withOpacity\((.*?)\)', r'AppColors.accentVivid.withValues(alpha: \1)', content)
content = re.sub(r'Theme\.of\(context\)\.colorScheme\.primary', r'AppColors.accentVivid', content)
content = re.sub(r'Theme\.of\(context\)\.colorScheme\.secondary', r'AppColors.accentVivid', content)
content = re.sub(r'Theme\.of\(context\)\.colorScheme\.error\.withOpacity\((.*?)\)', r'AppColors.errorRed.withValues(alpha: \1)', content)
content = re.sub(r'Theme\.of\(context\)\.colorScheme\.error', r'AppColors.errorRed', content)

# withOpacity to withValues
content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', content)

# TextField to GeniusTextField
content = re.sub(r'TextField\(', r'GeniusTextField(', content)

with open('lib/features/teacher/assignments/teacher_assignments_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
