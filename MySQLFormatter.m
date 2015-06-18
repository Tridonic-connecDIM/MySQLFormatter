//
//  MySQLFormatter.m
//  Objective-C_JSONParser
//
//  Created by Carlo Tortorella on 5/08/2014.
//  Copyright (c) 2014 DALI Lighting Pty Ltd. All rights reserved.
//

#import "MySQLFormatter.h"
#import "Functions.h"

#define USE_ARC NO

@implementation MySQLFormatter

- (NSString *)format:(NSString *)format arguments:(va_list)arguments
{
    _formatBuffer = format;
    _formatLength = [format length];
    _cursor = 0;
    
    _outputBuffer = NULL;
    _outputBufferCursor = 0;
    _outputBufferLength = 0;
    
    int c;
    while((c = [self read]) >= 0)
    {
        if (c != '%')
        {
            [self write:c];
        }
        else
        {
            int next = [self read];
            if (next == 'd' || next == 'i')
            {
                int value = va_arg(arguments, int);
                [self write:'\''];
                [self writeLongLong:value];
                [self write:'\''];
            }
            else if (next == 'u')
            {
                unsigned value = va_arg(arguments, unsigned);
                [self write:'\''];
                [self writeUnsignedLongLong:value];
                [self write:'\''];
            }
            else if (next == 'l')
            {
                next = [self read];
                if (next == 'd' || next == 'i')
                {
                    long value = va_arg(arguments, long);
                    [self write:'\''];
                    [self writeLongLong:value];
                    [self write:'\''];
                }
                else if (next == 'u')
                {
                    unsigned long value = va_arg(arguments, unsigned long);
                    [self write:'\''];
                    [self writeUnsignedLongLong:value];
                    [self write:'\''];
                }
                else if (next == 'x' || next == 'X')
                {
                    uint8_t state = next - 'x';
                    [self write:'\''];
                    long value = va_arg(arguments, long);
                    [self writeHexLongLong:value capitalised:state];
                    [self write:'\''];
                }
                else if (next == 'l')
                {
                    next = [self read];
                    if (next == 'd' || next == 'i')
                    {
                        long long value = va_arg(arguments, long long);
                        [self write:'\''];
                        [self writeLongLong:value];
                        [self write:'\''];
                    }
                    else if (next == 'u')
                    {
                        unsigned long long value = va_arg(arguments, unsigned long long);
                        [self write:'\''];
                        [self writeUnsignedLongLong:value];
                        [self write:'\''];
                    }
                    else if (next == 'x' || next == 'X')
                    {
                        uint8_t state = next - 'x';
                        [self write:'\''];
                        long long value = va_arg(arguments, long long);
                        [self writeHexLongLong:value capitalised:state];
                        [self write:'\''];
                    }
                }
            }
            else if (next == 'f')
            {
                double value = va_arg(arguments, double);
                [self write:'\''];
                [self writeDouble:value];
                [self write:'\''];
            }
            else if (next == 'x' || next == 'X')
            {
                uint8_t state = next - 'x';
                [self write:'\''];
                int value = va_arg(arguments, int);
                [self writeHexLongLong:value capitalised:state];
                [self write:'\''];
            }
            else if (next == 's')
            {
                const char *value = va_arg(arguments, const char *);
                [self write:'\''];
                while(*value)
                {
                    if (*value != '\'')
                    {
                        [self write:*value];
                    }
                    else
                    {
                        [self write:'\\'];
                        [self write:'\''];
                    }
                    ++value;
                }
                [self write:'\''];
            }
            else if (next == '@')
            {
                id object = va_arg(arguments, id);
                NSString * description = @"NULL";
                NSUInteger length = [description length];
                
                if (object)
                {
                    description = [self sanitiseObject:object];
                    length = [description length];
                }
                while(length > _outputBufferLength - _outputBufferCursor)
                    [self doubleOutputBuffer];
                
                [description getCharacters:_outputBuffer + _outputBufferCursor range:NSMakeRange(0, length)];
                _outputBufferCursor += length;
            }
            else if (next == '%')
            {
                [self write:'%'];
            }
        }
    }
    
    NSString *output = [[NSString alloc] initWithCharactersNoCopy:_outputBuffer length:_outputBufferCursor freeWhenDone:YES];
	
#if !(__has_feature(objc_arc))
	return output.autorelease;
#endif
	return output;
	
}

- (void)writeLongLong:(long long)value
{
    unsigned long long unsignedValue = value;
    if (value < 0)
    {
        [self write:'-'];
        unsignedValue = -value;
    }
    [self writeUnsignedLongLong:unsignedValue];
}

- (void)writeUnsignedLongLong:(unsigned long long)value
{
    unsigned long long cursor = 1;
    while(value / cursor >= 10)
        cursor *= 10;
    
    while(cursor > 0)
    {
        uint64_t digit = value / cursor;
        [self write:'0' + digit];
        value -= digit * cursor;
        cursor /= 10;
    }
}

- (void)writeHexLongLong:(long long)value capitalised:(uint8_t)caps
{
    unsigned long long unsignedValue = value;
    if (value < 0)
    {
        [self write:'-'];
        unsignedValue = llabs(value);
    }
    [self writeHexUnsignedLongLong:unsignedValue capitalised:caps];
}

- (void)writeHexUnsignedLongLong:(unsigned long long)value capitalised:(uint8_t)caps
{
    caps = caps ? 'A' - 'a' :0;
    char hex[] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a' + caps, 'b' + caps, 'c' + caps, 'd' + caps, 'e' + caps, 'f' + caps};
    int foundHighestSignificantByte = 0;
    if (value)
    {
        for (long i = sizeof(value) - 1; i >= 0; --i)
        {
            uint8_t byte = (value >> (i * 8)) & 0xFF;
            if (!foundHighestSignificantByte && byte)
            {
                foundHighestSignificantByte = 1;
                if (byte >> 4)
                {
                    [self write:hex[byte >> 4]];
                    [self write:hex[byte & 0xF]];
                }
                else
                {
                    [self write:hex[byte & 0xF]];
                }
            }
            else if (foundHighestSignificantByte)
            {
                [self write:hex[byte >> 4]];
                [self write:hex[byte & 0xF]];
            }
        }
    }
    else
    {
        [self write:'0'];
    }
}

- (void)writeDouble:(double)value
{
    if (value < 0.0)
    {
        [self write:'-'];
        value = -value;
    }
    
    if (isinf(value) || isnan(value))
    {
        const char *str = isinf(value) ? "INFINITY" :"NaN";
        while(*str)
		{
            [self write:*str++];
		}
        return;
    }
    
    double intpart = trunc(value);
    double fracpart = value - intpart;
    
    [self writeDoubleIntPart:intpart];
    [self write:'.'];
    [self writeDoubleFracPart:fracpart];
}

- (void)writeDoubleIntPart:(double)intpart
{
    unsigned long long total = 0;
    unsigned long long currentBit = 1;
    
    unsigned long long maxValue = [self ullongMaxPowerOf10] / 10;
    
    unsigned surplusZeroes = 0;
    
    while(intpart)
    {
        intpart /= 2;
        if (fmod(intpart, 1.0))
        {
            total += currentBit;
            intpart = trunc(intpart);
        }
        currentBit *= 2;
        if (currentBit > maxValue)
        {
            total = (total + 5) / 10;
            currentBit = (currentBit + 5) / 10;
            surplusZeroes++;
        }
    }
    
    [self writeUnsignedLongLong:total];
    for(unsigned i = 0; i < surplusZeroes; i++)
        [self write:'0'];
}

- (void)writeDoubleFracPart:(double)fracpart
{
    unsigned long long total = 0;
    unsigned long long currentBit = [self ullongMaxPowerOf10];
    unsigned long long shiftThreshold = [self ullongMaxPowerOf10] / 10;
    
    while(fracpart)
    {
        currentBit /= 2;
        fracpart *= 2;
        if (fracpart >= 1.0)
        {
            total += currentBit;
            fracpart -= 1.0;
        }
        
        if (currentBit <= shiftThreshold && total <= shiftThreshold)
        {
            [self write:'0'];
            currentBit *= 10;
            total *= 10;
        }
    }
    
    while(total != 0 && total % 10 == 0)
	{
        total /= 10;
	}
	
    [self writeUnsignedLongLong:total];
}

- (unsigned long long)ullongMaxPowerOf10
{
    unsigned long long result = 1;
    while(ULLONG_MAX / result >= 10)
        result *= 10;
    return result;
}

- (int)read
{
    if (_cursor < _formatLength)
	{
        return [_formatBuffer characterAtIndex:_cursor++];
	}
	return -1;
}

- (void)write:(unichar)c
{
    if (_outputBufferCursor >= _outputBufferLength)
	{
        [self doubleOutputBuffer];
	}
	
    _outputBuffer[_outputBufferCursor++] = c;
}

- (void)doubleOutputBuffer
{
    if (_outputBufferLength == 0)
	{
        _outputBufferLength = 64;
	}
    else
	{
        _outputBufferLength *= 2;
	}
    _outputBuffer = realloc(_outputBuffer, _outputBufferLength * sizeof(unichar));
}

- (NSString *)sanitiseObject:(id)object
{
    if ([object isKindOfClass:[NSArray class]])
    {
        return [NSString stringWithFormat:@"'%@'", [object componentsJoinedByString:@","]];
    }
    else if ([object isKindOfClass:[NSDictionary class]])
    {
        NSMutableArray * array = [NSMutableArray array];
        for (id key in object)
        {
            [array addObject:[NSString stringWithFormat:@"`%@`=%@", key, [self sanitiseObject:[object objectForKey:key]]]];
        }
        return [array componentsJoinedByString:@", "];
    }
    else if ([object isKindOfClass:[NSString class]])
    {
        return [NSString stringWithFormat:@"'%@'", [object stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]];
    }
    else if ([object isKindOfClass:[NSDate class]])
    {
        return [NSString stringWithFormat:@"'%@'", [[object description] substringToIndex:19]];
    }
    else
    {
        return [NSString stringWithFormat:@"'%@'", [object description]];
    }
}

@end
