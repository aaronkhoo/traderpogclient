//
//  LeaderboardRowCell.m
//  traderpog
//
//  Created by Aaron Khoo on 10/3/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "LeaderboardRowCell.h"

@implementation LeaderboardRowCell
@synthesize leftLabel;
@synthesize middleLabel;
@synthesize rightLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
