# FMODFix

A MobileSubstrate tweak that restores **music and sound** in 32-bit games built using older **FMOD Ex** on **iOS 10**.

Tested on an iPhone 6 running iOS 10.2.1 with:
- **Dead Space**
- **Mass Effect Infiltrator**
- **BioShock** 

But there's probably many more apps this potentially applies to.

## Do I need this

If you have old games that run on iOS 10 but everything is silent or frozen until the length of the expected sound has elapsed ...
then you probably need this tweak. 

## Why this happens

FMOD Ex creates its file/streaming thread `FMOD::FileThread` with a hardcoded **8 KB** stack. iOS 10's
`pthread_attr_setstacksize` rejects that size with `EINVAL`, so the thread is never created. The result is simple, most
audio directly fails or produces weird side-effects.

## Fix

The tweak hooks `pthread_attr_setstacksize`. If the game's own code asks for a stack that iOS rejects with `EINVAL`, it
retries with 16 KB (aligned). Nothing else is modified. It's that simple.

It loads into UIKit apps but does nothing unless the app is:
- An App Store or "User App"
- It contains the `FMOD file thread` string.

This should work universally because that string is not a symbol but .text data

## Install

Install the `.deb` from the releases page (or build it yourself), then relaunch the game.

When it's active, the syslog shows:

```
[FMODFix] FMOD Ex found in Dead Space, hooked (main header 0x...)
[FMODFix] setstacksize(8192) = EINVAL from header+0x... -> retried with 16384 = 0
```

## Build

I had Claude-Code make the build integration, did not want to do that myself.

Theos in Docker (Linux host, armv7, iPhoneOS 10.3 SDK):

```sh
docker build -t fmodfix-theos docker
docker run --rm -u $(id -u):$(id -g) -e HOME=/tmp -v "$PWD":/work -w /work fmodfix-theos make package FINALPACKAGE=1
```

The package ends up in `packages/`.

## Credits

- **Claude Fable 5 (Anthropic)**: build integration and tooling

**Dead Space and Mass Effect are trademarks of Electronic Arts Inc. FMOD is a trademark of Firelight Technologies Pty Ltd.
This project is not affiliated with EA or Firelight, and it contains no game code, library code or assets.**
