//
//  BugshotConsoleLogger.m
//  BugshotLumberjack
//
//  Created by LiuYang on 16/9/30.
//  Copyright © 2016年 same. All rights reserved.
//

#import "BugshotConsoleLogger.h"
#import "BugshotKit.h"

#define LOG_LEVEL 2

#define NSLogError(frmt, ...)    do{ if(LOG_LEVEL >= 1) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogWarn(frmt, ...)     do{ if(LOG_LEVEL >= 2) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogInfo(frmt, ...)     do{ if(LOG_LEVEL >= 3) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogDebug(frmt, ...)    do{ if(LOG_LEVEL >= 4) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogVerbose(frmt, ...)  do{ if(LOG_LEVEL >= 5) NSLog((frmt), ##__VA_ARGS__); } while(0)

// Private marker message class
@interface BugshotMarkerLogMessage : DDLogMessage

@end

@implementation BugshotMarkerLogMessage

@end

@implementation BugshotConsoleLogger{
    // Managing incoming messages
    dispatch_queue_t _consoleQueue;
    NSMutableArray * _messages;             // All currently displayed messages
    NSMutableArray * _newMessagesBuffer;    // Messages not yet added to _messages
    
    // Scheduling table view updates
    BOOL _updateScheduled;
    NSTimeInterval _minIntervalToUpdate;
    NSDate * _lastUpdate;
    
    // Filtering messages
    BOOL _filteringEnabled;
    NSString * _currentSearchText;
    NSInteger _currentLogLevel;
    NSMutableArray * _filteredMessages;
    
    // Managing expanding/collapsing messages
//    NSMutableSet * _expandedMessages;
    
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // Default values
        _maxMessages = 1000;
        _lastUpdate = NSDate.date;
        _minIntervalToUpdate = 0.3;
        _currentLogLevel = DDLogLevelVerbose;
        
        // Init queue
        _consoleQueue = dispatch_queue_create("console_queue", NULL);
        
        // Init message arrays and sets
        _messages = [NSMutableArray arrayWithCapacity:_maxMessages];
        _newMessagesBuffer = NSMutableArray.array;
//        _expandedMessages = NSMutableSet.set;
        
        // Register logger
        [DDLog addLogger:self withLevel:DDLogLevelAll];
    }
    return self;
}

#pragma mark - Logger

- (void)logMessage:(DDLogMessage *)logMessage
{
    // The method is called from the logger queue
    dispatch_async(_consoleQueue, ^
                   {
                       // Add new message to buffer
                       [_newMessagesBuffer insertObject:logMessage
                                                atIndex:0];
                       
                       // Trigger update
                       [self updateOrScheduleTableViewUpdateInConsoleQueue];
                   });
}

#pragma mark - Log formatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    if (_logFormatter)
    {
        return [_logFormatter formatLogMessage:logMessage];
    }
    else
    {
        return [NSString stringWithFormat:@"%@:%@ %@",
                logMessage.fileName,
                @(logMessage->_line),
                logMessage->_message];
    }
}

- (NSString *)formatShortLogMessage:(DDLogMessage *)logMessage
{
    if (self.shortLogFormatter)
    {
        return [self.shortLogFormatter formatLogMessage:logMessage];
    }
    else
    {
        //不要去掉换行和空格
        return logMessage->_message;
        
//        return [[logMessage->_message
//                 stringByReplacingOccurrencesOfString:@"  " withString:@""]
//                stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    }
}

#pragma mark - Methods

- (void)clearConsole
{
    // The method is called from the main queue
    dispatch_async(_consoleQueue, ^
                   {
                       // Clear all messages
                       [_newMessagesBuffer removeAllObjects];
                       [_messages removeAllObjects];
                       [_filteredMessages removeAllObjects];
//                       [_expandedMessages removeAllObjects];
                       
                       [self updateTableViewInConsoleQueue];
                   });
}

- (void)addMarker{
    BugshotMarkerLogMessage * marker = BugshotMarkerLogMessage.new;
    marker->_message = [NSString stringWithFormat:@"Marker %@", NSDate.date];
    [self logMessage:marker];
}

- (NSArray *)currentLogMessages{
    return _messages;
}

#pragma mark - Handling new messages

- (void)updateOrScheduleTableViewUpdateInConsoleQueue{
    if (_updateScheduled){
        return;
    }
    
    // Schedule?
    NSTimeInterval timeToWaitForNextUpdate = _minIntervalToUpdate + _lastUpdate.timeIntervalSinceNow;
    NSLogVerbose(@"timeToWaitForNextUpdate: %@", @(timeToWaitForNextUpdate));
    if (timeToWaitForNextUpdate > 0)
    {
        _updateScheduled = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeToWaitForNextUpdate * NSEC_PER_SEC)), _consoleQueue, ^
                       {
                           [self updateTableViewInConsoleQueue];
                           
                           _updateScheduled = NO;
                       });
    }
    // Update directly
    else
    {
        [self updateTableViewInConsoleQueue];
    }
}

- (void)updateTableViewInConsoleQueue
{
    _lastUpdate = NSDate.date;
    
    // Add and trim block
    __block NSInteger itemsToRemoveCount;
    __block NSInteger itemsToInsertCount;
    __block NSInteger itemsToKeepCount;
    void (^addAndTrimMessages)(NSMutableArray * messages, NSArray * newItems) = ^(NSMutableArray * messages, NSArray * newItems)
    {
        NSArray * tmp = [NSArray arrayWithArray:messages];
        [messages removeAllObjects];
        [messages addObjectsFromArray:newItems];
        [messages addObjectsFromArray:tmp];
        itemsToRemoveCount = MAX(0, (NSInteger)(messages.count - _maxMessages));
        if (itemsToRemoveCount > 0)
        {
            [messages removeObjectsInRange:NSMakeRange(_maxMessages, itemsToRemoveCount)];
        }
        itemsToInsertCount = MIN(newItems.count, _maxMessages);
        itemsToKeepCount = messages.count - itemsToInsertCount;
    };
    
    // Update regular messages' array
    addAndTrimMessages(_messages, _newMessagesBuffer);
    NSLogDebug(@"Messages to add: %@ keep: %@ remove: %@", @(itemsToInsertCount), @(itemsToKeepCount), @(itemsToRemoveCount));
    
    // Handle filtering
    BOOL forceReload = NO;
    if (_filteringEnabled)
    {
        // Just swithed on filtering?
        if (!_filteredMessages)
        {
            _filteredMessages = [self filterMessages:_messages];
            forceReload = YES;
        }
        
        // Update filtered messages' array
        addAndTrimMessages(_filteredMessages, [self filterMessages:_newMessagesBuffer]);
        NSLogDebug(@"Filtered messages to add: %@ keep: %@ remove: %@", @(itemsToInsertCount), @(itemsToKeepCount), @(itemsToRemoveCount));
    }
    else
    {
        // Just turned off filtering ?
        if (_filteredMessages)
        {
            // Clear filtered messages and force table reload
            _filteredMessages = nil;
            forceReload = YES;
        }
    }
    
    // Empty buffer
    [_newMessagesBuffer removeAllObjects];
    
    // Update table view (dispatch sync to ensure the messages' arrayt doesn't get modified)
    dispatch_sync(dispatch_get_main_queue(), ^
                  {
                      [NSNotificationCenter.defaultCenter postNotificationName:BSKNewLogMessageNotification object:nil];

                      // Completely update table view?
//                      if (itemsToKeepCount == 0 || forceReload)
//                      {
//                          [self.tableView reloadData];
                          
//                      }
                      // Partial only
//                      else
//                      {
//                          [self updateTableViewRowsRemoving:itemsToRemoveCount
//                                                  inserting:itemsToInsertCount];
//                      }
                  });
}

//- (void)updateTableViewRowsRemoving:(NSInteger)itemsToRemoveCount
//                          inserting:(NSInteger)itemsToInsertCount
//{
//    // Remove paths
//    NSMutableArray * removePaths = [NSMutableArray arrayWithCapacity:itemsToRemoveCount];
//    if(itemsToRemoveCount > 0)
//    {
//        NSUInteger tableCount = [self.tableView numberOfRowsInSection:0];
//        for (NSInteger i = tableCount - itemsToRemoveCount; i < tableCount; i++)
//        {
//            [removePaths addObject:[NSIndexPath indexPathForRow:i
//                                                      inSection:0]];
//        }
//    }
//    
//    // Insert paths
//    NSMutableArray * insertPaths = [NSMutableArray arrayWithCapacity:itemsToInsertCount];
//    for (NSInteger i = 0; i < itemsToInsertCount; i++)
//    {
//        [insertPaths addObject:[NSIndexPath indexPathForRow:i
//                                                  inSection:0]];
//    }
//    
//    // Update table view, we should never crash
//    @try
//    {
//        [self.tableView beginUpdates];
//        if (itemsToRemoveCount > 0)
//        {
//            [self.tableView deleteRowsAtIndexPaths:removePaths
//                                  withRowAnimation:UITableViewRowAnimationFade];
//            NSLogVerbose(@"deleteRowsAtIndexPaths: %@", removePaths);
//        }
//        if (itemsToInsertCount > 0)
//        {
//            [self.tableView insertRowsAtIndexPaths:insertPaths
//                                  withRowAnimation:UITableViewRowAnimationFade];
//        }
//        NSLogVerbose(@"insertRowsAtIndexPaths: %@", insertPaths);
//        [self.tableView endUpdates];
//    }
//    @catch (NSException * exception)
//    {
//        NSLogError(@"Exception when updating LumberjackConsole: %@", exception);
//        
//        [self.tableView reloadData];
//    }
//}

- (NSString *)textWithLogMessage:(DDLogMessage *)logMessage {
    NSString * prefix;
    switch (logMessage->_flag)
    {
        case DDLogFlagError   : prefix = @"Ⓔ"; break;
        case DDLogFlagWarning : prefix = @"Ⓦ"; break;
        case DDLogFlagInfo    : prefix = @"Ⓘ"; break;
        case DDLogFlagDebug   : prefix = @"Ⓓ"; break;
        default               : prefix = @"Ⓥ"; break;
    }
    
    // Expanded message?
//    if ([_expandedMessages containsObject:logMessage])
//    {
//        return [NSString stringWithFormat:@" %@ %@", prefix, [self formatLogMessage:logMessage]];
//    }
    
    // Collapsed message
    return [NSString stringWithFormat:@" %@ %@", prefix, [self formatShortLogMessage:logMessage]];
}


#pragma mark - Message filtering

- (NSMutableArray *)filterMessages:(NSArray *)messages
{
    NSMutableArray * filteredMessages = NSMutableArray.array;
    for (DDLogMessage * message in messages)
    {
        if ([self messagePassesFilter:message])
        {
            [filteredMessages addObject:message];
        }
    }
    return filteredMessages;
}

- (BOOL)messagePassesFilter:(DDLogMessage *)message
{
    // Message is a marker OR (Log flag matches AND (no search text OR contains search text))
    return ([message isKindOfClass:[BugshotMarkerLogMessage class]] ||
            ((message->_flag & _currentLogLevel) &&
             (_currentSearchText.length == 0 ||
              [[self formatLogMessage:message] rangeOfString:_currentSearchText
                                                     options:(NSCaseInsensitiveSearch |
                                                              NSDiacriticInsensitiveSearch |
                                                              NSWidthInsensitiveSearch)].location != NSNotFound)));
}
@end
