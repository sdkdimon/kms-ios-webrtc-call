
#import <SocketRocket/SRWebSocket.h>
#import <ReactiveCocoa/RACSignal.h>
#import <ReactiveCocoa/RACCommand.h>

@interface RACSRWebSocket : SRWebSocket

@property(weak,nonatomic,readonly) RACSignal *webSocketDidOpenSignal;
@property(weak,nonatomic,readonly) RACSignal *webSocketDidReceiveMessageSignal;
@property(weak,nonatomic,readonly) RACSignal *webSocketDidFailSignal;
@property(weak,nonatomic,readonly) RACSignal *webSocketDidCloseSignal;
@property(weak,nonatomic,readonly) RACSignal *webSocketDidReceivePongSignal;

@property(strong,nonatomic,readonly) RACCommand *sendDataCommand;
@property(strong,nonatomic,readwrite) NSValueTransformer *requestMessageTransformer;
@property(strong,nonatomic,readwrite) NSValueTransformer *responseMessageTransformer;


/**
 *  Tramsformer block for incoming usages, to simplify data convertation.
 */

-(RACSignal *)openConnection;
-(RACSignal *)closeConnection;

@end
