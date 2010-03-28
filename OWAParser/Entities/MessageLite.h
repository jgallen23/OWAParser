

@interface MessageLite : NSObject {
	NSString* subject;
	NSString* from;
	BOOL isUnread;
	NSDate* date;
	NSString* messageId;
}

@property (nonatomic, copy) NSString *subject;
@property (nonatomic, copy) NSString *from;
@property (nonatomic, assign) BOOL isUnread;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, copy) NSString *messageId;

-(id)init;
-(id)initWithSubject:(NSString *)aSubject From:(NSString *)aFrom Date:(NSDate *)aDate MessageId:(NSString *)aMessageId IsUnread:(BOOL)unread;

@end