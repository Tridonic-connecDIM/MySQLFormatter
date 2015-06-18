//
//  MySQLFormatter.h
//  Objective-C_JSONParser
//
//  Created by Carlo Tortorella on 5/08/2014.
//  Copyright (c) 2014 DALI Lighting Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MySQLFormatter : NSObject
{
    NSString * _formatBuffer;
    NSUInteger _formatLength;
    NSUInteger _cursor;
    
    unichar *_outputBuffer;
    NSUInteger _outputBufferCursor;
    NSUInteger _outputBufferLength;
}

- (NSString *)format:(NSString *)format arguments:(va_list)arguments;

@end
