//
//  XMLRPCHTTPTransport.h
//  XMLRPC
//
//  Created by Rickard Lyrenius on 28/05/15.
//
//

#import "XMLRPCClient.h"

@interface XMLRPCClientHTTPTransport : NSObject <XMLRPCClientTransport>
- (id) initWithURL:(NSURL*)url;
@property (nonatomic, retain) NSString* userAgent;
@end
