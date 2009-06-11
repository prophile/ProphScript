#import "PSStandardLibrary.h"

@implementation PSStandardLibrary
- (id)add:(id)a and:(id)b
{
	if ([a isKindOfClass:[NSNumber class]] && [b isKindOfClass:[NSNumber class]])
	{
		NSDecimal r1, r2, result;
		r1 = [a decimalValue];
		r2 = [b decimalValue];
		NSDecimalAdd(&result, &r1, &r2, NSRoundBankers);
		return [NSDecimalNumber decimalNumberWithDecimal:result];
	}
	else if ([a isKindOfClass:[NSString class]] && [b isKindOfClass:[NSString class]])
	{
		return [a stringByAppendingString:b];
	}
	else if ([a isKindOfClass:[NSSet class]] && [b isKindOfClass:[NSSet class]])
	{
		NSMutableSet* newSet = [NSMutableSet setWithSet:a];
		[newSet unionSet:b];
		return [NSSet setWithSet:newSet];
	}
	else if ([a isKindOfClass:[NSArray class]] && [b isKindOfClass:[NSArray class]])
	{
		return [a arrayByAddingObjectsFromArray:b];
	}
	else if ([a isKindOfClass:[NSDictionary class]] && [b isKindOfClass:[NSDictionary class]])
	{
		NSMutableDictionary* md = [NSMutableDictionary dictionaryWithDictionary:a];
		[md addEntriesFromDictionary:b];
		return [NSDictionary dictionaryWithDictionary:md];
	}
	return nil;
}

- (id)sub:(id)a and:(id)b
{
	if ([a isKindOfClass:[NSNumber class]] && [b isKindOfClass:[NSNumber class]])
	{
		NSDecimal r1, r2, result;
		r1 = [a decimalValue];
		r2 = [b decimalValue];
		NSDecimalSubtract(&result, &r1, &r2, NSRoundBankers);
		return [NSDecimalNumber decimalNumberWithDecimal:result];
	}
	else if ([a isKindOfClass:[NSSet class]] && [b isKindOfClass:[NSSet class]])
	{
		NSMutableSet* newSet = [NSMutableSet setWithSet:a];
		[newSet minusSet:b];
		return [NSSet setWithSet:newSet];
	}
	else if ([a isKindOfClass:[NSDictionary class]] && [b isKindOfClass:[NSDictionary class]])
	{
		NSMutableDictionary* md = [NSMutableDictionary dictionaryWithDictionary:a];
		id key;
		for (key in b)
		{
			[md removeObjectForKey:b];
		}
		return [NSDictionary dictionaryWithDictionary:md];
	}
	return nil;
}

- (id)mul:(id)a and:(id)b
{
	if ([a isKindOfClass:[NSNumber class]] && [b isKindOfClass:[NSNumber class]])
	{
		NSDecimal r1, r2, result;
		r1 = [a decimalValue];
		r2 = [b decimalValue];
		NSDecimalMultiply(&result, &r1, &r2, NSRoundBankers);
		return [NSDecimalNumber decimalNumberWithDecimal:result];
	}
	else if ([a isKindOfClass:[NSSet class]] && [b isKindOfClass:[NSSet class]])
	{
		NSMutableSet* newSet = [NSMutableSet setWithSet:a];
		[newSet intersectSet:b];
		return [NSSet setWithSet:newSet];
	}
	return nil;
}

- (id)div:(id)a and:(id)b
{
	if ([a isKindOfClass:[NSNumber class]] && [b isKindOfClass:[NSNumber class]])
	{
		NSDecimal r1, r2, result;
		r1 = [a decimalValue];
		r2 = [b decimalValue];
		NSDecimalDivide(&result, &r1, &r2, NSRoundBankers);
		return [NSDecimalNumber decimalNumberWithDecimal:result];
	}
	return nil;
}

- (id)negative:(id)a
{
	if ([a isKindOfClass:[NSNumber class]])
	{
		NSDecimal r1, r2, result;
		r1 = [a decimalValue];
		memset(&r2, 0, sizeof(r2));
		NSDecimalSubtract(&result, &r2, &r1, NSRoundBankers);
		return [NSDecimalNumber decimalNumberWithDecimal:result];
	}
	return nil;
}

- (int)compare:(id)a and:(id)b
{
	if ([a respondsToSelector:@selector(compare:)])
	{
		int result = [a compare:b];
		if (result < 0) result = -1;
		if (result > 0) result = 1;
		return result;
	}
	else
	{
		int hashA = [a hash];
		int hashB = [b hash];
		if (hashA > hashB) return 1;
		else if (hashA < hashB) return -1;
		else return 0;
	}
}

- (id)is:(id)a equalTo:(id)b
{
	int cmp = [self compare:a and:b];
	return [NSNumber numberWithBool:cmp == 0];
}

- (id)is:(id)a notEqualTo:(id)b
{
	int cmp = [self compare:a and:b];
	return [NSNumber numberWithBool:cmp != 0];
}

- (id)is:(id)a lessThan:(id)b
{
	int cmp = [self compare:a and:b];
	return [NSNumber numberWithBool:cmp == -1];
}

- (id)is:(id)a greaterThan:(id)b
{
	int cmp = [self compare:a and:b];
	return [NSNumber numberWithBool:cmp == 1];
}

- (id)is:(id)a lessThanOrEqualTo:(id)b
{
	int cmp = [self compare:a and:b];
	return [NSNumber numberWithBool:cmp == -1 || cmp == 0];
}

- (id)is:(id)a greaterThanOrEqualTo:(id)b
{
	int cmp = [self compare:a and:b];
	return [NSNumber numberWithBool:cmp == 1 || cmp == 0];
}

- (id)print:(NSArray*)input
{
	id entry;
	NSFileHandle* standardOut = [NSFileHandle fileHandleWithStandardOutput];
	for (entry in input)
	{
		NSString* out = [entry description];
		[standardOut writeData:[out dataUsingEncoding:NSUTF8StringEncoding]];
	}
	return nil;
}
@end
