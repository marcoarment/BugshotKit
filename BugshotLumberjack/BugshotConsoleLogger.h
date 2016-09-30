//
//  BugshotConsoleLogger.h
//  BugshotLumberjack
//
//  Created by LiuYang on 16/9/30.
//  Copyright © 2016年 same. All rights reserved.
//

#import <CocoaLumberjack/CocoaLumberjack.h>

@interface BugshotConsoleLogger : DDAbstractLogger

/// Set the maximum number of messages to be displayed on the Dashboard. Default `1000`.
@property (nonatomic)                   NSUInteger maxMessages;

/// An optional formatter to be used for shortened log messages.
@property (atomic, strong)              id<DDLogFormatter> shortLogFormatter;

- (NSArray *)currentLogMessages;

- (void)clearConsole;

- (void)addMarker;

- (NSString *)textWithLogMessage:(DDLogMessage *)logMessage;

@end
