#include <stdio.h>

#define putChar(v) putchar(v)

#define True 1
#define False 0
// define the maximum int to be not a number(int)
#define NaN 0x7FFFFFFF

int getNextOffset(char *line, int offset)
{
    while (line[offset] != '\0' && line[offset] != ' ')
    {
        offset = offset + 1;
    }
    // return the position of next valid char or a value larger than the size
    return offset + 1;
}


int getInt2(char *numStr, int len)
{
    int i = 0;
    int result = 0;
    int negative = False;
    int c = numStr[i];
    if (c == '-')
    {
        negative = True;
        i = i + 1;
    }
    while (i < len)
    {
        c = numStr[i];
        if (c >= '0' && c <= '9')
        {
            result = result * 10 + (c - '0');
            i = i + 1;
        }
        else
        {
            return NaN;
        }
    }
    if (i == 0)
    {
        return NaN;
    }
    if (negative)
    {
        if (i == 1)
        {
            return NaN;
        }
        result = result * -1;
    }
    return result;
}

// return the int value or NaN, need to calculate offset separately
int getInt(char *line, int offset)
{
    int len = getNextOffset(line, offset) - offset - 1;
    return getInt2(line + offset, len);
}

void putStr(const char *s)
{
    int i = 0;
    while (s[i] != '\0')
    {
        putChar(s[i]);
        i = i + 1;
    }
    return;
}

void putInt(int num)
{
    if (num == NaN)
    {
        putStr("NaN");
        return;
    }
    if (num == 0)
    {
        putChar('0');
        return;
    }
    if (num < 0)
    {
        putChar('-');
        num = num * -1;
    }
    int i = 0;
    char bits[10] = {0};
    while (num != 0)
    {
        bits[i] = (num % 10) + '0';
        num = num / 10;
        i = i + 1;
    }
    while (i != 0)
    {
        i = i - 1;
        putChar(bits[i]);
    }
    return;
}


// poiority: low to high
// +  -  *  /  ()
enum operatorPoriorities
{
    pAdd,
    pSubract = pAdd,
    pMultiply,
    pDevide = pMultiply,
    pBracket
};

enum operators
{
    opAdd,
    opSubract,
    opMultiply,
    opDevide,
    opBracket
};

// input expression is the pointer to the expression,
// no input offset is taken
int evalExpression2(char *expression, int len)
{
    // find next operator
    int bracketCnt = 0;
    int i = 0;
    int lowestPriority = NaN;
    int operator;
    int lowPPosition;
    int c;
    while (i < len)
    {
        c = expression[i];
        if (c == '(')
        {
            if (lowestPriority > pBracket)
            {
                lowestPriority = pBracket;
                operator= opBracket;
                lowPPosition = i;
            }
            bracketCnt = bracketCnt + 1;
            i = i + 1;
            continue;
        }
        if (c == ')')
        {
            bracketCnt = bracketCnt - 1;
            i = i + 1;
            continue;
        }
        if (bracketCnt != 0)
        {
            i = i + 1;
            continue;
        }
        else if (c == '+')
        {
            if (lowestPriority > pAdd)
            {
                lowestPriority = pAdd;
                operator= opAdd;
                lowPPosition = i;
            }
        }
        else if (c == '-')
        {
            if (lowestPriority > pSubract)
            {
                lowestPriority = pSubract;
                operator= opSubract;
                lowPPosition = i;
            }
        }
        else if (c == '*')
        {
            if (lowestPriority > pMultiply)
            {
                lowestPriority = pMultiply;
                operator= opMultiply;
                lowPPosition = i;
            }
        }
        else if (c == '/')
        {
            if (lowestPriority > pDevide)
            {
                lowestPriority = pDevide;
                operator= opDevide;
                lowPPosition = i;
            }
        }
        i = i + 1;
    }

    if (lowestPriority != NaN)
    {
        // handle operators
        int v1;
        int v2;
        // get values
        switch (operator)
        {
        case opAdd:
        case opSubract:
        case opMultiply:
        case opDevide:
            v1 = evalExpression2(expression, lowPPosition);
            v2 = evalExpression2(expression + lowPPosition + 1, len - lowPPosition - 1);
            if (v1 == NaN || v2 == NaN)
            {
                return NaN;
            }
            break;
        default:
            break;
        }
        // calculate
        switch (operator)
        {
        case opAdd:
            return v1 + v2;
        case opSubract:
            return v1 - v2;
        case opMultiply:
            return v1 * v2;
        case opDevide:
            if (v2 == 0)
            {
                return NaN;
            }
            return v1 / v2;
        case opBracket:
            return evalExpression2(expression + 1, len - 2);
        default:
            return NaN;
        }
    }
    else
    {
        // no operator found
        if (len == 0)
        {
            return 0;
        }
        else
        {
            return getInt2(expression, len);
        }
    }
}

// ([^\s\0]*)[\s\0]
// apply the calculations and return the result
int evalExpression(char *line)
{
    int len = getNextOffset(line, 0) - 1;
    return evalExpression2(line, len);
}

int main(int argc, char const *argv[])
{
    int result = evalExpression("27*(59+123)/2");
    putInt(result);
    putchar('\n');
    return 0;
}



