# UI Rules

- Keep widgets small and reusable.
- Extract reusable widgets.
- Avoid large build methods.
- Use const constructors whenever possible.
- Do not place business logic in widgets.
- Use AppColors constants instead of hardcoded color literals.
- Use AppSpacing constants instead of hardcoded spacing values.
- Use AppFontSizes constants instead of hardcoded font sizes.
- Use AppFontWeights constants instead of hardcoded font weights.
- Use AppBorderWidths constants instead of hardcoded border widths.
- Use AppRadius constants instead of hardcoded border radii.
- Use ThemeData for theming (dark/light), but reference AppColors tokens.

## Responsive layout

- Prefer flexible layouts (`Expanded`, `Flexible`, constraints) over fixed widths/heights for content.
- Use `AppResponsive` / `AppBreakpoints` for width tiers and adaptive padding; do not hardcode screen widths.
- Wrap page content with `AppConstrainedWidth` or `AppPageBody` so tablets get a centered max content width.
- Use `AppResponsive.pagePadding` / `scrollPadding` / `listPadding` instead of fixed `EdgeInsets.all(AppSpacing.space7)` for screen chrome.
- Titles and names: use `maxLines` + `TextOverflow.ellipsis` where overflow is possible.
- Money amounts: use `AppMoneyText` (scales down via `FittedBox`); do not use raw unfitted peso `Text` in narrow rows.
- Buttons must keep a minimum touch height of `AppSpacing.minTouchTarget` (48) / `space56`; labels may ellipsize, not overflow.
- Lists/cards must not require horizontal page scrolling (filter chip rows may scroll horizontally).
- Dialogs and bottom sheets must fit the viewport (scroll content; constrain sheet max height).
- Support large accessibility text by reflowing (stack columns) rather than shrinking body text globally.
- Respect safe areas for notches and system bars via shell/`SafeArea` patterns.
