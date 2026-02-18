import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';

enum MessageTone { error, info }

/// Displays error or info message with optional details
class MessageBanner extends StatelessWidget {
  const MessageBanner({
    required this.text,
    required this.tone,
    this.detail,
  });

  final String text;
  final String? detail;
  final MessageTone tone;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      MessageTone.error => const Color(errorColorLight),
      MessageTone.info => const Color(infoColorLight),
    };
    final foreground = switch (tone) {
      MessageTone.error => const Color(errorColorDark),
      MessageTone.info => const Color(infoColorDark),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tone == MessageTone.error ? Icons.error_outline : Icons.info_outline,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: foreground),
                ),
                if (detail != null && detail!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      detail!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: foreground.withOpacity(0.8)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays date selection button with custom label
class DateButton extends StatelessWidget {
  const DateButton({
    required this.label,
    required this.date,
    required this.onPressed,
  });

  final String label;
  final DateTime? date;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final text = date == null ? label : _formatDate(date!);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Displays a single info row in compact card view
class InfoRow extends StatelessWidget {
  const InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays summary statistic in a card
class SummaryTile extends StatelessWidget {
  const SummaryTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Background orb decorative element
class Orb extends StatelessWidget {
  const Orb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.35),
      ),
    );
  }
}

/// Expandable filter button that looks like an app icon
class FilterIconButton extends StatefulWidget {
  const FilterIconButton({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isExpanded;
  final VoidCallback onPressed;

  @override
  State<FilterIconButton> createState() => _FilterIconButtonState();
}

class _FilterIconButtonState extends State<FilterIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(FilterIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(primaryColorSeed);
    final backgroundColor = widget.isExpanded
        ? accentColor.withOpacity(0.15)
        : (_isHovering ? Colors.white : const Color(lightGray).withOpacity(0.3));
    const borderColor = Color(lightGray);
    final activeBorderColor = accentColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: SizedBox(
          height: 80,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(
                color:
                    widget.isExpanded ? activeBorderColor : borderColor,
                width: widget.isExpanded ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: _isHovering
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: _isHovering ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.icon,
                    color: widget.isExpanded ? accentColor : const Color(darkGray),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    widget.label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.isExpanded
                          ? accentColor
                          : const Color(darkGray),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

