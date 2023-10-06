+++
title = "Style Guide"

sort_by = "weight"
weight = 10
template = "docs/page.html"
date = 2021-05-01T08:00:00+00:00
updated = 2021-05-01T08:00:00+00:00


[extra]
toc = true
top = false

+++

## Acter Brand

### Overview

#### Colors

Colors can be found in [`app/lib/common/themes/app_theme.dart`](https://github.com/acterglobal/a3/blob/main/app/lib/common/themes/app_theme.dart). Whenever possible the `AppTheme.brandColorScheme` should be used in the code base rather than any specific color. New color sets like gradients or changes to existing colors shall be added to that class (for easier customization later).

- Primary Brand Color: <span style="color: #9CCAFF; font-weight: bold"> #9CCAFF </span>
- Secondary Brand Color: <span style="color: #9ACBFF; font-weight: bold"> #9ACBFF </span>
- Tertiary Brand Color: <span style="color: #FFB77B; font-weight: bold"> #FFB77B </span>
- Background Color: <span style="color: #001B3D; font-weight: bold"> #001B3D </span>
- Neutral: <span style="color: #121212; font-weight: bold"> #121212 </span>
- Success: <span style="color: #67A24A; font-weight: bold"> #67A24A </span>

#### Typeface

- App-Wide Font: Inter
- Emoji: System provided fond; on Linux: notoEmoji

#### Icons

We use clean, clear but slightly playful even childish Icons, to get away from a too steril style and keep things fun and social. Whenever possible we use the closest matching [Atlas Icon](https://atlasicons.vectopus.com/) that's already embedded in the app (via `package:atlas_icons/atlas_icons.dart`).

```dart
// Import package
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

Icon(Atlas.audio_album, size: 24.0, )
```
