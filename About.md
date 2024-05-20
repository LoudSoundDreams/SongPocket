SongPocket is a library-focused music player.

It’s on the [App Store](https://apps.apple.com/us/app/songpocket/id1538037231).

You shouldn’t need to be a rocket scientist to play with this. If anything’s unclear, [contact me](mailto:linus@loudsounddreams.com)!

# Expectations

Think of this repo like a backstage tour. Please report or fix bugs. I welcome suggestions too, but I make the final call on decisions.

If you want to make different decisions, you can make your own version. About that…

# Permissions

You have a Creative Commons [Attribution-NonCommercial-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0) license for this software.

That means you can adapt or share it, but when you do so, please…

1. Mention _SongPocket by Loud Sound Dreams_.
2. Don’t sell it.
3. Apply these same rules to the resulting work.

Be reasonable. Contact me with any questions.

# How to compile

1. Install Xcode on your Mac.
2. Download the code for SongPocket, then open “LavaRock.xcodeproj”. (That’s SongPocket’s internal name.)
3. Atop the Xcode window, choose an iOS Simulator device, then click the “play” button.

For help, see [Apple’s documentation](https://developer.apple.com/documentation/xcode/building-and-running-an-app).

## For a physical device

In the Simulator, most Apple Music features are unavailable, so you’ll need to develop on a physical device. This takes a few more steps.

1. Plug your iOS device into your Mac.
2. Atop the Xcode window, choose your device.
3. On your iOS device, [turn on Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).
4. On your Mac, in the menu bar, choose Xcode → Settings → Accounts, then sign in to your Apple account. (Warning: you can only run your app [on 3 devices](https://stackoverflow.com/questions/44230347) unless you pay for the Apple Developer Program.)
5. In the main Xcode window, in the left sidebar, click the folder icon, then the topmost “LavaRock” row. To the right, below “Targets”, choose “LavaRock”, then above, click “Signing & Capabilities”. For “Team”, choose the one associated with your Apple account.
6. For “Bundle Identifier”, replace “com.loudsounddreams.LavaRockDebug” with anything else. (This is how Apple devices tell apps apart.) Below the message “Failed Registering Bundle Identifier”, click “Try Again”.
7. Atop the Xcode window, click “play”.
8. Xcode will say “the request to open ‘[your bundle identifier]’ failed.” Follow its instructions for your iOS device, then click “play” again.

For help, see [Apple’s documentation](https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device/#Connect-real-devices-to-your-Mac).

## To submit changes

Fork this repo, make your changes in your fork, then open a pull request against my repo. For help, see [GitHub’s documentation](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/getting-started/about-collaborative-development-models#fork-and-pull-model).

If you change the UI, include screenshots. (You were looking at it anyway, right?)

# Non-goals

SongPocket won’t do everything for everyone, and generally, we should [remove](https://ignorethecode.net/blog/2010/02/02/removing-features) and [say no](https://alexgaynor.net/2020/nov/30/why-software-ends-up-complex) to features more often, for a simpler experience.

So, tentatively…

1. SongPocket won’t replace iOS’s Music app. This lets it do better what iOS Music doesn’t focus on. (Besides, [there’s no API](https://developer.apple.com/documentation/musickit/musiclibrary) for removing items from the user’s library.)
2. SongPocket won’t offer multiple ways to do the same action. [Monotonous design is better.](https://verbnounenter.net/monotony)