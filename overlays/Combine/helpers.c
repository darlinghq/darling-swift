// C implementation of the COpenCombineHelpers interface (identifier counter and the
// two lock flavours). Replaces OpenCombine's C++ file so the dylib needs no libc++.
#include "COpenCombineHelpers.h"

#include <os/lock.h>
#include <signal.h>
#include <pthread.h>
#include <stdlib.h>

static uint64_t next_identifier;

uint64_t opencombine_next_combine_identifier(void) {
    return __atomic_fetch_add(&next_identifier, 1, __ATOMIC_RELAXED);
}

static void *must_alloc(size_t size) {
    void *p = malloc(size);
    if (!p)
        abort();
    return p;
}

OpenCombineUnfairLock opencombine_unfair_lock_alloc(void) {
    os_unfair_lock_t lock = must_alloc(sizeof(os_unfair_lock));
    *lock = OS_UNFAIR_LOCK_INIT;
    return (OpenCombineUnfairLock){ .opaque = lock };
}

void opencombine_unfair_lock_lock(OpenCombineUnfairLock lock) {
    os_unfair_lock_lock(lock.opaque);
}

void opencombine_unfair_lock_unlock(OpenCombineUnfairLock lock) {
    os_unfair_lock_unlock(lock.opaque);
}

void opencombine_unfair_lock_assert_owner(OpenCombineUnfairLock lock) {
    os_unfair_lock_assert_owner(lock.opaque);
}

void opencombine_unfair_lock_dealloc(OpenCombineUnfairLock lock) {
    free(lock.opaque);
}

OpenCombineUnfairRecursiveLock opencombine_unfair_recursive_lock_alloc(void) {
    pthread_mutex_t *mutex = must_alloc(sizeof(pthread_mutex_t));
    pthread_mutexattr_t attr;
    if (pthread_mutexattr_init(&attr) != 0)
        abort();
    if (pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE) != 0)
        abort();
    if (pthread_mutex_init(mutex, &attr) != 0)
        abort();
    pthread_mutexattr_destroy(&attr);
    return (OpenCombineUnfairRecursiveLock){ .opaque = mutex };
}

void opencombine_unfair_recursive_lock_lock(OpenCombineUnfairRecursiveLock lock) {
    if (pthread_mutex_lock(lock.opaque) != 0)
        abort();
}

void opencombine_unfair_recursive_lock_unlock(OpenCombineUnfairRecursiveLock lock) {
    if (pthread_mutex_unlock(lock.opaque) != 0)
        abort();
}

void opencombine_unfair_recursive_lock_dealloc(OpenCombineUnfairRecursiveLock lock) {
    if (pthread_mutex_destroy(lock.opaque) != 0)
        abort();
    free(lock.opaque);
}

void opencombine_stop_in_debugger(void) {
    raise(SIGTRAP);
}
