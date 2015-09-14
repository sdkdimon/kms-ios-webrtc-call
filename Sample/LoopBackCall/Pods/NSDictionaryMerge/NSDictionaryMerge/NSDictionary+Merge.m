
#import "NSDictionary+Merge.h"

@implementation NSDictionary (Merge)

-(NSDictionary *)dictionaryByMergingDictionary:(NSDictionary *)dictionary{
    if(dictionary == nil){
        return self;
    }
    
    NSMutableDictionary *mutableSelf = [self mutableCopy];
    [mutableSelf addEntriesFromDictionary:dictionary];
    return [mutableSelf copy];
    
}

@end
