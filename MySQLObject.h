//
//  MySQLWrapper.h
//  Objective-C JSONParser
//
//  Created by Carlo Tortorella on 24/07/13.
//  Copyright (c) 2013 DALI Lighting Pty Ltd. All rights reserved.
//

#import <stdint.h>
#import <mysql.h>

typedef char byte;

/**
 *
 * MySQLObject allows transmutation of SQL queries using the MySQL C Connector API into NSStrings and abstracts away the need to use C functions.
 *
 */
@interface MySQLObject : NSObject
{
	MYSQL mysql;
	MYSQL_RES * result;
    NSString * host;
    NSString * username;
    NSString * password;
    NSString * database;
    uint16_t port;
}

- (NSNumber *)lastInsertedRowID;
/**
 *
 * Initialises the object and attempts to open a connection using the supplied parameters.
 *
 * @param host Either the IP address or DNS resolved address that you're trying to connect to.
 */
- (id)initWithHost:(NSString *)host username:(NSString *)username password:(NSString *)password database:(NSString *)database andPort:(uint16_t)port;
- (BOOL)query:(NSString *)query error:(NSError **)error;
- (BOOL)queryUnsanitisedWithError:(NSError **)error format:(NSString *)format, ...
#ifdef __APPLE__
NS_FORMAT_FUNCTION(2,3)
#endif
;
- (NSArray *)select:(NSString *)query error:(NSError **)error;
- (NSArray *)selectUnsanitisedWithError:(NSError **)error format:(NSString *)format, ...
#ifdef __APPLE__
NS_FORMAT_FUNCTION(2,3)
#endif
;
- (NSError *)getLastError;
- (NSString *)queryFormattedAsMySQLQuery:(NSString *)format, ...
#ifdef __APPLE__
NS_FORMAT_FUNCTION(1,2)
#endif
;

@end