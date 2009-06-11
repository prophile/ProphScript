#import <Foundation/Foundation.h>
#import "PSLexer.h"

@interface PSASTNode : NSObject
{
	NSString* _type;
	NSString* _data;
	NSMutableArray* _children;
}
- (id)initWithType:(NSString*)type;
- (void)setData:(NSString*)data;
- (NSString*)data;
- (void)addChild:(PSASTNode*)addChild;
- (NSString*)type;
- (NSArray*)children;
- (void)print;
@end

@interface PSParser : NSObject
{
	PSLexer* _lexer;
}
- (id)initWithLexer:(PSLexer*)lexer;
- (PSASTNode*)parseOpenBlock;
- (PSASTNode*)parseBlock;
- (PSASTNode*)parseVariable;
- (PSASTNode*)parseString;
- (PSASTNode*)parseFunction;
- (PSASTNode*)parseStatement;
- (PSASTNode*)parseExpression;
- (PSASTNode*)parseInteger;
- (PSASTNode*)parseValue;
- (void)parseError:(NSString*)error;
@end