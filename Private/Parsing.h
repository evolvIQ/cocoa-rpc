#import <Foundation/Foundation.h>

@class XMLRPCRequest, XMLRPCResponse;

@interface Parsing : NSObject
+(NSOperationQueue*) queue;
+(XMLRPCResponse*) parseXMLRPCResponseFromData:(NSData*)data;
+(XMLRPCRequest*) parseXMLRPCRequestFromData:(NSData*)data;
+(void) parseXMLRPCResponseAsyncFromData:(NSData*)data withCompletion:(void(^)(XMLRPCResponse*))completion;
+(void) parseXMLRPCRequestAsyncFromData:(NSData*)data withCompletion:(void(^)(XMLRPCRequest*))completion;
@end
