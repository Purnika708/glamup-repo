import 'package:flutter/material.dart';

class SharedHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool expandable;
  final Widget? background;
  final VoidCallback? onRefresh;
  final bool showBackButton;
  
  const SharedHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.actions,
    this.expandable = false,
    this.background,
    this.onRefresh,
    this.showBackButton = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandable ? 120 : null,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      leading: showBackButton 
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          )
        : null,
      flexibleSpace: expandable 
        ? FlexibleSpaceBar(
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 22,
              ),
            ),
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            centerTitle: false,
            background: background ?? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Colors.pink.shade300,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: subtitle != null 
                ? Align(
                    alignment: const Alignment(0, -0.2),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  )
                : null,
            ),
          )
        : null,
      title: !expandable ? Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ) : null,
      centerTitle: !expandable,
      actions: actions != null 
        ? [...actions!] 
        : onRefresh != null
          ? [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: onRefresh,
              ),
            ]
          : null,
    );
  }
}