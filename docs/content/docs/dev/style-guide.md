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

- Primary Brand Color: <span style="color: #EC2758; font-weight: bold"> #EC2758 </span>
- Secondary Brand Color: <span style="color: #23AFC2; font-weight: bold"> #23AFC2 </span>
- Tertiary Brand Color: <span style="color: #5C2A80; font-weight: bold"> #5C2A80 </span>
- Background Color: <span style="color: #979797; font-weight: bold"> #979797 </span>
- Dark Shade: <span style="color: #333540; font-weight: bold"> #333540 </span>
- Secondary Dark Shade: <span style="color: #2F313E; font-weight: bold"> #2F313E </span>
- Divider: <span style="color: #4A4A4A; font-weight: bold"> #4A4A4A </span>
- Text Color: <span style="color: #FFFFFF; font-weight: bold"> #FFFFFF </span>
- Text Shade: <span style="color: #FEFEFE; font-weight: bold"> #FEFEFE </span>
- Text Shade 2: <span style="color: #F8F8F8; font-weight: bold"> #F8F8F8 </span>
- Text Shade 3: <span style="color: #C2C1C0; font-weight: bold"> #C2C1C0 </span>

#### Typeface

- App-Wide Font: Roboto
- Headlines: Roboto Semi-Bold
- Regular Text: Robot Light
- Font-Sizes:
  - H1: 18/20
  - H2: 16/Auto
  - H3 subject: 15/20
  - Body Text: 10/15
  - H4 substitles: 10/15
  - H5 Big Word: 20/25
  - H6 legal: 10/auto

#### Icons

We use clean, clear but slightly playful even childish Icons, to get away from a too steril style and keep things fun and social. Whenever possible we pick of [the vast library of existing icons](https://oblador.github.io/react-native-vector-icons/) that's already embedded in the app (via `flutter_icons_null_safety`, usage as in [flutter icons](https://pub.dev/packages/flutter_icons)).

```dart
// Import package
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter/material.dart';

// After 1.1.0, the FlutterIcons class is provided to access all Icons
// Icon name in the original basis added icon set abbreviation name as suffix
// Hereinafter referred to as the following
//Ant Design Icons -> ant,
//Entypo Icons -> ent,
//Evil Icons -> evi,
//Feather Icons -> fea,
//Font Awesome Icons -> faw,
//Foundation Icons -> fou,
//Ionicons Icons -> ion,
//Material Community Icons -> mco,
//Material Icons -> mdi,
//Octicons Icons -> oct,
//Simple Line Icons -> sli,
//Zocial Icons -> zoc,
//Weather Icons -> wea
Icon(FlutterIcons.stepforward_ant)
Icon(FlutterIcons.html5_faw)
```

### [Brandguide as PDF](/styles/Acter-MVP-Design-Style.pdf)

## Implementation Guide

TBD

## Themeing / Customisastion

TBD
