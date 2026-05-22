# MyDailyCloset Open Source Preview

Public, safe-to-share parts of the MyDailyCloset project.

This repository includes:

- the native iOS SwiftUI preview shell
- a sample local wardrobe data file
- a free/open-source background removal helper script
- sanitized PWA planning docs

This repository does not include production secrets, the production Next.js/PWA app source, resale logic, full stylist logic, private prompts, or real user data.

## PWA direction

The production product is moving toward a phone-first PWA for beta testing. The private repository contains the production implementation. This public repository keeps only safe planning/reference material:

- `docs/PWA_TASK_CHECKLIST.md`
- `docs/OPEN_SOURCE_STRATEGY.md`
- `docs/OPEN_SOURCE_BOUNDARY.md`

## Run the iOS preview

Open `ios/MyDailyClosetPreview/MyDailyClosetPreview.xcodeproj` in Xcode and run it on an iPhone simulator.

## Run background removal

```bash
pip install rembg Pillow
python scripts/remove_background.py input.jpg output.png
```
