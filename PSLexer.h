#import <Foundation/Foundation.h>

typedef enum _PSLexerToken
{
	PS_TOK_EOF,
	PS_TOK_FUNCTION,
	PS_TOK_IDENTIFIER,
	PS_TOK_STRING,
	PS_TOK_INTEGER,
	PS_TOK_OPEN_BRACKET,
	PS_TOK_CLOSE_BRACKET,
	PS_TOK_OPEN_BRACE,
	PS_TOK_CLOSE_BRACE,
	PS_TOK_IF,
	PS_TOK_ELSE,
	PS_TOK_WHILE,
	PS_TOK_RETURN,
	PS_TOK_SEMICOLON,
	PS_TOK_BINARY_OPERATOR,
	PS_TOK_UNARY_OPERATOR,
	PS_TOK_COMMA
} PSLexerToken;

@interface PSLexer : NSObject
{
	NSString* _source;
	NSScanner* _scanner;
	NSUInteger _unlexPosition;
	BOOL _closeBrace;
}
- (void)getSourceLine:(NSUInteger*)line column:(NSUInteger*)column;
- (id)initWithSource:(NSString*)src;
- (NSString*)lex:(PSLexerToken)tok;
- (void)unlex;
- (BOOL)hadCloseBrace;
@end
