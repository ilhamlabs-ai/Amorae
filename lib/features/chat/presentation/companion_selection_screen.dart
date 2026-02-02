import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/firestore_service.dart';

class CompanionSelectionScreen extends ConsumerStatefulWidget {
  const CompanionSelectionScreen({super.key});

  @override
  ConsumerState<CompanionSelectionScreen> createState() =>
      _CompanionSelectionScreenState();
}

class _CompanionSelectionScreenState
    extends ConsumerState<CompanionSelectionScreen> {
  String? _selectedPersona;
  String? _customName;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _companionTypes = [
    {
      'persona': 'girlfriend',
      'title': 'Girlfriend',
      'subtitle': 'Romantic, caring, and affectionate companion',
      'icon': Icons.favorite,
      'color': Colors.pink,
      'defaultName': 'Luna',
    },
    {
      'persona': 'boyfriend',
      'title': 'Boyfriend',
      'subtitle': 'Supportive, charming, and understanding partner',
      'icon': Icons.favorite,
      'color': Colors.blue,
      'defaultName': 'Jack',
    },
    {
      'persona': 'friend',
      'title': 'Friend',
      'subtitle': 'Fun, reliable, and always there for you',
      'icon': Icons.people,
      'color': Colors.green,
      'defaultName': 'Alex',
    },
  ];

  Future<void> _selectCompanion() async {
    if (_selectedPersona == null) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      // Show custom name dialog
      final defaultName = _companionTypes
          .firstWhere((c) => c['persona'] == _selectedPersona)['defaultName'];

      final customName = await _showCustomNameDialog(defaultName);
      if (customName == null || !mounted) {
        setState(() => _isLoading = false);
        return;
      }

      // Create the companion thread
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createThread(
        userId: user.id,
        selectedPersona: _selectedPersona!,
        customPersonaName: customName,
      );

      if (mounted) {
        context.go('/chat');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating companion: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _showCustomNameDialog(String defaultName) async {
    final controller = TextEditingController(text: defaultName);

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Name Your Companion',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Give your companion a name',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter a name',
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              Navigator.of(context).pop(name.isEmpty ? defaultName : name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Continue',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Choose Your Companion',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select the type of companion you\'d like',
                      style: AppTextStyles.h3
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can only have one companion in single companion mode',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _companionTypes.length,
                        itemBuilder: (context, index) {
                          final companion = _companionTypes[index];
                          final isSelected =
                              _selectedPersona == companion['persona'];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: InkWell(
                              onTap: () => setState(
                                  () => _selectedPersona = companion['persona']),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? companion['color']
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: companion['color']
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        companion['icon'],
                                        color: companion['color'],
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            companion['title'],
                                            style: AppTextStyles.h3.copyWith(
                                                color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            companion['subtitle'],
                                            style: AppTextStyles.body.copyWith(
                                                color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: companion['color'],
                                        size: 28,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedPersona != null ? _selectCompanion : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.textSecondary.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: AppTextStyles.h3.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
