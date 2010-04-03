//
//  OWAParser.m
//  OWAParser
//
//  Created by JGA on 2/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OWAParser.h"
#import "XPathQuery.h"

static NSString* urlencode(NSString *url) {
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

@implementation OWAParser

@synthesize username;
@synthesize password;
@synthesize baseUrl;
@synthesize folders;

-(id)init {
	if (self=[super init]) {
	}
	
	return self;
}

-(NSString*)getCorrectBaseUrl:(NSString*)url {
	if (![url hasPrefix:@"http"])
		url = [NSString stringWithFormat:@"http://%@", url];
	if (![url hasSuffix:@"/"])
		url = [url stringByAppendingString:@"/"];
	return url;
}

-(id)initWithURL:(NSString*)aUrl username:(NSString*)aLogin password:(NSString*)aPassword {
	if (self=[super init]) {
		self.baseUrl = [self getCorrectBaseUrl:aUrl];
		self.username = aLogin;
		self.password = aPassword;
	}
	return self;
}

-(NSString*)getBaseUrl {
	NSArray *urlComp = [self.baseUrl componentsSeparatedByString:@"://"];
	return [NSString stringWithFormat:@"%@://%@:%@@%@", [urlComp objectAtIndex:0], self.username, self.password, [urlComp objectAtIndex:1]];
}

-(NSString*)getBaseUrlWithoutAuth {
	return self.baseUrl;
}

-(NSData*)getContentFromUrl:(NSString*)aUrl PostData:(NSDictionary*)postData {
	NSString *builtUrl = [NSString stringWithFormat:@"%@%@", [self getBaseUrlWithoutAuth], aUrl];
	
	/* Make a new header from the cookies */
	NSMutableDictionary* headers = [NSMutableDictionary dictionaryWithDictionary:[NSHTTPCookie requestHeaderFieldsWithCookies:cookies]];
	
	NSMutableURLRequest * theRequest=(NSMutableURLRequest*)[NSMutableURLRequest requestWithURL:[NSURL URLWithString:builtUrl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	
	if (postData != nil) {
		[theRequest setHTTPMethod:@"POST"];
		NSString* myRequestString = [postData urlEncodedString];
		
		[headers setObject:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
		[headers setObject:[NSString stringWithFormat:@"%d",[myRequestString length]] forKey:@"Content-Length"];
		
		NSData *myRequestData = [ NSData dataWithBytes: [ myRequestString UTF8String ] length: [ myRequestString length ] ];
		[theRequest setHTTPBody:myRequestData];
	}
	[theRequest setAllHTTPHeaderFields:headers];
	
	
	NSHTTPURLResponse *response = nil;
	NSError* error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:&error];
    if (debug) {
        NSString *html = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        [self logObject:html];
    }
	return data;
}

-(void)setDebug {
    debug = YES;
}

-(void)logObject:(id)obj {
    if (debug) {
        NSLog(@"%@", obj);
    }
}

-(NSData*)getContentFromUrl:(NSString*)aUrl {
	return [self getContentFromUrl:aUrl PostData:nil];
}

-(NSArray*)performXPathQuery:(NSString*)query onUrl:(NSString*)aUrl {
	NSData *responseData = [self getContentFromUrl:aUrl];
	NSArray *newItemsNodes = PerformHTMLXPathQuery(responseData, query);
	
	return newItemsNodes;
}

-(BOOL)login {
	
	NSString *url = [self getBaseUrl];
	
	NSMutableURLRequest * theRequest=(NSMutableURLRequest*)[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	
	NSHTTPURLResponse *response = nil;
	
	[NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:nil];
		
	@try {
		NSData *data = [self getContentFromUrl:@""];
		NSString *html = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		if ([html isEqualToString:@""] || [html rangeOfString:@"You are not authorized to view this page"].location != NSNotFound) {
			return NO;
        } else if ([html rangeOfString:@"hidcanary"].location != NSNotFound) {
            /* Get an array with all the cookies */
            cookies = [[NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:[NSURL URLWithString:[self getBaseUrlWithoutAuth]]] retain];
            /* Add the array of cookies in the shared cookie storage instance */
            [[NSHTTPCookieStorage sharedHTTPCookieStorage]
             setCookies:cookies
             forURL:[NSURL URLWithString:[self getBaseUrlWithoutAuth]]
             mainDocumentURL:nil];
			return YES;
		}
	}
	@catch (NSException * e) {
	}
	return NO;
}

-(Folder*)parseFolderNode:(NSDictionary*)node {
	NSArray *itemNode = [[[node objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeChildArray"];
	NSString* name = [[itemNode objectAtIndex:0] objectForKey:@"nodeContent"];
	NSString* href = [[[[itemNode objectAtIndex:0] objectForKey:@"nodeAttributeArray"] objectAtIndex:1] objectForKey:@"nodeContent"];
	NSInteger unreadCount = 0;
	if ([itemNode count] == 2) {
		NSString* strUnreadCount = [[itemNode objectAtIndex:1] objectForKey:@"nodeContent"];
		strUnreadCount = [strUnreadCount substringWithRange:NSMakeRange(1, [strUnreadCount length]-2)];
		unreadCount = [strUnreadCount intValue];
	}
	
	Folder* folder = [[[Folder alloc] initWithName:name URL:href UnreadCount:unreadCount] autorelease]; 
	
	return folder;
}

-(NSArray*)getFolders {
	if (!self.folders) {
		NSString *xpathQueryString = @"//table[@class='wh100']/tr/td/table[@class='snt']/tr";
		NSArray *nodes = [self performXPathQuery:xpathQueryString onUrl:@""];
		self.folders = [[[NSMutableArray alloc] initWithCapacity:[nodes count]] retain];
		for (int i = 0; i < [nodes count]; i++) {
			[folders addObject:[self parseFolderNode:[nodes objectAtIndex:i]]];
		}
	}
	
	return self.folders;
}

-(Folder*)getFolderById:(NSString*)folderId {
	if (!self.folders) {
		[self getFolders];
	}
	for (Folder *folder in self.folders) {
		if ([folder.name isEqualToString:folderId])
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


-(MessageLite*)parseMessageNode:(NSDictionary*)node {

	BOOL unread = ([node objectForKey:@"nodeAttributeArray"] != nil)?YES:NO;
	

	NSString *msgId = [[[[[[[node objectForKey:@"nodeChildArray"] objectAtIndex:3] objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeAttributeArray"] objectAtIndex:2] objectForKey:@"nodeContent"];
	NSString *subject = [[[[[[[node objectForKey:@"nodeChildArray"] objectAtIndex:5] objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeContent"];
	
	NSString *dateString = [[[node objectForKey:@"nodeChildArray"] objectAtIndex:6] objectForKey:@"nodeContent"];
	NSDate *date = [self parseDateWithString:dateString];
	
	NSString *from = [[[node objectForKey:@"nodeChildArray"] objectAtIndex:4] objectForKey:@"nodeContent"];
	
	MessageLite *msg = [[MessageLite alloc] initWithSubject:subject
													   From:from
													   Date:date
												  MessageId:msgId
												   IsUnread:unread];
	
	return msg;

}

-(NSArray*)getMessagesFrom:(NSString*)folderId {
	Folder *folder = [self getFolderById:folderId];
	
	NSString *xpathQueryString = @"//div[@class='cntnt']/table[@class='lvw']/tr";
	NSArray *nodes = [self performXPathQuery:xpathQueryString onUrl:folder.url];

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
	return [NSString stringWithFormat:@"?ae=Item&t=IPM.Note&id=%@", urlencode(messageId)];
}

-(Message*)getMessageFromId:(NSString*)messageId {
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
	
	NSArray *toNodes = PerformHTMLXPathQuery(responseData, @"//*[@id='divTo']/span");
	
	NSMutableArray *to = [[[NSMutableArray alloc] initWithCapacity:[toNodes count]] autorelease];
	
	for (NSDictionary *toDict in toNodes) {
		NSString* toName = nil;
		if ([toDict objectForKey:@"nodeChildArray"]) {
			toName = [[[toDict objectForKey:@"nodeChildArray"] objectAtIndex:0] objectForKey:@"nodeContent"];
		} else {
			toName = [toDict objectForKey:@"nodeContent"];
		}

		[to addObject:toName];
	}
	
	NSString *body = PerformHTMLXPathQueryAndReturnXml(responseData, @"//tr[2]/td/table[@class='w100']/tr[3]/td[@class='bdy']/div[@class='bdy']/div");
	
	Message* msg = [[[Message alloc] initWithSubject:subject
											   From:from
											 SentOn:sent
											   Body:body
											 SentTo:to
										  MessageId:messageId] autorelease];

	return msg;
}

-(void)markMessageUnread:(NSString*)messageId {
	NSString* canary = @"";
	for (NSHTTPCookie* cookie in cookies) {
		if ([cookie.name isEqualToString:@"UserContext"]) {
			canary = cookie.value;
			break;
		}
	}
	NSDictionary *data = [[[NSDictionary alloc] initWithObjectsAndKeys:
						  //[[self class] urlencode:messageId], @"chkmsg",
						  messageId, @"chkmsg",
						  @"", @"hidactbrfld",
						  @"", @"hidcid",
						  canary, @"hidcanary",
						  @"markunread", @"hidcmdpst",
						  @"MessageView", @"hidpid",
						  @"", @"hidpnst",
						  @"", @"hidso",
						  nil] autorelease];
	[self getContentFromUrl:[[self getFolderById:@"Inbox"] url] PostData:data];
}

-(void)markMessageRead:(NSString*)messageId {
	NSString* canary = @"";
	for (NSHTTPCookie* cookie in cookies) {
		if ([cookie.name isEqualToString:@"UserContext"]) {
			canary = cookie.value;
			break;
		}
	}
	NSDictionary *data = [[[NSDictionary alloc] initWithObjectsAndKeys:
						  messageId, @"chkmsg",
						  @"", @"hidactbrfld",
						  @"", @"hidcid",
						  canary, @"hidcanary",
						  @"markread", @"hidcmdpst",
						  @"MessageView", @"hidpid",
						  @"", @"hidpnst",
						  @"", @"hidso",
						  nil] autorelease];
	[self getContentFromUrl:[[self getFolderById:@"Inbox"] url] PostData:data];
}

-(void)deleteMessage:(NSString*)messageId {
	NSString* canary = @"";
	for (NSHTTPCookie* cookie in cookies) {
		if ([cookie.name isEqualToString:@"UserContext"]) {
			canary = cookie.value;
			break;
		}
	}
	NSDictionary *data = [[[NSDictionary alloc] initWithObjectsAndKeys:
						  messageId, @"chkmsg",
						  @"", @"hidactbrfld",
						  @"", @"hidcid",
						  canary, @"hidcanary",
						  @"delete", @"hidcmdpst",
						  @"MessageView", @"hidpid",
						  @"", @"hidpnst",
						  @"", @"hidso",
						  nil] autorelease];
	[self getContentFromUrl:@"?ae=Folder&t=IPF.Note&id=LgAAAADuXmIWgLhGTJrVVAih3RY%2bAQBIdpf9m55CSLeI2hw6Sj78AAAAJX1%2fAAAB&slUsng=0&pg=1" PostData:data];

}

+(NSString *) formattedDateRelativeToNow:(NSDate *)date
{
	NSDateFormatter *mdf = [[NSDateFormatter alloc] init];
	[mdf setDateFormat:@"yyyy-MM-dd"];
	NSDate *midnight = [mdf dateFromString:[mdf stringFromDate:date]];
	[mdf release];
	
	NSInteger dayDiff = (int)[midnight timeIntervalSinceNow] / (60*60*24);
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease]; 
	
	if(dayDiff == 0)
		[dateFormatter setDateFormat:@"'Today, 'h':'mm aaa"];
	else if(dayDiff == -1)
		[dateFormatter setDateFormat:@"'Yesterday, 'h':'mm aaa"];
	else if(dayDiff == -2)
		[dateFormatter setDateFormat:@"MMMM d', Two days ago'"];
	else if(dayDiff > -7 && dayDiff <= -2)
		[dateFormatter setDateFormat:@"MMMM d', This week'"];
	else if(dayDiff > -14 && dayDiff <= -7)
		[dateFormatter setDateFormat:@"MMMM d'; Last week'"];
	else if(dayDiff >= -60 && dayDiff <= -30)
		[dateFormatter setDateFormat:@"MMMM d'; Last month'"];
	else if(dayDiff >= -90 && dayDiff <= -60)
		[dateFormatter setDateFormat:@"MMMM d'; Within last three months'"];
	else if(dayDiff >= -180 && dayDiff <= -90)
		[dateFormatter setDateFormat:@"MMMM d'; Within last six months'"];
	else if(dayDiff >= -365 && dayDiff <= -180)
		[dateFormatter setDateFormat:@"MMMM d, YYYY'; Within this year'"];
	else if(dayDiff < -365)
		[dateFormatter setDateFormat:@"MMMM d, YYYY'; A long time ago'"];
	
	return [dateFormatter stringFromDate:date];
} 

-(void)dealloc {
	[username release];
	username = nil;
	[password release];
	password = nil;
	[baseUrl release];
	baseUrl = nil;
	[folders release];
	folders = nil;

	[super dealloc];
}


@end
