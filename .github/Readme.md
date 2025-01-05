SongPocket is an immersive player for your Apple Music library on iOS.

Arrange your library manually! Put your favorite albums and songs on top, or reverse or shuffle them.

[Get from the App Store.](https://apps.apple.com/us/app/songpocket/id1538037231)

# Philosophy

SongPocket is focused and elegant.

**Focus** means judiciously [saying no to](https://alexgaynor.net/2020/nov/30/why-software-ends-up-complex) and [removing](https://ignorethecode.net/blog/2010/02/02/removing-features) features.

- For example, only one way to do most given actions. You can’t swipe or touch-and-hold a song to play it later; you must use the buttons. That’s [monotony](https://verbnounenter.net/monotony).
- No settings, because they distract. That actually lets you fearlessly delete and reinstall the app.

I like minimalism because it means everything there is important.

**Elegance** means simple yet powerful.

- For example, [select-range](https://verbnounenter.net/range-selection) lets you easily select multiple items at once.
- Reorder, play-later, or shuffle-play only selected items.

Shockingly flexible is generally good.

# Non-goals

Things I explicitly don’t want. This list is incomplete, tentative, and hopefully helpful, not spiteful.

- Listening history
- Song durations

# Compiling

1. Install Xcode on your Mac.
2. Download the code for SongPocket, then open the “LavaRock” Xcode Project file. (That’s SongPocket’s internal name.)
3. Atop the Xcode window, choose an iOS Simulator device, then click “play”.

For help, see [Apple’s documentation](https://developer.apple.com/documentation/xcode/building-and-running-an-app).

## For a physical device

The Simulator doesn’t support most Apple Music features, so you’ll need to develop on a physical device. This takes a few more steps.

1. Plug your iOS device into your Mac.
2. Atop the Xcode window, choose your device, then click “play”. Xcode will show an error, “Unknown Team”.
3. In the menu bar, choose Xcode → Settings → Accounts, then sign in to your Apple account. (Warning: you can only run your app [on 3 devices](https://stackoverflow.com/questions/44230347) unless you pay for the Apple Developer Program.)
4. In the main Xcode window, in the left sidebar, click the folder icon, then the topmost “LavaRock” row. To the right, below “Targets”, choose “LavaRock”, then above, click “Signing & Capabilities”. Below “Signing (Debug)”, for “Team”, choose your Apple account.
5. Xcode will show an error, “Failed Registering Bundle Identifier”. For “Bundle Identifier”, replace “com.loudsounddreams.LavaRockDebug” with anything else. (This is how Apple devices tell apps apart.) Click “Try Again”, then click “play”.
6. Xcode will say “Developer Mode disabled”. Follow its instructions to [turn on Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device) on your device. Choose your device, then click “play”.
7. Xcode will say “the request to open ‘[your bundle identifier]’ failed.” Follow its instructions for your iOS device, then click “play”.

For help, see [Apple’s documentation](https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device/#Connect-real-devices-to-your-Mac).

# Contributing

Fork this repo, make your changes in your fork, then open a pull request against my repo. For help, see [GitHub’s documentation](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/getting-started/about-collaborative-development-models#fork-and-pull-model).

Include screenshots if you change the UI—you were looking at it anyway, right?

# Permissions

You have a Creative Commons [Attribution-NonCommercial-ShareAlike](https://creativecommons.org/licenses/by-nc-sa/4.0) 4.0 International license for this software.

That means you can adapt or share it, but when you do so, please…

1. Mention _SongPocket by Loud Sound Dreams_.
2. Don’t sell it.
3. Apply these same rules to the resulting work.

Be reasonable. [Contact me](mailto:linus@loudsounddreams.com) with any questions.