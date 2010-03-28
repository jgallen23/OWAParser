
@interface Message : NSObject {
	NSString* subject;
	NSString* from;
	NSString* sentOn;
	NSString* messageId;
	NSArray* sentTo;
	NSString* body;
	
}

@property (nonatomic, copy) NSString *subject;
@property (nonatomic, copy) NSString *from;
@property (nonatomic, copy) NSString *sentOn;
@property (nonatomic, copy) NSString *messageId;
@property (nonatomic, copy) NSArray *sentTo;
@property (nonatomic, copy) NSString *body;



-(id)init;
-(id)initWithSubject:(NSString *)aSubject From:(NSString *)aFrom SentOn:(NSString *)aSentOn Body:(NSString *)aBody SentTo:(NSArray *)aSentTo MessageId:(NSString *)aMessageId;

@end
