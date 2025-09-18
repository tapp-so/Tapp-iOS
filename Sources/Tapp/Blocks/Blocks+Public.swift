import Foundation

public typealias VoidCompletion = (_ result: Result<Void, Error>) -> Void
public typealias ResolvedURLCompletion = (_ result: Result<URL, Error>) -> Void
public typealias GenerateURLCompletion = (_ result: Result<GeneratedURLResponse, Error>) -> Void
public typealias LinkDataCompletion = (_ result: Result<TappDeferredLinkData, Error>) -> Void
