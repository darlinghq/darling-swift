// Copyright (C) 2026 Lubos Dolezel
#import "coredata_fetch_helper.h"

static NSManagedObjectModel *DCMakeModel(void) {
	NSEntityDescription *entity = [[[NSEntityDescription alloc] init] autorelease];
	[entity setName:@"Person"];
	[entity setManagedObjectClassName:@"NSManagedObject"];

	NSAttributeDescription *name = [[[NSAttributeDescription alloc] init] autorelease];
	[name setName:@"name"];
	[name setAttributeType:NSStringAttributeType];
	[name setOptional:NO];

	NSAttributeDescription *age = [[[NSAttributeDescription alloc] init] autorelease];
	[age setName:@"age"];
	[age setAttributeType:NSInteger32AttributeType];
	[age setOptional:NO];
	[age setDefaultValue:@0];

	[entity setProperties:@[name, age]];
	NSManagedObjectModel *model = [[[NSManagedObjectModel alloc] init] autorelease];
	[model setEntities:@[entity]];
	return model;
}

@interface DCFailingContext : NSManagedObjectContext
@end

@implementation DCFailingContext
- (NSArray *)executeFetchRequest:(NSFetchRequest *)request error:(NSError **)error {
	if (error)
		*error = [NSError errorWithDomain:@"DCTestErrorDomain" code:42 userInfo:nil];
	return nil;
}
- (NSUInteger)countForFetchRequest:(NSFetchRequest *)request error:(NSError **)error {
	if (error)
		*error = [NSError errorWithDomain:@"DCTestErrorDomain" code:42 userInfo:nil];
	return NSNotFound;
}
@end

static NSManagedObjectContext *DCMakeContextOfClass(Class cls) {
	NSPersistentStoreCoordinator *coordinator =
		[[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:DCMakeModel()] autorelease];
	NSError *error = nil;
	if (![coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error])
		return nil;
	NSManagedObjectContext *context = [[[cls alloc] init] autorelease];
	[context setPersistentStoreCoordinator:coordinator];
	return context;
}

NSManagedObjectContext *DCMakeContext(void) {
	return DCMakeContextOfClass([NSManagedObjectContext class]);
}

NSManagedObjectContext *DCMakeFailingContext(void) {
	return DCMakeContextOfClass([DCFailingContext class]);
}

void DCInsertPerson(NSManagedObjectContext *context, NSString *name, int age) {
	NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:context];
	[object setValue:name forKey:@"name"];
	[object setValue:@(age) forKey:@"age"];
}

BOOL DCSave(NSManagedObjectContext *context) {
	NSError *error = nil;
	return [context save:&error];
}

void DCDeleteObject(NSManagedObjectContext *context, NSManagedObject *object) {
	[context deleteObject:object];
}

NSFetchRequest<NSManagedObject *> *DCPersonRequest(NSString *predicateFormat, NSString *sortKey, BOOL ascending,
	NSUInteger limit) {
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
	if (predicateFormat)
		[request setPredicate:[NSPredicate predicateWithFormat:predicateFormat]];
	if (sortKey)
		[request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:sortKey ascending:ascending]]];
	if (limit)
		[request setFetchLimit:limit];
	return request;
}
