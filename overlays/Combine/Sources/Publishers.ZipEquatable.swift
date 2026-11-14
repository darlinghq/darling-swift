// Copyright (C) 2026 Lubos Dolezel
//
// Equatable conformances of the Zip publishers, which Combine declares when all the upstream publishers are
// Equatable: two publishers are equal when their upstream publishers are equal, position by position.

extension Publishers.Zip: Equatable where UpstreamA: Equatable, UpstreamB: Equatable {

    public static func == (lhs: Publishers.Zip<UpstreamA, UpstreamB>,
                           rhs: Publishers.Zip<UpstreamA, UpstreamB>) -> Bool {
        return lhs.a == rhs.a && lhs.b == rhs.b
    }
}

extension Publishers.Zip3: Equatable
    where UpstreamA: Equatable, UpstreamB: Equatable, UpstreamC: Equatable
{
    public static func == (lhs: Publishers.Zip3<UpstreamA, UpstreamB, UpstreamC>,
                           rhs: Publishers.Zip3<UpstreamA, UpstreamB, UpstreamC>) -> Bool {
        return lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c
    }
}

extension Publishers.Zip4: Equatable
    where UpstreamA: Equatable, UpstreamB: Equatable, UpstreamC: Equatable, UpstreamD: Equatable
{
    public static func == (lhs: Publishers.Zip4<UpstreamA, UpstreamB, UpstreamC, UpstreamD>,
                           rhs: Publishers.Zip4<UpstreamA, UpstreamB, UpstreamC, UpstreamD>) -> Bool {
        return lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c && lhs.d == rhs.d
    }
}
