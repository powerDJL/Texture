//
//  NSCache+ASHelpers.mm
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/NSCache+ASHelpers.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <AsyncDisplayKit/ASLog.h>

#import <mutex>
#import <unordered_map>

using namespace std;

@implementation NSCache (ASHelpers)

#if ASCachingLogEnabled
+ (void)load
{
  static unordered_map<void *, pair<int, int>> counts;
  static mutex lock;
  __block IMP originalObjectForKey = ASReplaceMethodWithBlock(self, @selector(objectForKey:), ^(NSCache *self, id key) {
    id result = ((id (*)(NSCache *, SEL, id))originalObjectForKey)(self, @selector(objectForKey:), key);
    
    BOOL hit = (result != nil);
    void *ptrSelf = (__bridge void *)self;
    int hits, misses;
    {
      lock_guard<mutex> l(lock);
      auto pairPtr = &counts[ptrSelf] ?: &(counts[ptrSelf] = pair<int, int>(0, 0));
      if (hit) {
        hits = (pairPtr->first += 1);
        misses = pairPtr->second;
      } else {
        hits = pairPtr->first;
        misses = (pairPtr->second += 1);
      }
    }
    
    int totalReads = hits + misses;
    if ((totalReads % 20) == 0) {
      as_log_info(ASCachingLog(), "%@ hit rate: %d/%d (%.2f%%)", self.name.length ? self.name : self.debugDescription, hits, totalReads, 100.0 * (hits / (double)totalReads));
    }
    return result;
  });
}
#endif

@end
