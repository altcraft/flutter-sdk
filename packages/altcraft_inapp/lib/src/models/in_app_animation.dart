/// Easing curve used for the in-app view animation.
enum InAppAnimationEasing { linear, easeIn, easeOut, easeInOut }

/// Declarative animation of the in-app view.
///
/// The native SDK animates the real native view, so this model describes the
/// starting and target states of the view. A `null` value means the neutral
/// state: opacity `1`, offset `0`, scale `1`, rotation `0`. The view is
/// prepared with the `*From` values and animated to the `*To` values over
/// [duration] after [delay].
class InAppAnimation {
  /// Campaign identifier (native `companyId`) the animation is bound to.
  ///
  /// `null` makes the animation a fallback that applies to campaigns without
  /// a dedicated entry.
  final int? companyId;

  /// Start opacity. `null` means `1.0`.
  final double? alphaFrom;

  /// Target opacity. `null` means `1.0`.
  final double? alphaTo;

  /// Start horizontal offset in logical points (dp on Android, pt on iOS).
  final double? translateXFrom;

  /// Target horizontal offset in logical points.
  final double? translateXTo;

  /// Start vertical offset in logical points.
  final double? translateYFrom;

  /// Target vertical offset in logical points.
  final double? translateYTo;

  /// Start horizontal scale. `null` means `1.0`.
  final double? scaleXFrom;

  /// Target horizontal scale. `null` means `1.0`.
  final double? scaleXTo;

  /// Start vertical scale. `null` means `1.0`.
  final double? scaleYFrom;

  /// Target vertical scale. `null` means `1.0`.
  final double? scaleYTo;

  /// Start rotation in degrees. `null` means `0.0`.
  final double? rotationFrom;

  /// Target rotation in degrees. `null` means `0.0`.
  final double? rotationTo;

  /// Animation duration.
  final Duration duration;

  /// Delay before the animation starts.
  final Duration delay;

  /// Easing curve.
  final InAppAnimationEasing easing;

  /// Creates an in-app view animation description.
  const InAppAnimation({
    this.companyId,
    this.alphaFrom,
    this.alphaTo,
    this.translateXFrom,
    this.translateXTo,
    this.translateYFrom,
    this.translateYTo,
    this.scaleXFrom,
    this.scaleXTo,
    this.scaleYFrom,
    this.scaleYTo,
    this.rotationFrom,
    this.rotationTo,
    this.duration = const Duration(milliseconds: 350),
    this.delay = Duration.zero,
    this.easing = InAppAnimationEasing.easeInOut,
  });

  /// Serializes the animation into a platform-channel map.
  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'alphaFrom': alphaFrom,
      'alphaTo': alphaTo,
      'translateXFrom': translateXFrom,
      'translateXTo': translateXTo,
      'translateYFrom': translateYFrom,
      'translateYTo': translateYTo,
      'scaleXFrom': scaleXFrom,
      'scaleXTo': scaleXTo,
      'scaleYFrom': scaleYFrom,
      'scaleYTo': scaleYTo,
      'rotationFrom': rotationFrom,
      'rotationTo': rotationTo,
      'durationMs': duration.inMilliseconds,
      'delayMs': delay.inMilliseconds,
      'easing': easing.name,
    };
  }
}
