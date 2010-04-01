
#import "Message.h"

@implementation Message

@synthesize subject;
@synthesize from;
@synthesize sentOn;
@synthesize messageId;
@synthesize sentTo;
@synthesize body;

-(id)init {
	if (self=[super init]) {
	}
	
	return self;
}

-(id)initWithSubject:(NSString*)aSubject From:(NSString*)aFrom SentOn:(NSString*)aSentOn Body:(NSString*)aBody SentTo:(NSArray*)aSentTo MessageId:(NSString*)aMessageId  {
	if (self=[super init]) {
		
		self.subject = aSubject;
		self.from = aFrom;
		self.sentOn = aSentOn;
		self.messageId = aMessageId;
		self.body = aBody;
		self.sentTo = aSentTo;
		
	}
	
	return self;
}

-(NSString*)description {
	return [NSString stringWithFormat:@"%@: %@ on %@", self.from, self.subject, self.sentOn];
}

- (void)dealloc
{
	[subject release];
	subject = nil;
	[from release];
	from = nil;
	[sentOn release];
	sentOn = nil;
	[messageId release];
	messageId = nil;
	[sentTo release];
	sentTo = nil;
	[body release];
	body = nil;

	[super dealloc];
}

@end