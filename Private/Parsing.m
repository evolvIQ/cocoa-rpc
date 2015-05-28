#import "Parsing.h"
#import "XMLRPCRequest.h"
#import "XMLRPCResponse.h"

static NSOperationQueue* parsingQueue;

@implementation Parsing


+(NSOperationQueue*) queue {
    if(!parsingQueue) parsingQueue = [NSOperationQueue new];
    return parsingQueue;
}

+(XMLRPCResponse*) parseXMLRPCResponseFromData:(NSData*)data {
    return [[XMLRPCResponse alloc] initWithData: data];
}
+(XMLRPCRequest*) parseXMLRPCRequestFromData:(NSData*)data {
    return nil;
}
+(void) parseXMLRPCResponseAsyncFromData:(NSData*)data withCompletion:(void(^)(XMLRPCResponse*))completion {
    [[Parsing queue] addOperation: [NSBlockOperation blockOperationWithBlock:^{
        XMLRPCResponse* response = [Parsing parseXMLRPCResponseFromData:data];

        [[NSOperationQueue mainQueue] addOperation: [NSBlockOperation blockOperationWithBlock:^{
            completion(response);
        }]];
    }]];
}
+(void) parseXMLRPCRequestAsyncFromData:(NSData*)data withCompletion:(void(^)(XMLRPCRequest*))completion {
    [[Parsing queue] addOperation: [NSBlockOperation blockOperationWithBlock:^{
        XMLRPCRequest* request = [Parsing parseXMLRPCRequestFromData:data];

        [[NSOperationQueue mainQueue] addOperation: [NSBlockOperation blockOperationWithBlock:^{
            completion(request);
        }]];
    }]];
}
@end
