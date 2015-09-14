
#import "MTLJSONAdapterWithoutNil.h"

//@interface MTLJSONAdapter ()
//+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass;
//
//@end


@implementation MTLJSONAdapterWithoutNil

//-(NSSet *)serializablePropertyKeys:(NSSet *)propertyKeys forModel:(id<MTLJSONSerializing>)model{
//    
//    id idModel = model;
//    
//    NSDictionary *transformers = [[self class] valueTransformersForModelClass:[idModel class]];
//    
//    NSMutableSet *ms = [propertyKeys mutableCopy];
//    NSMutableSet *keysToRemove = [[NSMutableSet alloc] init];
//    for (NSString *key in ms) {
//        id val = [idModel valueForKey:key];
//        if(val == [NSNull null] || val == nil) {
//            [keysToRemove addObject:key];
//        } else{
//            NSValueTransformer *transformer = transformers[key];
//            if([[transformer class] allowsReverseTransformation]){
//                val = [transformer reverseTransformedValue:val];
//                if(val == [NSNull null] || val == nil){
//                    [keysToRemove addObject:key];
//                }
//            }
//        }
//        
//    }
//    [ms minusSet:keysToRemove];
//    return [NSSet setWithSet:ms];
// }

-(NSDictionary *)JSONDictionaryFromModel:(id<MTLJSONSerializing>)model error:(NSError *__autoreleasing *)error{
    NSMutableDictionary *JSONDictionary = [[super JSONDictionaryFromModel:model error:error] mutableCopy];
    NSMutableArray *keysToRemove = [[NSMutableArray alloc] init];
    for(NSString *key in JSONDictionary){
        id value = JSONDictionary[key];
        if(value == [NSNull null]) {[keysToRemove addObject:key];}
    }
    [JSONDictionary removeObjectsForKeys:keysToRemove];
    return [JSONDictionary copy];
}

@end
