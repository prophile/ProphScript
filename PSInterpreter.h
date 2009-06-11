#import <Foundation/Foundation.h>
#import "PSParser.h"

@interface PSInterpreter : NSObject
{
	NSMutableArray* _symbolTable;
	NSMutableArray* _stack;
	NSUInteger _stackSize;
	PSASTNode* _block;
}
- (id)initWithBlock:(PSASTNode*)block;
- (void)run;
+ (void)runAST:(PSASTNode*)node;
- (void)declareBuiltin:(NSString*)name target:(id)target selector:(SEL)selector;
- (void)declareVarArgBuiltin:(NSString*)name target:(id)target selector:(SEL)selector;
@end
