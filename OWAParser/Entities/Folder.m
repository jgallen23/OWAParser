
#import "Folder.h"

@implementation Folder

@synthesize name;
@synthesize url;
@synthesize unreadCount;

-(id)init {
	if (self=[super init]) {
	}
	
	return self;
}

-(id)initWithName:(NSString*)aName URL:(NSString*)aUrl UnreadCount:(NSInteger)aUnreadCount {
	if (self=[super init]) {
		self.name = aName;
		self.url = aUrl;
		self.unreadCount = aUnreadCount;
	}
	
	return self;
}

-(NSString*)description {
	return [NSString stringWithFormat:@"%@ (%d) [%@]", self.name, self.unreadCount, self.url];
}

- (void)dealloc
{
	[name release];
	name = nil;
	[url release];
	url = nil;

	[super dealloc];
}

@end