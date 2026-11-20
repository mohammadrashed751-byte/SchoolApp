import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

/// Shared shell for every auth screen (login + all register forms): a
/// plain background, a back button when the route can be popped, a bold
/// title + muted subtitle, then the caller's form — matching the flat
/// reference design (no colored hero panel). Replaces the earlier
/// hero-panel `AuthScaffold`.
///
/// Wraps everything in [SafeArea] + [SingleChildScrollView] (with
/// `resizeToAvoidBottomInset` left at its default `true`) so opening the
/// keyboard scrolls the focused field into view instead of overflowing.
class FlatAuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget form;

  const FlatAuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: responsiveWidth(context, 28)).copyWith(
              top: responsiveHeight(context, 20),
              bottom: responsiveHeight(context, 32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (Navigator.canPop(context))
                  IconButton(
                    key: const Key('authBackButton'),
                    onPressed: () => Navigator.of(context).maybePop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: responsiveWidth(context, 26),
                    icon: const Icon(Icons.arrow_back),
                  ),
                SizedBox(height: responsiveHeight(context, 28)),
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
                SizedBox(height: responsiveHeight(context, 12)),
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                SizedBox(height: responsiveHeight(context, 36)),
                form,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
