//
//  MathUtils.h
//  traderpog
//
//  Created by Shu Chiun Cheah on 5/14/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#ifndef traderpog_MathUtils_h
#define traderpog_MathUtils_h

extern float RandomFrac();
extern int Max(int firstNum, int secondNum);
extern unsigned int RandomWithinRange(unsigned int min, unsigned int max);
extern int RandomIntWithinPercent(int baseline, float percent, int min);
extern float RandomFloatWithinPercent(float baseline, float percent, float min);

#endif
