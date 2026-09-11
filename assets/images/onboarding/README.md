# Onboarding illustrations

Drop the final Vanya artwork in this folder using these exact filenames —
every screen's illustration slot already points at its file via
`Image.asset(..., errorBuilder: ...)`, so it swaps in automatically with no
code change the moment the file exists here. Until then, each slot renders a
soft placeholder gradient in its place.

- `arrival_meadow.png` — Screen 1 (Arrival). Wide meadow shot, Vanya small
  in frame looking out at the landscape.
- `meet_vanya_portrait.png` — Screen 2 (Meet Vanya). Closer portrait crop,
  Vanya looking toward the viewer.
- `intention_meadow.png` — Screen 3 (Intention). A calmer, settled crop.
- `moments_meadow.png` — Screen 4 (Moments). An alert/curious crop.
- `promise_meadow.png` — Screen 5 (Promise). A content, resolved crop.

Recommended: 3x-density PNG or WebP. The arrival slot is a wide 16:11 crop;
the meet-Vanya slot is a 1:1 portrait crop; the other three are slim 16:8
banners, so a wide landscape-oriented crop works best for those.
