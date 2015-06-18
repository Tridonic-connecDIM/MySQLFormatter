//
//  MySQLWrapper.m
//  Objective-C JSONParser
//
//  Created by Carlo Tortorella on 24/07/13.
//  Copyright (c) 2013 DALI Lighting Pty Ltd. All rights reserved.
//

#import "MySQLObject.h"
#import "Functions.h"
#import "MySQLFormatter.h"

@implementation MySQLObject

- (id)initWithHost:(NSString *)hostname username:(NSString *)user password:(NSString *)pass database:(NSString *)db andPort:(uint16_t)p
{
	if (self = [super init])
	{
        host = hostname;
        username = user;
        password = pass;
        database = db;
        port = p;
		mysql_init(&mysql);
		if (!(mysql_real_connect(&mysql, [hostname UTF8String], [user UTF8String], [pass UTF8String], [db UTF8String], p, 0, 0)))
		{
            [self dealloc];
            return nil;
		}
	}
	return self;
}

- (void)dealloc
{
	mysql_close(&mysql);
	[super dealloc];
}

- (NSNumber *)lastInsertedRowID
{
	return [NSNumber numberWithUnsignedLongLong:mysql_insert_id(&mysql)];
}

- (BOOL)query:(NSString *)query error:(NSError **)error
{
	if (error) *error = nil;
	if (!(mysql_query(&mysql, [query UTF8String])))
	{
		return YES;
	}
	if (error) *error = [self getLastError];
	return NO;
}

- (BOOL)queryUnsanitisedWithError:(NSError **)error format:(NSString *)format, ...
{
	if (error) *error = nil;
    va_list arguments;
    va_start(arguments, format);
    NSString * query = [self queryFormattedAsMySQLQuery:format list:arguments];
    va_end(arguments);
    
	return [self query:query error:error];
}

- (NSArray *)selectUnsanitisedWithError:(NSError **)error format:(NSString *)format, ...
{
    va_list arguments;
    va_start(arguments, format);
    NSString * query = [self queryFormattedAsMySQLQuery:format list:arguments];
    va_end(arguments);
    
    return [self select:query error:error];
}

- (NSArray *)select:(NSString *)query error:(NSError **)error
{
	if (error) *error = nil;
	NSMutableArray * retVal = NSMutableArray.array;
	
	if (mysql_query(&mysql, [query UTF8String]))
	{
		NSDictionary * userInfo = [NSDictionary dictionaryWithObject:@"Could not select Interface from db (DB error)." forKey:@"NSLocalizedDescriptionKey"];
		if (error) *error = [NSError errorWithDomain:@"self" code:1101 userInfo:userInfo];
	}

	if (!(result = mysql_store_result(&mysql)))
	{
		NSLog(@"%s", mysql_error(&mysql));
        if (!strcmp("MySQL server has gone away", mysql_error(&mysql)))
        {
            if (!(mysql_real_connect(&mysql, [host UTF8String], [username UTF8String], [password UTF8String], [database UTF8String], port, 0, 0)))
            {
                NSLog(@"%s", mysql_error(&mysql));
            }
        }
        return nil;
	}

	int num_fields = mysql_num_fields(result);

	MYSQL_ROW row;
	MYSQL_FIELD * field;

	NSMutableArray * fieldNames = [NSMutableArray new];
	while ((row = mysql_fetch_row(result)))
	{
		NSMutableDictionary * dictionary = [NSMutableDictionary new];
		for(int i = 0; i < num_fields; ++i)
		{
			if (!i)
			{
				while((field = mysql_fetch_field(result)))
				{
					[fieldNames addObject:[NSString stringWithUTF8String:field->name]];
				}
			}
			if (row[i])
			{
				[dictionary setObject:[NSString stringWithUTF8String:row[i]] forKey:[fieldNames objectAtIndex:i]];
			}
		}
		[retVal addObject:dictionary];
		[dictionary release];
	}
	[fieldNames release];
	return retVal;
}

- (NSError *)getLastError
{
	NSDictionary * userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:mysql_error(&mysql)] forKey:@"NSLocalizedDescriptionKey"];
	return [NSError errorWithDomain:@"self" code:0 userInfo:userInfo];
}

- (NSString *)queryFormattedAsMySQLQuery:(NSString *)format list:(va_list)list
{
    MySQLFormatter * formatter = MySQLFormatter.new;
    NSString * retVal = [formatter format:format arguments:list];
    [formatter release];
    return retVal;
}

- (NSString *)queryFormattedAsMySQLQuery:(NSString *)format, ...
{
    va_list arguments;
    va_start(arguments, format);
    MySQLFormatter * formatter = MySQLFormatter.new;
    NSString * retVal = [formatter format:format arguments:arguments];
    va_end(arguments);
    [formatter release];
    return retVal;
}

@end
