//
//  OWAParser.m
//  OWAParser
//
//  Created by JGA on 2/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OWAParser.h"

@implementation OWAParser

-(id)init {
	if (self=[super init]) {
	}
	
	return self;
}

-(id)initWithURL:(NSString*)aUrl login:(NSString*)aLogin password:(NSString*)aPassword {
	if (self=[super init]) {
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
	return [NSString stringWithFormat:@"https://%@:%@@%@/", login, password, baseUrl];
}

-(NSData*)getContentFromUrl:(NSString*)aUrl {
	NSString *builtUrl = [NSString stringWithFormat:@"%@%@", [self getBaseUrl], aUrl];
	
	NSMutableURLRequest * theRequest=(NSMutableURLRequest*)[NSMutableURLRequest requestWithURL:[NSURL URLWithString:builtUrl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	
	NSHTTPURLResponse *response = nil;
	
	NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:nil];
	return data;
}

-(NSArray*)performXPathQuery:(NSString*)query onUrl:(NSString*)aUrl {
	NSData *responseData = [self getContentFromUrl:aUrl];
	//NSLog(@"%@", responseData);
	NSError *error;
    NSXMLDocument *document =
	[[NSXMLDocument alloc] initWithData:responseData options:NSXMLDocumentTidyHTML error:&error];
    
    // Deliberately ignore the error: with most HTML it will be filled with
    // numerous "tidy" warnings.
    
    NSXMLElement *rootNode = [document rootElement];
    
    
    NSArray *newItemsNodes = [rootNode nodesForXPath:query error:&error];
    if (error)
    {
		NSLog(@"%@", error);
    }	
	
	return newItemsNodes;
}

-(BOOL)isAuthenticated {
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


-(NSDictionary*)parseFolderNode:(NSXMLElement*)node {
	NSXMLElement *hrefNode = (NSXMLElement*)[[node childAtIndex:0] childAtIndex:0];
	
	NSDictionary *folder = [[NSDictionary alloc] initWithObjectsAndKeys:
							[[node stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], @"name",
							[hrefNode stringValue], @"id",
							[[hrefNode attributeForName:@"href"] stringValue], @"url",
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
		NSXMLElement *elem = [nodes objectAtIndex:0];
		NSString *spanTag = [elem stringValue];
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

-(NSDictionary*)parseMessageNode:(NSXMLElement*)node {
	NSNumber *unread = [NSNumber numberWithBool:([node attributes])?YES:NO];
	NSString *msgId = [[(NSXMLElement*)[[node childAtIndex:3] childAtIndex:0] attributeForName:@"value"] stringValue];
	NSXMLNode *subjectNode = [[[node childAtIndex:5] childAtIndex:0] childAtIndex:0];
	NSString *subject = [subjectNode stringValue];
	NSString *dateString = [[node childAtIndex:6] stringValue];
	NSDate *date = [self parseDateWithString:dateString];
	NSDictionary *msg = [[NSDictionary alloc] initWithObjectsAndKeys:
						  unread, @"unread",
						 [[node childAtIndex:4] stringValue], @"from",
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
	return [NSString stringWithFormat:@"%@?ae=Item&t=IPM.Note&id=%@", [self getBaseUrl], [[self class] urlencode:messageId]];
}


@end
