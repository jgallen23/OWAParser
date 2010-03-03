//
//  OWAParser.h
//  OWAParser
//
//  Created by JGA on 2/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


@interface OWAParser : NSObject {
	NSString* login;
	NSString* password;
	NSString* baseUrl;
	NSData* currentPageData;
	NSMutableArray* folders;
}

-(id)initWithURL:(NSString *)aUrl login:(NSString *)aLogin password:(NSString *)aPassword;
-(BOOL)isAuthenticated;
-(NSArray*)getFolders;
-(int)getInboxUnreadCount;
-(NSArray*)getMessagesFrom:(NSString *)folderId;
@end
