+++
title = "Setting up"

sort_by = "weight"
weight = 1
template = "docs/page.html"
+++

## Installing Acter

Acter is published on the various app stores on a weekly basis. Just head on over to the app store of your platform and install acter:

### Apple iOS AppStore

<a href="https://apps.apple.com/us/app/acter/id6445989155?itsct=apps_box_badge&amp;itscg=30200">
    <img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83&amp;releaseDate=1694390400" alt="Download on the App Store" style="border-radius: 13px; width: 250px; height: 83px;">
</a>

### Android Google Play Store

<a href='https://play.google.com/store/apps/details?id=global.acter.a3&pcampaignid=pcampaignidMKT-Other-global-all-co-prtnr-py-PartBadge-Mar2515-1'>
    <img alt='Get it on Google Play' width="250" src='https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png'/>
</a>

_FDroid is not yet supported_ [tracking issue here](https://github.com/acterglobal/a3/issues/1016) . But you can just the latest [nightly build](/nightly).

### Windows Microsoft Store

<a href="ms-windows-store://pdp/?ProductId=9NZLTDVTN203">
    <img height="83" src="https://get.microsoft.com/images/en-us%20dark.svg" alt="Download Acter" />
</a>

### Apple Desktop App AppStore

_not yet supported_ [tracking issue here](https://github.com/acterglobal/a3/issues/1016) . But you can just the latest [nightly build](/nightly)

### Snapcraft Linux Store

_not yet supported_ [tracking issue here](https://github.com/acterglobal/a3/issues/1016) . But you can just the latest [nightly build](/nightly).

## Installing latest nightly

To install the nightly latest built, head over to [the nightly build section](/nightly/) and download the corresponding package for your platform. Once the download finished unpack it and run the `Acter` executable. Be sure to note the following for your platform:

<details>
<summary><strong>Running on MacOS</strong></summary>
MacOS will probably refuse to open the application stating it was downloaded from an unknown Source. To allow it to proceed, close that said dialog, Navigate to your `System Settings -> General -> Privacy & Security` and under the security section you'll find the option to `Run Acter anyways`. Click that to start Acter. And subsequent run should work without it bothering you again. You might have to repeat that process for every new downloaded version though. 
</details>

<details>
<summary><strong>Install on iPhone/iOS</strong></summary>
We are running this in a limited so called Ad-Hoc built at the moment, which requires us to register every iOS device with Apple prior for it to work. In order to be able to do that, you need to navigate to [udid.tech](https://udid.tech/) with your target device(s), follow the process there and sent us over the resulting UDID. Once we have received that we will submit it to apple and the next nightly built after (in general) should be able to work on your device. To install just navigate to the [nightly page](/nightly/) on your device and click `iOS / iPhone` - it should ask you a few security questions but then should be willing to proceed.

**Note**: We have a limit number (100) of signatures we can add for the built, so please only register devices you are expecting to use and inform us if you stop using any device, so we can free up that slot.

</details>

## Platform support

### Mobile

Our current built is expected to work on (and above):

- **Android** 5.0\* (SDKv21 / "Lollipop"), ARM64
- **iOS** 11 ARM64 (no x86 or simulator)

### Desktop

We currently built for

- **Windows** 10 and 11, Arch: x86_64 (no arm)
- **Mac OS**: 10.14\* (Mojave) and above on Intel, version 11 an above on Apple Silicon (M1 & M2)
- **Linux**: Debian 10-11 64bit, Ubuntu 18.04 LTS 64bit or alike; _32bit & ARM are not supported at the moment_

**\*Note**: While we do built against these _older_ API levels, we generally only test against the latest 2 stable releases of any platform and **highly recommend** keeping the underlying systems up-to-date with the latest security updates from the vendor. Thus we **do not** recommend using the lowest possible platforms nor support them, as that is often already past its end-of-live and therefore can't be considered a secure platform to run on anymore. See end of life of [Android](https://endoflife.date/android), [iOS](https://endoflife.date/ios), [macOS](https://endoflife.date/macos), [Windows](https://endoflife.date/windows), [Linux Kernel](https://endoflife.date/linux).
