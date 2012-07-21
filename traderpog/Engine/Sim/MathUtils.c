//
//  MathUtils.c
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/14/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#include "MathUtils.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

float RandomFrac()
{
    unsigned int randomNum = arc4random() % 101;
    float frac = ((float)randomNum) / 100.0f;
    return frac;
}

int Max(int firstNum, int secondNum)
{
    int result = secondNum;
    if(firstNum > secondNum)
    {
        result = firstNum;
    }
    return result;
}


unsigned int RandomWithinRange(unsigned int min, unsigned int max)
{
    unsigned int result = (unsigned int)(RandomFrac() * ((float)(max-min))) + min;
    return result;
}

int RandomIntWithinPercent(int baseline, float percent, int min)
{
    float fraction = percent / 100.0f;
    float baselineFloat = (float) baseline;
    float factor = RandomFrac();
    float adjustment = ((factor * 2.0f * fraction) - fraction) * baselineFloat;
    baselineFloat = baselineFloat + adjustment;
    int result = (int) floorf(baselineFloat);
    if(min > result)
    {
        result = min;
    }
    
    return result;
}

float RandomFloatWithinPercent(float baseline, float percent, float min)
{
    float fraction = percent / 100.0f;
    float factor = RandomFrac();
    float adjustment = ((factor * 2.0f * fraction) - fraction) * baseline;
    baseline = baseline + adjustment;
    if(min > baseline)
    {
        baseline = min;
    }
    
    return baseline;    
}