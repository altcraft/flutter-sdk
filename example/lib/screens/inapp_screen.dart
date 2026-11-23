import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:altcraft_inapp/altcraft_inapp.dart';
import 'package:altcraft_sdk_example/services/app_state.dart';

const _kLine = Color(0xFFE0E0E0);

/// In-App demonstration screen.
///
/// Replicates the Android Jetpack Compose InAppScreen layout:
/// - Altcraft header
/// - Three equally sized rows
/// - Two centered cells per row
/// - Vertical and horizontal dividers
/// - Placement counter badge
/// - In-App trigger buttons
class InAppScreen extends StatefulWidget {
  const InAppScreen({super.key});

  @override
  State<InAppScreen> createState() => _InAppScreenState();
}

class _InAppScreenState extends State<InAppScreen> {
  @override
  void initState() {
    super.initState();

    // Subscribe to application state changes.
    AppState.instance.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    // Remove the listener when this screen is destroyed.
    AppState.instance.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Creates the complete In-App screen.
  ///
  /// The content uses Expanded to distribute the three rows
  /// equally, matching Compose's Modifier.weight(1f).
  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Altcraft application header.
          _header(),

          // Main In-App content grid.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  // Row 1: Placements and Modal.
                  _row(
                    _placementCell(
                      state.placementCount,
                      semanticsIdentifier: 'inapp_placements_button',
                    ),
                    _triggerCell(
                      title: 'Modal',
                      icon: 'assets/ic_in_app_center.png',
                      trigger: 'tr_modal',
                      semanticsIdentifier: 'inapp_modal_button',
                    ),
                  ),

                  _horizontalDivider(),

                  // Row 2: Fullscreen and Floating Bar.
                  _row(
                    _triggerCell(
                      title: 'Fullscreen',
                      icon: 'assets/ic_in_app_fullscreen.png',
                      trigger: 'tr_fullscreen',
                      semanticsIdentifier: 'inapp_fullscreen_button',
                    ),
                    _triggerCell(
                      title: 'Floating Bar',
                      icon: 'assets/ic_in_app_down.png',
                      trigger: 'tr_floating_bar',
                      semanticsIdentifier: 'inapp_floating_bar_button',
                    ),
                  ),

                  _horizontalDivider(),

                  // Row 3: SlideUp and Custom.
                  _row(
                    _triggerCell(
                      title: 'SlideUp',
                      icon: 'assets/ic_in_app_top.png',
                      trigger: 'tr_slide_up',
                      semanticsIdentifier: 'inapp_slide_up_button',
                    ),
                    _triggerCell(
                      title: 'Custom',
                      icon: 'assets/ic_in_app_custom.png',
                      trigger: 'tr_custom',
                      semanticsIdentifier: 'inapp_custom_button',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Creates the Altcraft header.
  ///
  /// Corresponds to HeaderSection() in Android Compose.
  Widget _header() {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 16),
      child: Image.asset(
        'assets/ic_altcraft.png',
        width: 80,
        height: 20,
        fit: BoxFit.contain,
      ),
    );
  }

  /// Creates one row containing two equally sized cells.
  ///
  /// Android Compose equivalent:
  /// Row(Modifier.weight(1f)) {
  ///     Cell(Modifier.weight(1f))
  ///     VerticalDivider()
  ///     Cell(Modifier.weight(1f))
  /// }
  Widget _row(Widget first, Widget second) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: first,
          ),
          _verticalDivider(),
          Expanded(
            child: second,
          ),
        ],
      ),
    );
  }

  /// Creates the vertical divider between two cells.
  ///
  /// Matches Android Compose:
  /// width = 2dp
  /// vertical padding = 15dp
  Widget _verticalDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
      ),
      child: Container(
        width: 2,
        color: _kLine,
      ),
    );
  }

  /// Creates the interrupted horizontal divider.
  ///
  /// Android Compose uses two horizontal lines with
  /// an empty 60dp segment in the center.
  ///
  /// The entire divider has 15dp horizontal padding.
  Widget _horizontalDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      child: SizedBox(
        height: 2,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 2,
                color: _kLine,
              ),
            ),
            const SizedBox(width: 60),
            Expanded(
              child: Container(
                height: 2,
                color: _kLine,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates the Placements cell.
  ///
  /// Corresponds to PlacementCell() in Android Compose.
  ///
  /// Shows:
  /// - Placements title
  /// - Download image
  /// - Count badge when placements are available
  /// - Load placements description
  Widget _placementCell(
    int count, {
    required String semanticsIdentifier,
  }) {
    return _cellContent(
      title: 'Placements',
      description: 'Load placements',
      imageBuilder: (iconSize) {
        return Semantics(
          identifier: semanticsIdentifier,
          button: true,
          label: 'Placements',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              await AltcraftInApp.getPlacements();
            },
            child: SizedBox(
              width: iconSize,
              height: iconSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Placement download icon.
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/ic_in_app_download.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Placement count badge.
                  if (count > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _countBadge(count),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Creates a trigger cell.
  ///
  /// Corresponds to InAppIconCell() in Android Compose.
  ///
  /// The trigger name and icon are passed by the parent row.
  Widget _triggerCell({
    required String title,
    required String icon,
    required String trigger,
    required String semanticsIdentifier,
  }) {
    return _cellContent(
      title: title,
      description: trigger,
      imageBuilder: (iconSize) {
        return Semantics(
          identifier: semanticsIdentifier,
          button: true,
          label: title,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              await AltcraftInApp.trigger(trigger);
            },
            child: SizedBox(
              width: iconSize,
              height: iconSize,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  icon,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the common visual structure for all grid cells.
  ///
  /// Android Compose centers each cell using:
  /// Box(contentAlignment = Alignment.Center)
  /// Column(
  ///     horizontalAlignment = Alignment.CenterHorizontally,
  ///     verticalArrangement = Arrangement.Center
  /// )
  ///
  /// LayoutBuilder reduces the icon size on smaller screens
  /// while preserving the original 120dp maximum.
  Widget _cellContent({
    required String title,
    required String description,
    required Widget Function(double iconSize) imageBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Available width for the image inside this cell.
        final availableWidth = math.max(
          0.0,
          constraints.maxWidth - 16,
        );

        // Reserve space for the title, description and spacing.
        final availableHeight = math.max(
          0.0,
          constraints.maxHeight - 72,
        );

        // Android Compose uses 120dp images.
        final iconSize = math.min(
          120.0,
          math.min(
            availableWidth,
            availableHeight,
          ),
        );

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cell title.
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 12),

              // Clickable image or placement icon.
              imageBuilder(iconSize),

              const SizedBox(height: 12),

              // Trigger identifier or placement description.
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Creates a placement count badge.
  ///
  /// Matches Compose CountBadge:
  /// - 20dp outer white circle
  /// - 18dp inner black circle
  /// - 10sp bold white counter
  Widget _countBadge(int count) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            count.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
