
#import "MessageLite.h"

@implementation MessageLite

@synthesize subject;
@synthesize from;
@synthesize isUnread;
@synthesize date;
@synthesize messageId;


-(id)init {
	if (self=[super init]) {
	}
	
	return self;
}

-(id)initWithSubject:(NSString*)aSubject From:(NSString*)aFrom Date:(NSDate*)aDate MessageId:(NSString*)aMessageId IsUnread:(BOOL)unread {
	if (self=[super init]) {
		
		self.subject = aSubject;
		self.from = aFrom;
		self.date = aDate;
		self.messageId = aMessageId;
		self.isUnread = unread;
		
	}
	
	return self;
}

-(NSString*)description {
	return [NSString stringWithFormat:@"%@: %@ on %@", self.from, self.subject, self.date];
}

- (void)dealloc
{
	[subject release];
	subject = nil;
	[from release];
	from = nil;
	[date release];
	date = nil;
	[messageId release];
	messageId = nil;

	[super dealloc];
}

@end