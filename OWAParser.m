//
//  OWAParser.m
//  OWAParser
//
//  Created by JGA on 2/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OWAParser.h"
#import "XPathQuery.h"

@implementation OWAParser

-(id)init {
	if (self=[super init]) {
	}
	
	return self;
}

-(id)initWithURL:(NSString*)aUrl login:(NSString*)aLogin password:(NSString*)aPassword {
	if (self=[super init]) {
		if (![aUrl hasPrefix:@"http"])
			baseUrl = [NSString stringWithFormat:@"http://%@", aUrl];
		else
			baseUrl = aUrl;
		login = aLogin;
		password = aPassword;
	}
	return self;
}

+(NSString *) urlencode: (NSString *) url
{
    NSArray *escapeChars = [NSArray arrayWithObjects:@";" , @"/" , @"?" , @":" ,
							@"@" , @"&" , @"=" , @"+" ,
							@"$" , @"," , @"[" , @"]",
							@"#", @"!", @"'", @"(", 
							@")", @"*", nil];
	
    NSArray *replaceChars = [NSArray arrayWithObjects:@"%3B" , @"%2F" , @"%3F" ,
							 @"%3A" , @"%40" , @"%26" ,
							 @"%3D" , @"%2B" , @"%24" ,
							 @"%2C" , @"%5B" , @"%5D", 
							 @"%23", @"%21", @"%27",
							 @"%28", @"%29", @"%2A", nil];
	
    int len = [escapeChars count];
	
    NSMutableString *temp = [url mutableCopy];
	
    int i;
    for(i = 0; i < len; i++)
    {
		
        [temp replaceOccurrencesOfString: [escapeChars objectAtIndex:i]
							  withString:[replaceChars objectAtIndex:i]
								 options:NSLiteralSearch
								   range:NSMakeRange(0, [temp length])];
    }
	
    NSString *out = [NSString stringWithString: temp];
	
    return out;
}

-(NSString*)getBaseUrl {
	NSArray *urlComp = [baseUrl componentsSeparatedByString:@"://"];
	return [NSString stringWithFormat:@"%@://%@:%@@%@", [urlComp objectAtIndex:0], login, password, [urlComp objectAtIndex:1]];
}

-(NSString*)getBaseUrlWithoutAuth {
	return baseUrl;
}

-(NSData*)getContentFromUrl:(NSString*)aUrl {
	NSString *builtUrl = [NSString stringWithFormat:@"%@%@", [self getBaseUrlWithoutAuth], aUrl];
	
	/* getting the stored cookies */
	NSArray* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage]
						cookiesForURL:[NSURL URLWithString:[self getBaseUrlWithoutAuth]]];
	/* Make a new header from the cookies */
	NSDictionary* headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
	
	NSMutableURLRequest * theRequest=(NSMutableURLRequest*)[NSMutableURLRequest requestWithURL:[NSURL URLWithString:builtUrl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	[theRequest setAllHTTPHeaderFields:headers];
	
	NSHTTPURLResponse *response = nil;
	
	NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:nil];
	return data;
}

-(NSArray*)performXPathQuery:(NSString*)query onUrl:(NSString*)aUrl {
	NSData *responseData = [self getContentFromUrl:aUrl];
	//NSLog(@"%@", aUrl);
	//NSLog(@"%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
	NSArray *newItemsNodes = PerformHTMLXPathQuery(responseData, query);
	
	return newItemsNodes;
}

-(BOOL)login {
	
	NSString *url = [self getBaseUrl];
	
	NSMutableURLRequest * theRequest=(NSMutableURLRequest*)[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	
	NSHTTPURLResponse *response = nil;
	
	[NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:nil];
	
	/* Get an array with all the cookies */
	NSArray* allCookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:[NSURL URLWithString:[self getBaseUrlWithoutAuth]]];
	/* Add the array of cookies in the shared cookie storage instance */
	[[NSHTTPCookieStorage sharedHTTPCookieStorage]
	 setCookies:allCookies
	 forURL:[NSURL URLWithString:[self getBaseUrlWithoutAuth]]
	 mainDocumentURL:nil];
	 
	 for (NSHTTPCookie* cookie in allCookies) {
		 NSLog(@"\nName: %@\nValue: %@\nExpires: %@", [cookie name], [cookie value], [cookie expiresDate]);
	 }
	
	@try {
		NSData *data = [self getContentFromUrl:@""];
		NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if ([html isEqualToString:@""] || [html rangeOfString:@"You are not authorized to view this page"].location != NSNotFound) {
			return NO;
		} else {
			return YES;
		}
		return NO;
	}
	@catch (NSException * e) {
		return NO;
	}
}

-(NSDictionary*)parseFolderNode:(NSDictionary*)node {
	NSArray *itemNode = [[[node objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeChildArray"];
	NSString* name = [[itemNode objectAtIndex:0] objectForKey:@"nodeContent"];
	NSString* href = [[[[itemNode objectAtIndex:0] objectForKey:@"nodeAttributeArray"] objectAtIndex:1] objectForKey:@"nodeContent"];
	NSString* unreadCount = @"0";
	if ([itemNode count] == 2) {
		unreadCount = [[itemNode objectAtIndex:1] objectForKey:@"nodeContent"];
		unreadCount = [unreadCount substringWithRange:NSMakeRange(1, [unreadCount length]-2)];
	}
	NSDictionary *folder = [[NSDictionary alloc] initWithObjectsAndKeys:
							name, @"name",
							name, @"id",
							href, @"url",
							unreadCount, @"unreadCount",
							nil
							];
	
	return folder;
}

-(NSArray*)getFolders {
	if (!folders) {
		NSString *xpathQueryString = @"//table[@class='wh100']/tr/td/table[@class='snt']/tr";
		NSArray *nodes = [self performXPathQuery:xpathQueryString onUrl:@""];
		folders = [[[NSMutableArray alloc] initWithCapacity:[nodes count]] retain];
		for (int i = 0; i < [nodes count]; i++) {
			[folders addObject:[self parseFolderNode:[nodes objectAtIndex:i]]];
		}
	}
	
	return folders;
}

-(NSDictionary*)getFolderById:(NSString*)folderId {
	if (!folders) {
		[self getFolders];
	}
	for (NSDictionary *folder in folders) {
		if ([[folder objectForKey:@"id"] isEqualToString:folderId])
			return folder;
	}
	return nil;
}

-(int)getInboxUnreadCount {
	NSString *xpathQueryString = @"//table[@class='snt'][1]/tr[3]/td/span";
	NSArray *nodes = [self performXPathQuery:xpathQueryString onUrl:@""];
	if ([nodes count] != 0) {
		NSDictionary *elem = [nodes objectAtIndex:0];
		NSString *spanTag = [elem objectForKey:@"nodeContent"];
		NSString *count = [spanTag substringWithRange:NSMakeRange(1, [spanTag length]-2)];
		return [count intValue];

	}
	else {
		return 0;
	}
	
}

-(NSDate*)parseDateWithString:(NSString*)dateString {
	if(!dateString) return nil;
	
    NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:@"MM/dd/yyyy hh:mm aa"];
	return [formatter dateFromString:dateString];
}


-(NSDictionary*)parseMessageNode:(NSDictionary*)node {

	NSNumber *unread = [NSNumber numberWithBool:([node objectForKey:@"nodeAttributeArray"] != nil)?YES:NO];
	

	NSString *msgId = [[[[[[[node objectForKey:@"nodeChildArray"] objectAtIndex:3] objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeAttributeArray"] objectAtIndex:2] objectForKey:@"nodeContent"];
	NSString *subject = [[[[[[[node objectForKey:@"nodeChildArray"] objectAtIndex:5] objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeContent"];
	
	NSString *dateString = [[[node objectForKey:@"nodeChildArray"] objectAtIndex:6] objectForKey:@"nodeContent"];
	NSDate *date = [self parseDateWithString:dateString];
	
	NSString *from = [[[node objectForKey:@"nodeChildArray"] objectAtIndex:4] objectForKey:@"nodeContent"];
	
	

	NSDictionary *msg = [[NSDictionary alloc] initWithObjectsAndKeys:
						 unread, @"unread",
						 from, @"from",
						 msgId, @"id",
						 subject, @"subject",
						 date, @"date",
						  nil
						];
	
	return msg;

}

-(NSArray*)getMessagesFrom:(NSString*)folderId {
	NSDictionary *folder = [self getFolderById:folderId];
	
	NSString *xpathQueryString = @"//div[@class='cntnt']/table[@class='lvw']/tr";
	NSArray *nodes = [self performXPathQuery:xpathQueryString onUrl:[folder objectForKey:@"url"]];

	NSMutableArray *messages = [[NSMutableArray alloc] initWithCapacity:[nodes count] -2];
	for (int i = 2; i < [nodes count]; i++) {
		[messages addObject:[self parseMessageNode:[nodes objectAtIndex:i]]];
	}
	return messages;
}



-(NSString*)getFullMessageUrlFromId:(NSString*)messageId {
	return [NSString stringWithFormat:@"%@%@", [self getBaseUrlWithoutAuth], [self getMessageUrlFromId:messageId]];
}

-(NSString*)getMessageUrlFromId:(NSString*)messageId {
	return [NSString stringWithFormat:@"?ae=Item&t=IPM.Note&id=%@", [[self class] urlencode:messageId]];
}

-(NSDictionary*)getMessageFromId:(NSString*)messageId {
	NSString *messageUrl = [self getMessageUrlFromId:messageId];
	NSData *responseData = [self getContentFromUrl:messageUrl];
	
	NSString* subject = [[PerformHTMLXPathQuery(responseData, @"//tr[1]/td/table[@class='msgHd']/tr[1]/td[@class='sub']") objectAtIndex:0] objectForKey:@"nodeContent"];
	NSDictionary* fromNode = [PerformHTMLXPathQuery(responseData, @"//tr[1]/td/table[@class='msgHd']/tr[2]/td[@class='frm']/span") objectAtIndex:0];
	NSString* from=nil;
	if ([fromNode objectForKey:@"nodeChildArray"] != nil) {
		from = [[[fromNode objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeContent"];
	} else {
		from = [fromNode objectForKey:@"nodeContent"];
	}

	NSString *sent = [[PerformHTMLXPathQuery(responseData, @"//tr[1]/td/table[@class='msgHd']/tr[4]/td[@class='hdtxnr' and position()=2]") objectAtIndex:0] objectForKey:@"nodeContent"];
	
	NSString *body = PerformHTMLXPathQueryAndReturnText(responseData, @"//tr[2]/td/table[@class='w100']/tr[3]/td[@class='bdy']/div[@class='bdy']/div");
	
	NSDictionary* msg = [[NSDictionary alloc] initWithObjectsAndKeys:
						 subject, @"subject",
						 from, @"from",
						 sent, @"sent",
						 body, @"body",
						 nil];


	return msg;
}


@end
