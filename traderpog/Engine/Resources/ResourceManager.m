//
//  ResourceManager.m
//  traderpog
//
//  Created by Aaron Khoo on 8/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GameManager.h"
#import "ResourceManager.h"
#import "SSZipArchive.h"

static NSString* const kKeyVersion = @"version";
static NSString* const kKeyLastModified = @"lastmodified";
static NSString* const kResourceManagerFilename = @"resourcemanager.sav";
static NSString* const kResourceBundleFilename = @"resources.bundle";
static NSString* const kResourcePackagePath = @"resources.zip";
static NSString* const kResourcePackageURL = @"https://s3.amazonaws.com/traderpog/resources.zip";

@interface ResourceManager ()
{
    // internal
    NSString* _createdVersion;
    
    NSDate* _resourceLastModified;
    NSDate* _resourceNewlyModifiedDate;
    NSURLConnection* _headConnection;
    NSURLConnection* _getConnection;
    NSMutableData* _dataBuffer;
    NSBundle* _bundle;
}
- (NSString*)getResourcePath:(NSString*)subDir resourceName:(NSString*)resName;
@end

@implementation ResourceManager
@synthesize delegate = _delegate;

- (id) init
{
    self = [super init];
    if(self)
    {
        _resourceLastModified = nil;
        _resourceNewlyModifiedDate = nil;
        _headConnection = nil;
        _getConnection = nil;
        _dataBuffer = nil;
        _bundle = nil;
    }
    return self;
}

#pragma mark - NSCoding
- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_createdVersion forKey:kKeyVersion];
    [aCoder encodeObject:_resourceLastModified forKey:kKeyLastModified];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    _createdVersion = [aDecoder decodeObjectForKey:kKeyVersion];
    _resourceLastModified = [aDecoder decodeObjectForKey:kKeyLastModified];
    return self;
}


#pragma mark - private functions

+ (NSString*) resourceManagerFilepath
{
    NSString* docsDir = [GameManager documentsDirectory];
    NSString* filepath = [docsDir stringByAppendingPathComponent:kResourceManagerFilename];
    return filepath;
}

+ (NSString*) resourcePackageFilepath
{
    NSString* docsDir = [GameManager documentsDirectory];
    NSString* filepath = [docsDir stringByAppendingPathComponent:kResourcePackagePath];
    return filepath;
}

+ (NSString*) resourceBundlePath
{
    NSString* docsDir = [GameManager documentsDirectory];
    NSString* filepath = [docsDir stringByAppendingPathComponent:kResourceBundleFilename];
    return filepath;
}

#pragma mark - saved game data loading and unloading
+ (ResourceManager*) loadResourceManagerData
{
    ResourceManager* current_rm = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [ResourceManager resourceManagerFilepath];
    if ([fileManager fileExistsAtPath:filepath])
    {
        NSData* readData = [NSData dataWithContentsOfFile:filepath];
        if(readData)
        {
            current_rm = [NSKeyedUnarchiver unarchiveObjectWithData:readData];
        }
    }
    return current_rm;
}

- (void) saveResourceManagerData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSError* error = nil;
    BOOL writeSuccess = [data writeToFile:[ResourceManager resourceManagerFilepath]
                                  options:NSDataWritingAtomic
                                    error:&error];
    if(writeSuccess)
    {
        NSLog(@"resource manager file saved successfully");
    }
    else
    {
        NSLog(@"resource manager file save failed: %@", error);
    }
}

- (void) removeResourceManagerData
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filepath = [ResourceManager resourceManagerFilepath];
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:filepath])
    {
        [fileManager removeItemAtPath:filepath error:&error];
    }
}

- (NSString*)getResourcePath:(NSString*)subDir resourceName:(NSString*)resName
{
    if (_bundle)
    {
        NSString* resourcePath = [NSString stringWithFormat:@"%@/%@",subDir, resName];
        return [_bundle pathForResource:resourcePath ofType:nil];
    }
    return nil;
}

#pragma mark - Server call functions

- (void) sendRequestForResourcePackage:(BOOL)headOnly
{
    // send a request for file modification date  
    NSURL *url = [NSURL URLWithString:kResourcePackageURL];
    NSMutableURLRequest *lastmodReq = [NSMutableURLRequest requestWithURL:url];
    [lastmodReq setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [lastmodReq setTimeoutInterval:15.0f];
    NSURLConnection* currentConnection;
    
    if (headOnly)
    {
        [lastmodReq setHTTPMethod:@"HEAD"];
        _headConnection = [[NSURLConnection alloc] initWithRequest:lastmodReq delegate:self];
        currentConnection = _headConnection;
    }
    else
    {
        [lastmodReq setHTTPMethod:@"GET"];
        _getConnection = [[NSURLConnection alloc] initWithRequest:lastmodReq delegate:self];
        currentConnection = _getConnection;
    }
    
    if (currentConnection)
    {
        NSLog(@"HTTP request for resource package started.");
    }
    else
    {
        NSLog(@"HTTP request for resources failed!");
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    BOOL openBundle = FALSE;
    NSHTTPURLResponse* urlResponse = (NSHTTPURLResponse *)response;
    
    if (_headConnection == connection)
    {        
        if ([urlResponse statusCode] == 200)
        {
            // Get the last-modified header to check
            NSString * last_modified = [NSString stringWithFormat:@"%@",
                                        [[urlResponse allHeaderFields] objectForKey:@"Last-Modified"]];
            NSLog(@"Last-Modified: %@", last_modified );
            
            // Convert to NSDate
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            df.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss z";
            df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            _resourceNewlyModifiedDate = [df dateFromString:last_modified];
            
            // If the resource package has been modified recently, then download it
            if (!_resourceLastModified || [_resourceLastModified timeIntervalSinceDate:_resourceNewlyModifiedDate] < 0)
            {
                NSLog(@"Requesting resource package");
                _dataBuffer = [[NSMutableData alloc] init];
                [self sendRequestForResourcePackage:FALSE];
            }
            else
            {
                NSLog(@"Resource package has not changed. Skipping download.");
                openBundle = TRUE;
            }
        }
        else
        {
            NSLog(@"Received HTTP error from resource package head connection!");
            // Some error was returned from aws. Try opening local package that
            // might have been stored. 
            openBundle = TRUE;
        }
    }
    else if (_getConnection == connection)
    {
        if ([urlResponse statusCode] == 200)
        {
            NSLog(@"Response received from resource package request.");
        }
        else
        {
            NSLog(@"Received HTTP error from resource package get connection!");
        }
    }
    else
    {
        NSLog(@"Received response for unknown resource package connection!");
    }
    
    // Open up the resource package
    if (openBundle)
    {
        NSLog(@"Opening local resource package");
        
        // Open the bundle file
        _bundle = [NSBundle bundleWithPath:[ResourceManager resourceBundlePath]];
        
        [self.delegate didCompleteHttpCallback:kResourceManager_PackageReady, TRUE];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (_getConnection == connection)
    {
        NSLog(@"Append %d bytes to data buffer", [data length]);
        [_dataBuffer appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (_getConnection == connection)
    {
        NSData* data = (NSData*)_dataBuffer;
        NSLog(@"Write resource package to disk. Size: %d", [data length]);
        if ([data length] > 0)
        {
            // Write the downloaded zip file to disk
            [data writeToFile:[ResourceManager resourcePackageFilepath] atomically:YES];
            
            // Remove old bundle
            NSFileManager* fileManager = [NSFileManager defaultManager];
            NSString* filepath = [ResourceManager resourceBundlePath];
            NSError *error = nil;
            if ([fileManager fileExistsAtPath:filepath])
            {
                [fileManager removeItemAtPath:filepath error:&error];
            }
            
            // Unzip the downloaded file into a bundle directory.
            [SSZipArchive unzipFileAtPath:[ResourceManager resourcePackageFilepath]
                            toDestination:[GameManager documentsDirectory]];
            
            // Open the bundle file
            _bundle = [NSBundle bundleWithPath:[ResourceManager resourceBundlePath]];
            
            // Save the last modified date
            _resourceLastModified = _resourceNewlyModifiedDate;
            _resourceNewlyModifiedDate = nil;
            
            // The ResourcePackage is done loading. Save anything we need to. 
            [self saveResourceManagerData];
            
            [self.delegate didCompleteHttpCallback:kResourceManager_PackageReady, TRUE];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (_getConnection == connection || _headConnection == connection)
    {
        NSLog(@"Resource package retrieval failed!");
        
        // Inform of failure
        [self.delegate didCompleteHttpCallback:kResourceManager_PackageReady, FALSE];
    }
    else
    {
        NSLog(@"Unknown connection failure in resource package retrieval!");
    }
}

#pragma mark - Public functions

- (void)downloadResourceFileIfNecessary
{
    [self sendRequestForResourcePackage:TRUE];
}

- (NSString*)getAudioPath:(NSString*)resourceName
{
    return [self getResourcePath:@"audio" resourceName:resourceName];
}

- (NSString*)getImagePath:(NSString*)subDir forResource:(NSString*)resourceName
{
    return [self getResourcePath:subDir resourceName:resourceName];
}


#pragma mark - Singleton
static ResourceManager* singleton = nil;
+ (ResourceManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
            // First, try to load the player data from disk
            singleton = [ResourceManager loadResourceManagerData];
            if (!singleton)
            {
                // OK, no saved data available. Go ahead and create a new Player.
                singleton = [[ResourceManager alloc] init];
            }
		}
	}
	return singleton;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		singleton = nil;
	}
}

@end
