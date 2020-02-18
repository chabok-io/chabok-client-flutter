//
//  ChabokLogger.h
//  Chabok
//
//  Created by Hussein Habibi Juybari on 2019-06-15.
//  Copyright (c) 2012-2019 Chabok. All rights reserved.
//
#import <Foundation/Foundation.h>

typedef enum {
    ChabokLogLevelVerbose  = 1,
    ChabokLogLevelDebug    = 2,
    ChabokLogLevelInfo     = 3,
    ChabokLogLevelWarn     = 4,
    ChabokLogLevelError    = 5,
    ChabokLogLevelAssert   = 6,
    ChabokLogLevelSuppress = 7
} ChabokLogLevel;

/**
 * @brief Chabok logger protocol.
 */
@protocol ChabokLogger

/**
 * @brief Set the log level of the SDK.
 *
 * @param logLevel Level of the logs to be displayed.
 */
- (void)setLogLevel:(ChabokLogLevel)logLevel;

/**
 * @brief Prevent log level changes.
 */
- (void)lockLogLevel;

/**
 * @brief Print verbose logs.
 */
- (void)verbose:(nonnull NSString *)message, ...;

/**
 * @brief Print debug logs.
 */
- (void)debug:(nonnull NSString *)message, ...;

/**
 * @brief Print info logs.
 */
- (void)info:(nonnull NSString *)message, ...;

/**
 * @brief Print warn logs.
 */
- (void)warn:(nonnull NSString *)message, ...;

/**
 * @brief Print error logs.
 */
- (void)error:(nonnull NSString *)message, ...;

/**
 * @brief Print assert logs.
 */
- (void)assert:(nonnull NSString *)message, ...;

@end

/**
 * @brief Chabok logger class.
 */
@interface ChabokLogger : NSObject<ChabokLogger>

/**
 * @brief Convert log level string to ChabokLogLevel enumeration.
 *
 * @param logLevelString Log level as string.
 *
 * @return Log level as ChabokLogLevel enumeration.
 */
+ (ChabokLogLevel)logLevelFromString:(nonnull NSString *)logLevelString;

@end
