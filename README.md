BugshotKit
==========

iOS in-app bug reporting for developers and testers, with annotated screenshots and the console log.

(tl;dr version: embedded [Bugshot](http://www.marco.org/bugshot) plus `NSLog()` collection for beta testing.)

# Usage

Simply invoke `[BugshotKit enableWithNumberOfTouches:...]` from your `application:didFinishLaunchingWithOptions:`:

```obj-c
#import "BugshotKit.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [BugshotKit enableWithNumberOfTouches:1 performingGestures:BSKInvocationGestureSwipeFromRightEdge feedbackEmailAddress:@"your@email.biz" extraInfoBlock:NULL];
}
```

That's it, really. You can customize it

# License

See the included LICENSE file. (It's the MIT license.)

## Inconsolata font

BugshotKit includes [Inconsolata](http://levien.com/type/myfonts/inconsolata.html), a free monospace programming font released under the [SIL Open Font License](http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&item_id=OFL).
