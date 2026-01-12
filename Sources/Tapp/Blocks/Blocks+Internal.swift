import Foundation

public typealias NetworkServiceCompletion = (_ result: Result<Data, Error>) -> Void
public typealias DataTaskCompletion = (Data?, URLResponse?, Error?) -> Void

typealias InitializeTappCompletion = (_ result: Result<Void, Error>) -> Void
typealias SecretsCompletion = (_ result: Result<SecretsResponse, Error>) -> Void
typealias DeviceCompletion = (_ result: Result<Device, Error>) -> Void
typealias LinkDataDTOCompletion = (_ result: Result<TappDeferredLinkDataDTO, Error>) -> Void
