//
//  OWAParser.h
//  OWAParser
//
//  Created by JGA on 2/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Folder.h"
#import "MessageLite.h"
#import "Message.h"

@interface OWAParser : NSObject {
	NSString* username;
	NSString* password;
	NSString* baseUrl;
	NSMutableArray* folders;
	NSArray* cookies;
    BOOL debug;
}

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *baseUrl;
@property (nonatomic, retain) NSMutableArray *folders;

-(id)initWithURL:(NSString *)aUrl username:(NSString *)aLogin password:(NSString *)aPassword;
-(BOOL)login;
-(void)setDebug;
-(NSArray*)getFolders;
-(int)getInboxUnreadCount;
-(NSArray*)getMessagesFrom:(NSString *)folderId;
-(NSString*)getMessageUrlFromId:(NSString *)messageId;
-(NSString*)getFullMessageUrlFromId:(NSString *)messageId;
-(Message*)getMessageFromId:(NSString *)messageId;
-(void)markMessageUnread:(NSString *)messageId;
-(void)markMessageRead:(NSString *)messageId;
-(void)deleteMessage:(NSString *)messageId;
+(NSString*)formattedDateRelativeToNow:(NSDate *)date;
@end
