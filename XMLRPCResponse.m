#import "XMLRPCResponse.h"
#import "XMLRPCEventBasedParser.h"

@interface XMLRPCResponse () {
    NSString *myBody;
    id myObject;
    BOOL isFault;
}
@end

@implementation XMLRPCResponse

- (id)initWithData: (NSData *)data {
    if (!data) {
        return nil;
    }

    if (self = [super init]) {
        XMLRPCEventBasedParser *parser = [[XMLRPCEventBasedParser alloc] initWithData: data];
        
        if (!parser) {
            
            return nil;
        }
    
        myBody = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        myObject = [parser parse];
        
        isFault = [parser isFault];
        
    }
    
    return self;
}

#pragma mark -

- (BOOL)isFault {
    return isFault;
}

- (NSNumber *)faultCode {
    if (isFault) {
        return [myObject objectForKey: @"faultCode"];
    }
    
    return nil;
}

- (NSString *)faultString {
    if (isFault) {
        return [myObject objectForKey: @"faultString"];
    }
    
    return nil;
}

#pragma mark -

- (id)object {
    return myObject;
}

#pragma mark -

- (NSString *)body {
    return myBody;
}

#pragma mark -

- (NSString *)description {
	NSMutableString	*result = [NSMutableString stringWithCapacity:128];
    
	[result appendFormat:@"[body=%@", myBody];
    
	if (isFault) {
		[result appendFormat:@", fault[%@]='%@'", [self faultCode], [self faultString]];
	} else {
		[result appendFormat:@", object=%@", myObject];
	}
    
	[result appendString:@"]"];
    
	return result;
}

#pragma mark -


@end
