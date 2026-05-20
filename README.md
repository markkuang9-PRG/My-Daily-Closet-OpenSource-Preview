# MyDailyCloset Open Source Preview

Public, safe-to-share parts of the MyDailyCloset project.

This repository includes:

- the native iOS SwiftUI preview shell
- a sample local wardrobe data file
- a free/open-source background removal helper script

This repository does not include production secrets, resale logic, full stylist logic, or real user data.

## Run the iOS preview

Open `ios/MyDailyClosetPreview/MyDailyClosetPreview.xcodeproj` in Xcode and run it on an iPhone simulator.

## Run background removal

```bash
pip install rembg Pillow
python scripts/remove_background.py input.jpg output.png
```
