# Illish — UI Philosophy & Design Guidelines

This document serves as the master blueprint for the app's visual identity, interaction design, and UI philosophy, derived strictly from the current state of the `illish` codebase.

Future agents and developers MUST consult this file before introducing new UI elements, screens, or animations.

---

## 1. Overall UI Philosophy & Tone

- **High-End Fintech Meets Food Magazine:** The app should feel premium, minimalist, and deeply utilitarian. It is NOT a whimsical or cluttered social app.
- **Dark Mode First (and Only):** The app operates in a pure black (`#000000`) environment. This saves battery in high-brightness outdoor scenarios (like a sunny wet market) and creates a sleek, high-contrast aesthetic.
- **Visual Restraint:** Let typography and negative space do the heavy lifting. Avoid unnecessary borders, dividers, or generic drop shadows.
- **Action-Oriented:** The user is likely holding a bag in one hand. Actions must be massive, obvious, and reachable via bottom sheets or bottom-anchored buttons.

---

## 2. Color Palette & Usage

Do not introduce new random hex codes. Stick to the predefined `AppTheme` colors:
- **Background:** `Colors.black` (Pure black).
- **Cards/Overlays:** `Color(0xFF1A1A1A)` or `Colors.white.withOpacity(0.05)` to `0.15` for frosted glass.
- **Text:** `Colors.white` for primary, `Colors.white54` or `Colors.white70` for secondary/tertiary.
- **Accents:**
  - `neonCyan` (`#00F0FF`): Used for primary actions, glowing effects, and brand identity.
  - `emeraldGreen` (`#00E676`): Used STRICTLY for positive freshness status or success states.
  - `amber` (`#FFB300`): Used STRICTLY for warnings or medium freshness.
  - `crimsonRed` (`#FF3B30`): Used STRICTLY for errors, poor freshness, or destructive actions.

---

## 3. Typography & Hierarchy

- **Font Family:** `GoogleFonts.inter()` is the standard.
- **Hierarchy:**
  - **Massive Headers:** `fontSize: 32` to `48`, `fontWeight: FontWeight.w900`, tight letter spacing (`-1.0` to `-1.5`).
  - **Section Titles:** `fontSize: 18` to `20`, `fontWeight: FontWeight.bold`.
  - **Body Text:** `fontSize: 14` to `15`, `color: Colors.white70`, `height: 1.5` for readability.
  - **Micro-copy:** `fontSize: 12`, `color: Colors.white54`.

---

## 4. Component Patterns

### Buttons
- **Shape:** Pill-shaped (`BorderRadius.circular(100)`). Do not use square or slightly rounded buttons for primary actions.
- **Primary CTA:** Filled with `AppTheme.neonCyan`, text color `Colors.black`, bold text.
- **Secondary Actions:** Blurred frosted glass (`Colors.white.withOpacity(0.15)`) with a thin border.
- **Icons:** Use modern, outlined icons (e.g., `CupertinoIcons` or `Icons.XYZ_outlined`).

### Cards & Sheets
- **Border Radius:** `BorderRadius.circular(24)` or `32` for bottom sheets. `16` to `24` for internal cards.
- **Borders:** Thin, subtle borders are preferred over heavy shadows in dark mode (e.g., `Border.all(color: Colors.white.withOpacity(0.08))`).
- **Glassmorphism:** Heavily used. Wrap containers in `ClipRRect` -> `BackdropFilter(ImageFilter.blur(sigmaX: 10, sigmaY: 10))` -> `Container(color: Colors.white.withOpacity(0.1))`.

### Hit Testing (CRITICAL)
- **Ghost Touches:** Since many containers use transparency or have empty padding, `GestureDetector` will fail to register taps unless `behavior: HitTestBehavior.opaque` is explicitly set. ALWAYS use this for interactive cards, custom buttons, or dismiss handlers.

---

## 5. Motion & Animation Philosophy

- **Subtle & Purposeful:** Animations should communicate state changes, not just look flashy.
- **Transitions:** Prefer smooth slide animations (e.g., bottom sheets sliding up) over jarring fade transitions.
- **Micro-interactions:** Scale animations on button press (`Transform.scale`) are encouraged.
- **Performance Constraints (Jank Avoidance):**
  - **DO NOT** animate vector blurs (`MaskFilter.blur`) at 60fps on a `CustomPaint` canvas (like we saw in the original `FreshnessRingPainter`). It causes severe jank on physical devices.
  - If a glowing effect needs to animate, use standard `BoxShadow` on an underlying `Container` or animate the `opacity` of a static blurred asset, letting the Flutter engine cache it properly.

---

## 6. What Should Never Be Changed Casually

- **The Main Camera Viewfinder:** Must remain instantly accessible with zero delay.
- **The Dark Mode Requirement:** Do not introduce a "Light Mode" or arbitrary white backgrounds.
- **The "One Thumb" Rule:** Primary interactions (scanning, closing sheets, viewing recipes) must be doable with a single thumb in the bottom half of the screen.

---

## 7. How to Add New Elements

1. Look for an existing widget in `ResultsScreen` or `CameraScreen` that serves a similar purpose (e.g., `_buildTrickeryCard`, `_buildPriceCard`) and duplicate its styling.
2. If adding a new dialog, use a `showModalBottomSheet` with `AppTheme.cardBackground` and top-rounded corners, rather than an intrusive center `AlertDialog`.
3. If adding a new setting or page, use a standard `Scaffold` with a black background, no `AppBar` (or a transparent one nested safely to avoid scroll overlap), and consistent padding (`EdgeInsets.symmetric(horizontal: 24)`).
