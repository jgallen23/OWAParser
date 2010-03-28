

@interface Folder : NSObject {
	NSString* name;
	NSString* url;
	NSInteger unreadCount;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) NSInteger unreadCount;


-(id)initWithName:(NSString *)aName URL:(NSString *)aUrl UnreadCount:(NSInteger)aUnreadCount;
@end