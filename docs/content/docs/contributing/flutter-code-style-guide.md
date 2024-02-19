## Flutter - code style guide

👉 This style guide describes the preferred style for code written as part of the [`acter` repository](https://github.com/acterglobal/a3)

### Overview
This document describes our approach to designing and programming Flutter development of the Acter App, from high-level architectural principles all the way to indentation rules.

The primary goal of these style guidelines is to improve code readability so that everyone, whether reading the code for the first time or maintaining it for years, can quickly determine what the code does. Secondary goals are to design systems that are simple, to increase the likelihood of catching bugs quickly, and avoiding arguments when there are disagreements over subjective matters.

That document is focused more about Flutter conventions.

### App Theme
Use theme classes for the generalise theme of the different components and avoid styling at the component level until and unless it is required.

**Key things to note:**
- Colors may not be hardcoded in the code, but should be pulled from the AppTheme.
- Avoid component level styling

Reference: https://docs.flutter.dev/cookbook/design/themes

**Buttons Guide:**

Primary Button
```
 ElevatedButton(
     onPressed: () {},
    child: ...,
),
```

Secondary Button
```
 OutlinedButton(
     onPressed: () {},
    child: ...,
),
```

### Code structure
There are few basis standard we would like to follow in futter code.


**1. General Guide**
- General try-catches (rather use AsyncValues)
- Router for state management

**2. Scrolling usage**
- Use `SingleChildScrollView` in all the general use cases where need widgets need to be scrollable
- Use `CustomScrollView` with its `Slivers` when complex scrolling behavior is required

**3. Avoid Deeply Nested Widget Hierarchies**
- Use module approach of widget layout and avoid huge nesting in code
- It helps to break things out into separate functions / methods, each of which returns a small widget that contributes to a larger interface. This also facilitates code re-use and, at least in theory, makes your code easier to test.
- General rule of thumb: If something feels unwieldy, that usually means you should probably break that logical section out into it's own function.

**4. State management with Riverpod**
- Avoid unneccesary usage of provider where things can be handle without it
- Use appropriate Riverpod provider type based on the use-case
- Avoiding `requireValue` and `ref.watch(clientProvider)!`
- Proper dependency management (ref.watch rather than ref.read(someProvider.notifier).someFunction())`)

**5. Naming Convention**
- Use Names That Are Detailed and Clear
- Observe the Dart Package Naming Guidelines
- File names should contain singular nouns.
- File Names with Prefixes for Related Components
- Keep consistency and reuse in mind
  e.g. `ThingDetailsPage` and `ThingListItem` are common practice.

**5. Common Widget**
Create separate widget which can be reuse

**6. Responsive Design**
- Design should be responsive which can support for different mobile screen sizes, tablets and iPads and Desktop platform
- Use `MediaQuery` for sizes
- For MaxValue use `BoxConstraints`
- Use `isDesktop` rarely! It is almost always misleading in terms showing something because of sizes available (always remember: the latest iPad touch has a higher resolution than the also supported MacBook Air 2017! - isDesktop is an inadequate approximation of what we actually want and that is responsiveness according to the available space)