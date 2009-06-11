#import <Foundation/Foundation.h>

@interface PSStandardLibrary : NSObject
{
}
- (id)add:(id)a and:(id)b;
- (id)sub:(id)a and:(id)b;
- (id)mul:(id)a and:(id)b;
- (id)div:(id)a and:(id)b;
- (id)is:(id)a equalTo:(id)b;
- (id)is:(id)a notEqualTo:(id)b;
- (id)is:(id)a lessThan:(id)b;
- (id)is:(id)a greaterThan:(id)b;
- (id)is:(id)a lessThanOrEqualTo:(id)b;
- (id)is:(id)a greaterThanOrEqualTo:(id)b;
- (id)negative:(id)a;
- (id)print:(NSArray*)input;
@end
