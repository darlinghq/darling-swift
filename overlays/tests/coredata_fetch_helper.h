// Objective-C side of tests/coredata_fetch.swift: the model, the stores and the contexts are set up here so the Swift
// test only exercises what the CoreData overlay adds (the generic fetch and count) and its results.
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

// A context on an in-memory store whose model has one entity, Person, with a string attribute "name" and an Int32
// attribute "age".
NSManagedObjectContext *DCMakeContext(void);
// A context of the same kind whose -executeFetchRequest:error: and -countForFetchRequest:error: always fail with an
// NSError (domain "DCTestErrorDomain", code 42).
NSManagedObjectContext *DCMakeFailingContext(void);
void DCInsertPerson(NSManagedObjectContext *context, NSString *name, int age);
BOOL DCSave(NSManagedObjectContext *context);
void DCDeleteObject(NSManagedObjectContext *context, NSManagedObject *object);

// Requests for Person: all objects (or those matching the predicate format when it is not nil), sorted by sortKey when
// it is not nil, limited to limit objects when it is not 0.
NSFetchRequest<NSManagedObject *> *DCPersonRequest(NSString *_Nullable predicateFormat, NSString *_Nullable sortKey,
	BOOL ascending, NSUInteger limit);

NS_ASSUME_NONNULL_END
