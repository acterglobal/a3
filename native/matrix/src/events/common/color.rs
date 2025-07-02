/// ARGB int representation of a color as used in dart::ui
/// The bits are interpreted as follows:
///     Bits 24-31 are the alpha value.
///     Bits 16-23 are the red value.
///     Bits 8-15 are the green value.
///     Bits 0-7 are the blue value.
///
/// In other words, if AA is the alpha value in hex, RR the red value in hex, GG the green value in hex, and BB the blue value in hex, a color can be expressed as 0xAARRGGBB.
//
/// For example, to get a fully opaque orange, you would use 0xFFFF9000 (FF for the alpha, FF for the red, 90 for the green, and 00 for the blue).
pub type Color = u32;
