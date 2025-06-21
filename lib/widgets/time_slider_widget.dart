import 'dart:math';

import 'package:flutter/material.dart';

// Import for kDebugMode if needed later

class TimeSlider extends StatefulWidget {
  final TimeOfDay selectedTime;
  final TimeOfDay currentTime;
  final bool showBumpOut;
  // final double availableHeight; // Removed
  final ValueChanged<TimeOfDay> onTimeChange;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  const TimeSlider({
    super.key,
    required this.selectedTime,
    required this.currentTime,
    required this.showBumpOut,
    // required this.availableHeight, // Removed
    required this.onTimeChange,
    this.onInteractionStart,
    this.onInteractionEnd,
  });

  @override
  State<TimeSlider> createState() => _TimeSliderState();
}

class _TimeSliderState extends State<TimeSlider> {
  bool _isInteracting = false;

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get actual constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure we have a valid height constraint
        if (!constraints.hasBoundedHeight || constraints.maxHeight.isInfinite) {
          return const Center(
            child: Text(
              'Slider requires bounded height',
              style: TextStyle(color: Colors.red),
            ),
          ); // Or some other placeholder/error widget
        }

        final double actualAvailableHeight = constraints.maxHeight;
        final double dynamicHourHeight = actualAvailableHeight / 24;

        // Prevent division by zero or negative height if constraints are weird
        if (dynamicHourHeight <= 0) {
          return const SizedBox.shrink(); // Or handle error appropriately
        }

        final List<int> displayHoursOrder = List.generate(
          24,
          (i) => (i + 5) % 24,
        );
        int selectedHourVisualIndex = displayHoursOrder.indexOf(
          widget.selectedTime.hour,
        );
        if (selectedHourVisualIndex == -1) {
          selectedHourVisualIndex = 0; // Fallback
        }

        final double indicatorHeight = 36.0;
        final double topOffsetForIndicator =
            (selectedHourVisualIndex * dynamicHourHeight) +
            (dynamicHourHeight / 2) -
            (indicatorHeight / 2);

        return SizedBox(
          width: 45, // Slightly wider width for the slider column
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: GestureDetector(
                    onVerticalDragStart: (_) {
                      setState(() {
                        _isInteracting = true;
                      });
                      widget.onInteractionStart?.call();
                    },
                    onVerticalDragUpdate: (DragUpdateDetails details) {
                      widget.onInteractionStart?.call();
                      int touchedIndex = (details.localPosition.dy /
                              dynamicHourHeight)
                          .floor()
                          .clamp(0, 23);
                      int newSelectedHour = displayHoursOrder[touchedIndex];
                      if (newSelectedHour != widget.selectedTime.hour) {
                        widget.onTimeChange(
                          TimeOfDay(
                            hour: newSelectedHour,
                            minute: widget.selectedTime.minute,
                          ),
                        );
                      }
                    },
                    onVerticalDragEnd: (_) {
                      setState(() {
                        _isInteracting = false;
                      });
                      widget.onInteractionEnd?.call();
                    },
                    onVerticalDragCancel: () {
                      setState(() {
                        _isInteracting = false;
                      });
                      widget.onInteractionEnd?.call();
                    },
                    onTapDown: (TapDownDetails details) {
                      setState(() {
                        _isInteracting = true;
                      });
                      widget.onInteractionStart?.call();
                      int touchedIndex = (details.localPosition.dy /
                              dynamicHourHeight)
                          .floor()
                          .clamp(0, 23);
                      int newSelectedHour = displayHoursOrder[touchedIndex];
                      if (newSelectedHour != widget.selectedTime.hour) {
                        widget.onTimeChange(
                          TimeOfDay(
                            hour: newSelectedHour,
                            minute: widget.selectedTime.minute,
                          ),
                        );
                      }
                    },
                    onTapUp: (_) {
                      setState(() {
                        _isInteracting = false;
                      });
                      widget.onInteractionEnd?.call();
                    },
                    onTapCancel: () {
                      setState(() {
                        _isInteracting = false;
                      });
                      widget.onInteractionEnd?.call();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        for (var hourValue in displayHoursOrder)
                          SizedBox(
                            height: dynamicHourHeight,
                            width: 45, // Match the slightly wider width here
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    (hourValue == widget.selectedTime.hour)
                                        ? Colors.blueAccent.withOpacity(0.3)
                                        : Colors.transparent,
                              ),
                              child: Text(
                                hourValue.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  color:
                                      (hourValue == widget.currentTime.hour)
                                          ? Colors.blueAccent
                                          : (hourValue ==
                                              widget.selectedTime.hour)
                                          ? Colors.white
                                          : Colors.white70,
                                  fontWeight:
                                      (hourValue == widget.selectedTime.hour ||
                                              hourValue ==
                                                  widget.currentTime.hour)
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.showBumpOut && _isInteracting)
                Positioned(
                  top: topOffsetForIndicator.clamp(
                    0.0,
                    actualAvailableHeight -
                        indicatorHeight, // Use actual height
                  ),
                  left: -100, // Move bump-out further left
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, // Increased horizontal padding
                      vertical: 6,
                    ),
                    height: indicatorHeight,
                    width: 120, // Fixed width for consistent sizing
                    decoration: BoxDecoration(
                      color: Colors.blue.shade800,
                      borderRadius: BorderRadius.circular(4), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6, // Softer shadow
                          offset: const Offset(0, 3), // More pronounced shadow
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "KI ${widget.selectedTime.hour.toString().padLeft(2, '0')}:00",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.more_horiz,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
