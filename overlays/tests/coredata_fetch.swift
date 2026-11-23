// CoreData overlay: NSManagedObjectContext.fetch(_:) and count(for:) for NSFetchRequest<T> over an in-memory store
// and a model built in code (typed results, predicate, sort order, limit, the
// NSError of a failing fetch), the CocoaError codes the overlay adds, and the NSFetchRequestResult conformances.
// The model, store and requests are made by coredata_fetch_helper.m (the header-imported Swift API of Darling's
// CoreData is not what this test is about). Exits non-zero on failure.
//
// Build: compile the helper with clang for the target, give swiftc -import-objc-header coredata_fetch_helper.h, and
// link the helper object next to the test object.

import Foundation
import CoreData

var failures = 0
func check(_ ok: Bool, _ what: String) {
	print("\(ok ? "PASS" : "FAIL"): \(what)")
	fflush(nil)
	if !ok { failures += 1 }
}

func names(_ objects: [NSManagedObject]) -> [String] {
	return objects.map { $0.value(forKey: "name") as? String ?? "?" }
}

let context = DCMakeContext()
DCInsertPerson(context, "Alice", 31)
DCInsertPerson(context, "Bob", 25)
DCInsertPerson(context, "Carol", 47)
check(DCSave(context), "three objects saved")

// A typed fetch: the element type of the result is the request's type parameter.
do {
	let people: [NSManagedObject] = try context.fetch(DCPersonRequest(nil, "name", true, 0))
	check(people.count == 3, "fetch returns all three objects")
	check(names(people) == ["Alice", "Bob", "Carol"], "results follow the sort descriptor")
	check(people.allSatisfy { ($0.value(forKey: "age") as? Int) != nil }, "results are Person objects with an age")
} catch {
	check(false, "typed fetch threw \(error)")
}

// Predicate and descending order.
do {
	let result = try context.fetch(DCPersonRequest("age > 30", "age", false, 0))
	check(names(result) == ["Carol", "Alice"], "predicate filters and the sort orders descending")
} catch {
	check(false, "predicate fetch threw \(error)")
}

// A predicate that matches nothing gives an empty array, not an error.
do {
	check(try context.fetch(DCPersonRequest("name == 'Zed'", nil, true, 0)).isEmpty, "no match gives an empty array")
} catch {
	check(false, "empty fetch threw \(error)")
}

// fetchLimit
do {
	check(try context.fetch(DCPersonRequest(nil, "age", true, 2)).count == 2, "fetchLimit limits the result")
} catch {
	check(false, "limited fetch threw \(error)")
}

// count(for:)
do {
	check(try context.count(for: DCPersonRequest(nil, nil, true, 0)) == 3, "count(for:) counts every object")
	check(try context.count(for: DCPersonRequest("age > 30", nil, true, 0)) == 2, "count(for:) honours the predicate")
} catch {
	check(false, "count threw \(error)")
}

// A deleted object is gone from the next fetch.
do {
	let bob = try context.fetch(DCPersonRequest("name == 'Bob'", nil, true, 0))
	check(bob.count == 1, "Bob is fetched")
	DCDeleteObject(context, bob[0])
	check(DCSave(context), "the deletion is saved")
	check(names(try context.fetch(DCPersonRequest(nil, "name", true, 0))) == ["Alice", "Carol"], "the deleted object is gone")
} catch {
	check(false, "delete and fetch threw \(error)")
}

// A fetch and a count that fail with an NSError throw it.
let failing = DCMakeFailingContext()
do {
	_ = try failing.fetch(DCPersonRequest(nil, nil, true, 0))
	check(false, "a failing fetch throws")
} catch {
	check(error._domain == "DCTestErrorDomain" && error._code == 42, "a failing fetch throws the NSError")
}
do {
	_ = try failing.count(for: DCPersonRequest(nil, nil, true, 0))
	check(false, "a failing count throws")
} catch {
	check(error._domain == "DCTestErrorDomain" && error._code == 42, "a failing count throws the NSError")
}

// The CocoaError codes the overlay adds.
check(CocoaError.Code.managedObjectValidation.rawValue == 1550, "managedObjectValidation is 1550")
check(CocoaError.Code.validationStringPatternMatching.rawValue == 1680, "validationStringPatternMatching is 1680")
check(CocoaError.Code.persistentStoreOpen.rawValue == 134080, "persistentStoreOpen is 134080")
check(CocoaError.Code.persistentStoreIncompatibleVersionHash.rawValue == 134100, "persistentStoreIncompatibleVersionHash is 134100")
check(CocoaError.Code.migration.rawValue == 134110, "migration is 134110")

// NSNumber and NSDictionary are NSFetchRequestResult, as is NSManagedObject.
check(NSNumber(value: 1).conforms(to: NSFetchRequestResult.self), "NSNumber conforms to NSFetchRequestResult")
check(NSDictionary().conforms(to: NSFetchRequestResult.self), "NSDictionary conforms to NSFetchRequestResult")

print("failures=\(failures)")
exit(failures == 0 ? 0 : 1)
