//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// From release/5.4 (apple/swift 845205b4407c) stdlib/public/Darwin/Foundation/NSError.swift, MachError.

@_exported import Foundation // Clang module
import CoreFoundation

public struct MachError : _BridgedStoredNSError {
  public let _nsError: NSError

  public init(_nsError error: NSError) {
    precondition(error.domain() == NSMachErrorDomain)
    self._nsError = error
  }

  public static var errorDomain: String { return NSMachErrorDomain }

  public var hashValue: Int {
    return _nsError.hashValue
  }

  public typealias Code = MachErrorCode
}

extension MachErrorCode : _ErrorCodeProtocol {
  public typealias _ErrorType = MachError
}

extension MachError {
  public static var success: MachError.Code {
    return .success
  }

  /// Specified address is not currently valid.
  public static var invalidAddress: MachError.Code {
    return .invalidAddress
  }

  /// Specified memory is valid, but does not permit the required
  /// forms of access.
  public static var protectionFailure: MachError.Code {
    return .protectionFailure
  }

  /// The address range specified is already in use, or no address
  /// range of the size specified could be found.  
  public static var noSpace: MachError.Code {
    return .noSpace
  }

  /// The function requested was not applicable to this type of
  /// argument, or an argument is invalid.
  public static var invalidArgument: MachError.Code {
    return .invalidArgument
  }

  /// The function could not be performed.  A catch-all.
  public static var failure: MachError.Code {
    return .failure
  }

  /// A system resource could not be allocated to fulfill this
  /// request.  This failure may not be permanent.
  public static var resourceShortage: MachError.Code {
    return .resourceShortage
  }

  /// The task in question does not hold receive rights for the port
  /// argument.
  public static var notReceiver: MachError.Code {
    return .notReceiver
  }

  /// Bogus access restriction.
  public static var noAccess: MachError.Code {
    return .noAccess
  }

  /// During a page fault, the target address refers to a memory
  /// object that has been destroyed.  This failure is permanent.
  public static var memoryFailure: MachError.Code {
    return .memoryFailure
  }

  /// During a page fault, the memory object indicated that the data
  /// could not be returned.  This failure may be temporary; future
  /// attempts to access this same data may succeed, as defined by the
  /// memory object.
  public static var memoryError: MachError.Code {
    return .memoryError
  }

  /// The receive right is already a member of the portset.
  public static var alreadyInSet: MachError.Code {
    return .alreadyInSet
  }

  /// The receive right is not a member of a port set.
  public static var notInSet: MachError.Code {
    return .notInSet
  }

  /// The name already denotes a right in the task.
  public static var nameExists: MachError.Code {
    return .nameExists
  }

  /// The operation was aborted.  Ipc code will catch this and reflect
  /// it as a message error.
  public static var aborted: MachError.Code {
    return .aborted
  }

  /// The name doesn't denote a right in the task.
  public static var invalidName: MachError.Code {
    return .invalidName
  }

  /// Target task isn't an active task.
  public static var invalidTask: MachError.Code {
    return .invalidTask
  }

  /// The name denotes a right, but not an appropriate right.
  public static var invalidRight: MachError.Code {
    return .invalidRight
  }

  /// A blatant range error.
  public static var invalidValue: MachError.Code {
    return .invalidValue
  }

  /// Operation would overflow limit on user-references.
  public static var userReferencesOverflow: MachError.Code {
    return .userReferencesOverflow
  }

  /// The supplied (port) capability is improper.
  public static var invalidCapability: MachError.Code {
    return .invalidCapability
  }

  /// The task already has send or receive rights for the port under
  /// another name.
  public static var rightExists: MachError.Code {
    return .rightExists
  }

  /// Target host isn't actually a host.
  public static var invalidHost: MachError.Code {
    return .invalidHost
  }

  /// An attempt was made to supply "precious" data for memory that is
  /// already present in a memory object.
  public static var memoryPresent: MachError.Code {
    return .memoryPresent
  }

  /// A page was requested of a memory manager via
  /// memory_object_data_request for an object using a
  /// MEMORY_OBJECT_COPY_CALL strategy, with the VM_PROT_WANTS_COPY
  /// flag being used to specify that the page desired is for a copy
  /// of the object, and the memory manager has detected the page was
  /// pushed into a copy of the object while the kernel was walking
  /// the shadow chain from the copy to the object. This error code is
  /// delivered via memory_object_data_error and is handled by the
  /// kernel (it forces the kernel to restart the fault). It will not
  /// be seen by users.
  public static var memoryDataMoved: MachError.Code {
    return .memoryDataMoved
  }

  /// A strategic copy was attempted of an object upon which a quicker
  /// copy is now possible.  The caller should retry the copy using
  /// vm_object_copy_quickly. This error code is seen only by the
  /// kernel.
  public static var memoryRestartCopy: MachError.Code {
    return .memoryRestartCopy
  }

  /// An argument applied to assert processor set privilege was not a
  /// processor set control port.
  public static var invalidProcessorSet: MachError.Code {
    return .invalidProcessorSet
  }

  /// The specified scheduling attributes exceed the thread's limits.
  public static var policyLimit: MachError.Code {
    return .policyLimit
  }

  /// The specified scheduling policy is not currently enabled for the
  /// processor set.
  public static var invalidPolicy: MachError.Code {
    return .invalidPolicy
  }

  /// The external memory manager failed to initialize the memory object.
  public static var invalidObject: MachError.Code {
    return .invalidObject
  }

  /// A thread is attempting to wait for an event for which there is
  /// already a waiting thread.
  public static var alreadyWaiting: MachError.Code {
    return .alreadyWaiting
  }

  /// An attempt was made to destroy the default processor set.
  public static var defaultSet: MachError.Code {
    return .defaultSet
  }

  /// An attempt was made to fetch an exception port that is
  /// protected, or to abort a thread while processing a protected
  /// exception.
  public static var exceptionProtected: MachError.Code {
    return .exceptionProtected
  }

  /// A ledger was required but not supplied.
  public static var invalidLedger: MachError.Code {
    return .invalidLedger
  }

  /// The port was not a memory cache control port.
  public static var invalidMemoryControl: MachError.Code {
    return .invalidMemoryControl
  }

  /// An argument supplied to assert security privilege was not a host
  /// security port.
  public static var invalidSecurity: MachError.Code {
    return .invalidSecurity
  }

  /// thread_depress_abort was called on a thread which was not
  /// currently depressed.
  public static var notDepressed: MachError.Code {
    return .notDepressed
  }

  /// Object has been terminated and is no longer available.
  public static var terminated: MachError.Code {
    return .terminated
  }

  /// Lock set has been destroyed and is no longer available.
  public static var lockSetDestroyed: MachError.Code {
    return .lockSetDestroyed
  }

  /// The thread holding the lock terminated before releasing the lock.
  public static var lockUnstable: MachError.Code {
    return .lockUnstable
  }

  /// The lock is already owned by another thread.
  public static var lockOwned: MachError.Code {
    return .lockOwned
  }

  /// The lock is already owned by the calling thread.
  public static var lockOwnedSelf: MachError.Code {
    return .lockOwnedSelf
  }

  /// Semaphore has been destroyed and is no longer available.
  public static var semaphoreDestroyed: MachError.Code {
    return .semaphoreDestroyed
  }

  /// Return from RPC indicating the target server was terminated
  /// before it successfully replied.
  public static var rpcServerTerminated: MachError.Code {
    return .rpcServerTerminated
  }

  /// Terminate an orphaned activation.
  public static var rpcTerminateOrphan: MachError.Code {
    return .rpcTerminateOrphan
  }

  /// Allow an orphaned activation to continue executing.
  public static var rpcContinueOrphan: MachError.Code {
    return .rpcContinueOrphan
  }

  /// Empty thread activation (No thread linked to it).
  public static var notSupported: MachError.Code {
    return .notSupported
  }

  /// Remote node down or inaccessible.
  public static var nodeDown: MachError.Code {
    return .nodeDown
  }

  /// A signalled thread was not actually waiting.
  public static var notWaiting: MachError.Code {
    return .notWaiting
  }

  /// Some thread-oriented operation (semaphore_wait) timed out.
  public static var operationTimedOut: MachError.Code {
    return .operationTimedOut
  }

  /// During a page fault, indicates that the page was rejected as a
  /// result of a signature check.
  public static var codesignError: MachError.Code {
    return .codesignError
  }

  /// The requested property cannot be changed at this time.
  public static var policyStatic: MachError.Code {
    return .policyStatic
  }
}

