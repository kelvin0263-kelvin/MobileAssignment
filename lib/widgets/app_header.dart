import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_utils.dart';

class AppHeader extends StatelessWidget {
  final String subtitle;
  final Widget? trailing;
  final Widget? bottom;

  const AppHeader({super.key, required this.subtitle, this.trailing, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary,
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Text(
                          authProvider.currentUser?.name ?? 'Mechanic Name',
                          style: AppTextStyles.headline2.copyWith(
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.body2.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: 16),
            bottom!,
          ],
        ],
      ),
    );
  }
}


