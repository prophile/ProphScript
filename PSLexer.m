#import "PSLexer.h"

@implementation PSLexer
- (void)getSourceLine:(NSUInteger*)line column:(NSUInteger*)column
{
	NSUInteger location = [_scanner scanLocation];
	NSUInteger l = 1, c = 1;
	NSUInteger i = 0;
	for (i = 0; i < location; i++)
	{
		unichar loc = [_source characterAtIndex:i];
		if (loc == '\n')
		{
			l++;
			c = 1;
		}
		else
		{
			c++;
		}
	}
	*line = l;
	*column = c;
}

- (id)initWithSource:(NSString*)src
{
	id s = [super init];
	if (s == self)
	{
		_source = [src copy];
		_unlexPosition = 0;
		_scanner = [[NSScanner alloc] initWithString:_source];
		[_scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	return s;
}

- (void)dealloc
{
	[_scanner release];
	[_source release];
	[super dealloc];
}

- (BOOL)hadCloseBrace
{
	return _closeBrace;
}

- (NSString*)lex:(PSLexerToken)tok
{
	NSUInteger newUnlexPosition = [_scanner scanLocation];
	NSString* lexedValue = nil;
	
	while ([_scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"#"] intoString:NULL])
		[_scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
	
	switch (tok)
	{
		case PS_TOK_STRING:
			{
				NSString* start;
				if ([_scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""] intoString:&start])
				{
					[_scanner scanUpToString:start intoString:&lexedValue];
					[_scanner scanString:start intoString:NULL];
				}
			}
			break;
		case PS_TOK_FUNCTION:
			[_scanner scanString:@"function" intoString:&lexedValue];
			break;
		case PS_TOK_IDENTIFIER:
			[_scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_1234567890"] intoString:&lexedValue];
			break;
		case PS_TOK_COMMA:
			[_scanner scanString:@"," intoString:&lexedValue];
			break;
		case PS_TOK_OPEN_BRACE:
			[_scanner scanString:@"{" intoString:&lexedValue];
			break;
		case PS_TOK_CLOSE_BRACE:
			[_scanner scanString:@"}" intoString:&lexedValue];
			break;
		case PS_TOK_OPEN_BRACKET:
			[_scanner scanString:@"(" intoString:&lexedValue];
			break;
		case PS_TOK_CLOSE_BRACKET:
			[_scanner scanString:@")" intoString:&lexedValue];
			break;
		case PS_TOK_IF:
			[_scanner scanString:@"if" intoString:&lexedValue];
			break;
		case PS_TOK_ELSE:
			[_scanner scanString:@"else" intoString:&lexedValue];
			break;
		case PS_TOK_WHILE:
			[_scanner scanString:@"while" intoString:&lexedValue];
			break;
		case PS_TOK_RETURN:
			[_scanner scanString:@"return" intoString:&lexedValue];
			break;
		case PS_TOK_SEMICOLON:
			[_scanner scanString:@";" intoString:&lexedValue];
			break;
		case PS_TOK_BINARY_OPERATOR:
			if (![_scanner scanString:@"==" intoString:&lexedValue])
			if (![_scanner scanString:@"=" intoString:&lexedValue])
			if (![_scanner scanString:@"~=" intoString:&lexedValue])
			if (![_scanner scanString:@">=" intoString:&lexedValue])
			if (![_scanner scanString:@"<=" intoString:&lexedValue])
			if (![_scanner scanString:@">" intoString:&lexedValue])
			if (![_scanner scanString:@"<" intoString:&lexedValue])
			if (![_scanner scanString:@"+" intoString:&lexedValue])
			if (![_scanner scanString:@"-" intoString:&lexedValue])
			if (![_scanner scanString:@"*" intoString:&lexedValue])
			if (![_scanner scanString:@"/" intoString:&lexedValue])
			if (![_scanner scanString:@"and" intoString:&lexedValue])
			if (![_scanner scanString:@"or" intoString:&lexedValue])
			if (![_scanner scanString:@"xor" intoString:&lexedValue])
				lexedValue = nil;
			break;
		case PS_TOK_UNARY_OPERATOR:
			if (![_scanner scanString:@"not" intoString:&lexedValue])
			if (![_scanner scanString:@"~" intoString:&lexedValue])
				lexedValue = nil;
			break;
		case PS_TOK_INTEGER:
			{
				NSInteger v;
				if ([_scanner scanInteger:&v])
				{
					lexedValue = [NSString stringWithFormat:@"%d", v];
				}
			}
			break;
		case PS_TOK_EOF:
			if ([_scanner isAtEnd])
				lexedValue = @"";
			break;
	}
	
	if (lexedValue)
	{
		_unlexPosition = newUnlexPosition;
		_closeBrace = tok == PS_TOK_CLOSE_BRACE;
		return lexedValue;
	}
	else
	{
		[_scanner setScanLocation:newUnlexPosition];
		return nil;
	}
}

- (void)unlex
{
	[_scanner setScanLocation:_unlexPosition];
}
@end
