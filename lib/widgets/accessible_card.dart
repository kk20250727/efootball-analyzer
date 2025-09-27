import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// アクセシビリティ対応の改善されたCardウィジェット
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String? semanticLabel;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const AccessibleCard({
    super.key,
    required this.child,
    this.semanticLabel,
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      margin: margin,
      color: backgroundColor,
      child: Padding(
        padding: padding!,
        child: child,
      ),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    if (semanticLabel != null) {
      card = Semantics(
        label: semanticLabel!,
        child: card,
      );
    }

    return card;
  }
}

/// プログレス表示ウィジェット
class ProgressIndicatorWidget extends StatelessWidget {
  final double progress;
  final String label;
  final bool isVisible;

  const ProgressIndicatorWidget({
    super.key,
    required this.progress,
    required this.label,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: AppTheme.cyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: '$label: ${(progress * 100).toInt()}%完了',
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.darkGray,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.cyan),
          ),
        ),
      ],
    );
  }
}

/// レスポンシブグリッドウィジェット
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final responsiveColumns = isTablet ? crossAxisCount + 1 : crossAxisCount;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: responsiveColumns,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      children: children,
    );
  }
}

/// アクセシブルなステータスメッセージウィジェット
class StatusMessage extends StatelessWidget {
  final String message;
  final MessageType type;
  final IconData? icon;

  const StatusMessage({
    super.key,
    required this.message,
    this.type = MessageType.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData defaultIcon;

    switch (type) {
      case MessageType.success:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green.shade300;
        defaultIcon = Icons.check_circle;
        break;
      case MessageType.error:
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red.shade300;
        defaultIcon = Icons.error;
        break;
      case MessageType.warning:
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange.shade300;
        defaultIcon = Icons.warning;
        break;
      case MessageType.info:
      default:
        backgroundColor = AppTheme.darkGray.withOpacity(0.5);
        textColor = AppTheme.cyan;
        defaultIcon = Icons.info;
        break;
    }

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: textColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon ?? defaultIcon,
              color: textColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum MessageType {
  info,
  success,
  warning,
  error,
}

/// アクセシブルなボタンウィジェット
class AccessibleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final ButtonType type;
  final Size? minimumSize;
  final EdgeInsetsGeometry? padding;

  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.type = ButtonType.primary,
    this.minimumSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;

    switch (type) {
      case ButtonType.primary:
        button = ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: minimumSize ?? const Size(double.infinity, 48),
            padding: padding,
          ),
          child: child,
        );
        break;
      case ButtonType.secondary:
        button = OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: minimumSize ?? const Size(double.infinity, 48),
            padding: padding,
          ),
          child: child,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: minimumSize ?? const Size(double.infinity, 48),
            padding: padding,
          ),
          child: child,
        );
        break;
    }

    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel!,
        button: true,
        child: button,
      );
    }

    return button;
  }
}

enum ButtonType {
  primary,
  secondary,
  text,
}
