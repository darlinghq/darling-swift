#ifndef DARLING_COREDATA_OVERLAY_SHIMS_H
#define DARLING_COREDATA_OVERLAY_SHIMS_H

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

// Calls -executeFetchRequest:error: on the context: the overlay's generic fetch(_:) cannot name the Objective-C
// method, which Swift imports with the same name and an equivalent signature.
static inline NSArray *_Nullable DarlingCoreDataExecuteFetch(NSManagedObjectContext *context, id request,
	NSError *_Nullable *_Nullable error) {
	return [context executeFetchRequest:(NSFetchRequest *)request error:error];
}

// Calls -countForFetchRequest:error: on the context; the count is NSNotFound with *error set when it fails.
static inline NSUInteger DarlingCoreDataCount(NSManagedObjectContext *context, id request,
	NSError *_Nullable *_Nullable error) {
	return [context countForFetchRequest:(NSFetchRequest *)request error:error];
}

NS_ASSUME_NONNULL_END

#endif
