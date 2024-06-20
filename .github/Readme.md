SongPocket is a library-focused music player.

It’s on the [App Store](https://apps.apple.com/us/app/songpocket/id1538037231).

# Permissions

You have a Creative Commons [Attribution-NonCommercial-ShareAlike](https://creativecommons.org/licenses/by-nc-sa/4.0) 4.0 International license for this software.

That means you can adapt or share it, but when you do so, please…

1. Mention _SongPocket by Loud Sound Dreams_.
2. Don’t sell it.
3. Apply these same rules to the resulting work.

Be reasonable. [Contact me](mailto:linus@loudsounddreams.com) with any questions.

# Non-goals

SongPocket won’t do everything for everyone, and generally, we should [remove](https://ignorethecode.net/blog/2010/02/02/removing-features) and [say no](https://alexgaynor.net/2020/nov/30/why-software-ends-up-complex) to features more often, for a simpler experience.

So Songpocket tentatively…

1. Won’t offer multiple ways to do the same action. [Monotonous design is better.](https://verbnounenter.net/monotony)
2. Won’t replace iOS’s Music app. This lets it do better what the Music app doesn’t focus on. (Besides, [there’s no API](https://developer.apple.com/documentation/musickit/musiclibrary) for removing items from the user’s library.)
3. Won’t show song durations, because I [consider them spoilers](https://en.wikipedia.org/wiki/Hidden_track). If this were a music app for everyone, I would add a mode; but it’s not, and [modes are bad](https://spectrum.ieee.org/of-modes-and-men). (Settings are modes too.)
4. Won’t include appearance options like dark mode or accent color, because they distract from the key experience. Focus means spending your full attention on what actually matters, and preventing yourself from fiddling.

Want to make different decisions? You can make your own version:

# Compiling

1. Install Xcode on your Mac.
2. Download the code for SongPocket, then open “LavaRock.xcodeproj”. (That’s SongPocket’s internal name.)
3. Atop the Xcode window, choose an iOS Simulator device, then click the “play” button.

For help, see [Apple’s documentation](https://developer.apple.com/documentation/xcode/building-and-running-an-app).

## For a physical device

In the Simulator, most Apple Music features are unavailable, so you’ll need to develop on a physical device. This takes a few more steps.

1. Plug your iOS device into your Mac.
2. Atop the Xcode window, choose your device, then click “play”. Xcode will show an error, “Unknown Team”.
3. In the menu bar, choose Xcode → Settings → Accounts, then sign in to your Apple account. (Warning: you can only run your app [on 3 devices](https://stackoverflow.com/questions/44230347) unless you pay for the Apple Developer Program.)
4. In the main Xcode window, in the left sidebar, click the folder icon, then the topmost “LavaRock” row. To the right, below “Targets”, choose “LavaRock”, then above, click “Signing & Capabilities”. Below “Signing (Debug)”, for “Team”, choose the one associated with your Apple account.
5. Xcode will show an error, “Failed Registering Bundle Identifier”. For “Bundle Identifier”, replace “com.loudsounddreams.LavaRockDebug” with anything else. (This is how Apple devices tell apps apart.) Click “Try Again”, then click “play”.
6. Xcode will say “Developer Mode disabled”. Follow its instructions to [turn on Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device) on your device. Choose your device, then click “play”.
7. Xcode will say “the request to open ‘[your bundle identifier]’ failed.” Follow its instructions for your iOS device, then click “play”.

For help, see [Apple’s documentation](https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device/#Connect-real-devices-to-your-Mac).

# Contributing

Fork this repo, make your changes in your fork, then open a pull request against my repo. For help, see [GitHub’s documentation](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/getting-started/about-collaborative-development-models#fork-and-pull-model).

If you change the UI, include screenshots. (You were looking at it anyway, right?)