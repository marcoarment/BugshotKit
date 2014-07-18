BugshotKit
==========

iOS in-app bug reporting for developers and testers, with annotated screenshots and the console log. By [Marco Arment](http://www.marco.org/).

(tl;dr: Embedded [Bugshot](http://www.marco.org/bugshot) plus `NSLog()` collection for beta testing.)

Just perform a gesture of your choice — shake, two-finger swipe-up, three-finger double-tap, swipe from right screen edge, etc. — from anywhere in the app, and the Bugshot report window slides up:

![Screenshot](https://raw.github.com/marcoarment/BugshotKit/master/example-screenshot.png)

It automatically screenshots whatever you were just seeing in the app, and it includes a live `NSLog()` console log **with no dependencies.** (Also compatible with CocoaLumberjack and anything else capable of outputting to the standard system log, or you can add messages manually.)

Tapping the screenshot brings up an embedded version of the Bugshot app: draw bold orange arrows and boxes to annotate, or blur out sensitive information.

Tapping the console brings up a full-screen live console, useful in debugging even when you're not submitting a bug report.

Tap the respective green checkmarks to omit the screenshot or log if you'd like, and then simply compose an email with all of the relevant information already filled in and attached.

## For development and beta tests only!

BugshotKit is made for development and ad-hoc beta testing. **Please do not ship it in App Store builds.**

To help prevent accidentally shipping your app with BugshotKit, I've included a helpful private API call that should cause immediate validation failure upon submitting. If you somehow ship it anyway, it will attempt to detect App Store builds at runtime and disable itself.

These safeguards aren't guaranteed. Please don't rely on them. Remove BugshotKit from your App Store builds.

## Setup

The easiest way to be sure you're not going to build BugshotKit into your App Store builds is to link to it just in your Debug and Ad-Hoc builds. To do that:

1. Build a static library from the BugshotKit Xcode project.
2. Put that library, and the header files that come with it, somewhere in your project folder.
3. Make sure your app build settings' Library Search Paths and Header Search Paths include the path to where you put these.
4. Add `-lBugshotKit` to the Other Linker Flags setting, but only for the Debug and Ad-Hoc builds.
5. Use a conditional macro (e.g. "`#if defined(DEBUG) || defined(ADHOC)`"..."`#endif`") around the BugshotKit import and the invocation, below.

## Usage

Simply invoke `[BugshotKit enableWithNumberOfTouches:...]` from your `application:didFinishLaunchingWithOptions:`:

```obj-c
#import "BugshotKit.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [BugshotKit enableWithNumberOfTouches:1 performingGestures:BSKInvocationGestureSwipeUp feedbackEmailAddress:@"your@app.biz"];
}
```

That's it, really. Console tracking begins immediately, and on the next run-loop pass, it'll look for a `UIWindow` with a `rootViewController` and attach its gesture handlers (if any).

Bugshot can also be shown when the user shakes the device, by using `BSKWindow` in place of `UIWindow` in your application delegate:

```obj-c
self.window = [[BSKWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
```

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

To add custom keys to this, set a block with `[BugshotKit setExtraInfoBlock:]` that returns an `NSDictionary`, and they'll be merged in.

To customize the email subject, set a block with `[BugshotKit setEmailSubjectBlock:]`. It receives the full dictionary as a parameter, with any keys you added with the extra info block, so you can do something like:

```obj-c
[BugshotKit setExtraInfoBlock:^NSDictionary *{
    return @{
        @"userID" : @(1),
        @"colorScheme" : @"dark"
    };
}];

[BugshotKit setEmailSubjectBlock:^NSString *(NSDictionary *info) {
    return [NSString stringWithFormat:@"Bug report from version %@, user %@", info[@"appVersion"], info[@"userID"]];
}];
```

## License

See the included LICENSE file. (It's the MIT license.)

If you use BugshotKit, please consider supporting my bill-paying projects:

* [Marco.org](http://www.marco.org/)
* [Accidental Tech Podcast](http://atp.fm/)
* [Overcast](http://overcast.fm/)

Thanks.

### Inconsolata font

BugshotKit includes [Inconsolata](http://levien.com/type/myfonts/inconsolata.html), a free monospace programming font released under the [SIL Open Font License](http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&item_id=OFL), to make its console look nicer.

Add it to your application's resources to use it. If it's absent, BugshotKit will fall back to Courier New, but its console will look worse.
