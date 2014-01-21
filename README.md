BugshotKit
==========

iOS in-app bug reporting for developers and testers, with annotated screenshots and the console log. By [Marco Arment](http://www.marco.org/).

(tl;dr: Embedded [Bugshot](http://www.marco.org/bugshot) plus `NSLog()` collection for beta testing.)

Just perform a gesture of your choice — two-finger swipe-up, three-finger double-tap, swipe from right screen edge, etc. — from anywhere in the app, and the Bugshot report window slides up:

![Screenshot](https://raw.github.com/marcoarment/BugshotKit/master/example-screenshot.png)

It automatically screenshots whatever you were just seeing in the app, and it includes a live `NSLog()` console log **with no dependencies.** (Also compatible with CocoaLumberjack and anything else capable of outputting to the standard system log, or you can add messages manually.)

Tapping the screenshot brings up an embedded version of the Bugshot app: draw bold orange arrows and boxes to annotate, or blur out sensitive information.

Tapping the console brings up a full-screen live console, useful in debugging even when you're not submitting a bug report.

Tap the respective green checkmarks to omit the screenshot or log if you'd like, and then simply compose an email with all of the relevant information already filled in and attached.

## For development and beta tests only!

BugshotKit is made for development and ad-hoc beta testing. **Please do not ship it in App Store builds.**

To help prevent accidentally shipping your app with BugshotKit, I've included a helpful private API call that should cause immediate validation failure upon submitting. If you somehow ship it anyway, it will attempt to detect App Store builds at runtime and disable itself.

These safeguards aren't guaranteed. Please don't rely on them. Remove BugshotKit from your App Store builds.

## Usage

Simply invoke `[BugshotKit enableWithNumberOfTouches:...]` from your `application:didFinishLaunchingWithOptions:`:

```obj-c
#import "BugshotKit.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [BugshotKit enableWithNumberOfTouches:1 performingGestures:BSKInvocationGestureSwipeUp feedbackEmailAddress:@"your@app.biz" extraInfoBlock:NULL];
}
```

That's it, really. Console tracking begins immediately, and on the next run-loop pass, it'll look for a `UIWindow` with a `rootViewController` and attach its gesture handlers (if any).

If you don't want to use gesture triggers, you can invoke it manually (from a button, maybe):

```obj-c
[BugshotKit show];
```

BugshotKit's emails include an `info.json` file containing basic info in JSON:

```json
{
  "appName" : "TestBugshotKit",
  "appVersion" : "1.0",
  "systemVersion" : "7.1",
  "deviceModel" : "iPhone6,1"
}
```

To add custom keys to this, supply an `extraInfoBlock` to the initial call that returns an `NSDictionary`, and they'll be merged in.

## License

See the included LICENSE file. (It's the MIT license.)

If you use BugshotKit, please consider supporting my bill-paying projects:

* [Marco.org](http://www.marco.org/)
* [Accidental Tech Podcast](http://atp.fm/)
* [Overcast](http://overcast.fm/) (coming soon)

Thanks.

### Inconsolata font

BugshotKit includes [Inconsolata](http://levien.com/type/myfonts/inconsolata.html), a free monospace programming font released under the [SIL Open Font License](http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&item_id=OFL).

Add it to your application's resources to use it. If it's absent, BugshotKit will fall back to Courier New, but it'll look worse.
