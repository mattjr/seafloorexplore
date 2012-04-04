@interface NSOperationQueue (SharedQueue)
+(NSOperationQueue*)sharedOperationQueue;
@end

// NSOperationQueue+SharedQueue.m
@implementation NSOperationQueue (SharedQueue)
+(NSOperationQueue*)sharedOperationQueue;
{
  static NSOperationQueue* sharedQueue = nil;
  if (sharedQueue == nil) {
    sharedQueue = [[NSOperationQueue alloc] init];
  }
  return sharedQueue;
}
@end
