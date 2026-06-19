import 'package:flutter/material.dart';
import '../../models/lodging.dart';
import '../../utils/constants.dart';

/// Collapsible tab that appears in the bottom-right corner of MonitorView
/// when a red alert (alarm) is active, showing nearby lodging options.
class LodgingTab extends StatefulWidget {
  const LodgingTab({super.key});

  @override
  State<LodgingTab> createState() => _LodgingTabState();
}

class _LodgingTabState extends State<LodgingTab>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Expanded panel ──
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: 1.0,
          child: Container(
            width: 260,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Constants.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Constants.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'HOSPEDAJE CERCANO',
                  style: TextStyle(
                    color: Constants.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Descansa antes de continuar',
                  style: TextStyle(
                    color: Constants.textTertiary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 12),
                ...Lodging.nearbyDefaults.map(_buildLodgingItem),
              ],
            ),
          ),
        ),

        // ── Collapsed tab button ──
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _expanded
                  ? Constants.accent
                  : Constants.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _expanded
                    ? Constants.accent
                    : Constants.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expanded ? Icons.close : Icons.hotel,
                  size: 16,
                  color: _expanded
                      ? Colors.white
                      : Constants.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  _expanded ? 'Cerrar' : 'Hospedaje',
                  style: TextStyle(
                    color: _expanded
                        ? Colors.white
                        : Constants.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLodgingItem(Lodging lodging) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Constants.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.hotel,
              size: 18,
              color: Constants.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lodging.name,
                  style: const TextStyle(
                    color: Constants.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      lodging.distance,
                      style: const TextStyle(
                        color: Constants.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.star,
                      size: 10,
                      color: Constants.warningColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      lodging.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Constants.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  lodging.address,
                  style: const TextStyle(
                    color: Constants.textTertiary,
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
