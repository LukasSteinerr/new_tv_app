import 'package:flutter/material.dart';

class TimeSlider extends StatefulWidget {
  final TimeOfDay selectedTime;
  final bool showBumpOut;
  final double availableHeight;
  final ValueChanged<TimeOfDay> onTimeChange;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  const TimeSlider({
    super.key,
    required this.selectedTime,
    required this.showBumpOut,
    required this.availableHeight,
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
    final double dynamicHourHeight = widget.availableHeight / 24;
    final List<int> displayHoursOrder = List.generate(24, (i) => (i + 5) % 24);
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
      width: 50,
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
                        width: 50,
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
                                  (hourValue == widget.selectedTime.hour)
                                      ? Colors.white
                                      : Colors.white70,
                              fontWeight:
                                  (hourValue == widget.selectedTime.hour)
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
                widget.availableHeight - indicatorHeight,
              ),
              left: -75,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                height: indicatorHeight,
                decoration: BoxDecoration(
                  color: Colors.blue.shade800,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
                    const Icon(Icons.more_horiz, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
