//
//  Copyright (c) 2022 Dropbox Inc. All rights reserved.
//

import Foundation

public enum UploadBody {
    case data(Data)
    case file(URL)
    case stream(InputStream)
}

/// These objects are constructed by the SDK; users of the SDK do not need to create them manually.
///
/// Pass in a closure to the `response` method to handle a response or error.
public class Request<RSerial: JSONSerializer, ESerial: JSONSerializer> {
    let responseSerializer: RSerial
    let errorSerializer: ESerial

    public var clientPersistedString: String? {
        persistedRequestInfo?.clientProvidedInfo
    }

    @available(iOS 13.0, macOS 10.13, *)
    public var earliestBeginDate: Date? {
        request.earliestBeginDate
    }

    private(set) var request: ApiRequest
    fileprivate var persistedRequestInfo: ReconnectionHelpers.PersistedRequestInfo? {
        get {
            try? ReconnectionHelpers.persistedRequestInfo(from: request)
        }
        set {
            request.taskDescription = try? newValue?.asJsonString()
        }
    }

    private var selfRetain: AnyObject?

    init(request: ApiRequest, responseSerializer: RSerial, errorSerializer: ESerial) {
        self.errorSerializer = errorSerializer
        self.responseSerializer = responseSerializer

        self.request = request
        self.selfRetain = self
        request.setCleanupHandler { [weak self] in
            self?.cleanupSelfRetain()
        }
    }

    @discardableResult
    public func persistingString(
        string: String?
    ) -> Self {
        persistedRequestInfo = persistedRequestInfo?.settingClientInfo(string: string)
        DropboxClientsManager.logBackgroundSession("persistingString full description: \(request.taskDescription ?? "None")")
        return self
    }

    @available(iOS 13.0, macOS 10.13, *)
    @discardableResult
    public func settingEarliestBeginDate(
        date: Date?
    ) -> Self {
        request.earliestBeginDate = date
        return self
    }

    public func cancel() {
        request.cancel()
    }

    func handleResponseError(networkTaskFailure: NetworkTaskFailure) -> CallError<ESerial.ValueType> {
        let callError = parseCallError(from: networkTaskFailure)
        
        // We call the global error response handler to alert it to an error
        // But unlike in the objc SDK we do not stop the SDK from calling the per-route completion handler as well.
        GlobalErrorResponseHandler.shared.reportGlobalError(callError.typeErased)
        
        return callError
    }
    
    private func parseCallError(from networkTaskFailure: NetworkTaskFailure) -> CallError<ESerial.ValueType> {
        switch networkTaskFailure {
        case .badStatusCode(let data, _, let response):
            return CallError(response, data: data, errorSerializer: errorSerializer)

        case .failedWithError(let error):
            return CallError(clientError: .urlSessionError(error))
        }
    }

    private func cleanupSelfRetain() {
        selfRetain = nil
    }
}

/// An "rpc-style" request
public class RpcRequest<RSerial: JSONSerializer, ESerial: JSONSerializer>: Request<RSerial, ESerial> {
    @discardableResult
    public func response(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (RSerial.ValueType?, CallError<ESerial.ValueType>?) -> Void
    ) -> Self {
        request.setCompletionHandlerProvider(queue: queue, completionHandlerProvider: .dataCompletionHandlerProvider({ [weak self] response in
            guard let strongSelf = self else {
                return {
                    completionHandler(nil, .clientError(.requestObjectDeallocated))
                }
            }

            var (result, error): (RSerial.ValueType?, CallError<ESerial.ValueType>?)

            switch response {
            case .success((let data, _)):
                do {
                    (result, error) = (try strongSelf.responseSerializer.deserialize(SerializeUtil.parseJSON(data)), nil)
                } catch let _error {
                    (result, error) = (nil, CallError.serializationError(_error))
                }
            case .failure(let failure):
                (result, error) = (nil, strongSelf.handleResponseError(networkTaskFailure: failure))
            }

            return {
                completionHandler(result, error)
            }
        }))
        return self
    }
}

/// An "upload-style" request
public class UploadRequest<RSerial: JSONSerializer, ESerial: JSONSerializer>: Request<RSerial, ESerial> {
    @discardableResult
    public func progress(_ progressHandler: @escaping ((Progress) -> Void)) -> Self {
        request.setProgressHandler(progressHandler)
        return self
    }

    @discardableResult
    public func response(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (RSerial.ValueType?, CallError<ESerial.ValueType>?) -> Void
    ) -> Self {
        request.setCompletionHandlerProvider(queue: queue, completionHandlerProvider: .dataCompletionHandlerProvider({ [weak self] response in
            guard let strongSelf = self else {
                return {
                    completionHandler(nil, .clientError(.requestObjectDeallocated))
                }
            }

            var (result, error): (RSerial.ValueType?, CallError<ESerial.ValueType>?)

            switch response {
            case .success((let data, _)):
                do {
                    (result, error) = (try strongSelf.responseSerializer.deserialize(SerializeUtil.parseJSON(data)), nil)
                } catch let _error {
                    (result, error) = (nil, CallError.serializationError(_error))
                }
            case .failure(let failure):
                (result, error) = (nil, strongSelf.handleResponseError(networkTaskFailure: failure))
            }

            return {
                completionHandler(result, error)
            }
        }))
        return self
    }
}

/// A "download-style" request to a file
public class DownloadRequestFile<RSerial: JSONSerializer, ESerial: JSONSerializer>: Request<RSerial, ESerial> {
    let moveToDestination: (URL) throws -> URL
    let errorDataFromLocation: (URL) throws -> Data?

    init(
        request: ApiRequest,
        responseSerializer: RSerial,
        errorSerializer: ESerial,
        moveToDestination: @escaping (URL) throws -> URL,
        errorDataFromLocation: @escaping (URL) throws -> Data?
    ) {
        self.moveToDestination = moveToDestination
        self.errorDataFromLocation = errorDataFromLocation

        super.init(request: request, responseSerializer: responseSerializer, errorSerializer: errorSerializer)
    }

    @discardableResult
    public func progress(_ progressHandler: @escaping ((Progress) -> Void)) -> Self {
        request.setProgressHandler(progressHandler)
        return self
    }

    @discardableResult
    public func response(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping ((RSerial.ValueType, URL)?, CallError<ESerial.ValueType>?) -> Void
    ) -> Self {
        request.setCompletionHandlerProvider(queue: queue, completionHandlerProvider: .downloadFileCompletionHandlerProvider({ [weak self] response in
            guard let strongSelf = self else {
                return {
                    completionHandler(nil, .clientError(.requestObjectDeallocated))
                }
            }

            var (result, error): ((RSerial.ValueType, URL)?, CallError<ESerial.ValueType>?)

            switch response {
            case .success((let tempLocation, let response)):
                var destination: URL
                do {
                    try destination = strongSelf.moveToDestination(tempLocation)
                } catch let _error {
                    return {
                        completionHandler(nil, CallError(clientError: .fileAccessError(_error)))
                    }
                }

                do {
                    let headerFields: [AnyHashable: Any] = response.allHeaderFields
                    let apiResult = try caseInsensitiveLookup("Dropbox-Api-Result", dictionary: headerFields).orThrow(SerializationError.missingResultHeader)
                    let resultData = try apiResult.data(using: .utf8, allowLossyConversion: false).orThrow(SerializationError.missingResultData)

                    let resultObject = try strongSelf.responseSerializer.deserialize(SerializeUtil.parseJSON(resultData))
                    (result, error) = ((resultObject, destination), nil)
                } catch let _error {
                    (result, error) = (nil, CallError.serializationError(_error))
                }
            case .failure(let failure):
                (result, error) = (nil, strongSelf.handleResponseError(networkTaskFailure: failure))
            }

            return {
                completionHandler(result, error)
            }
        }))
        return self
    }
}

/// A "download-style" request to memory
public class DownloadRequestMemory<RSerial: JSONSerializer, ESerial: JSONSerializer>: Request<RSerial, ESerial> {
    @discardableResult
    public func progress(_ progressHandler: @escaping ((Progress) -> Void)) -> Self {
        request.setProgressHandler(progressHandler)
        return self
    }

    @discardableResult
    public func response(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping ((RSerial.ValueType, Data)?, CallError<ESerial.ValueType>?) -> Void
    ) -> Self {
        request.setCompletionHandlerProvider(queue: queue, completionHandlerProvider: .dataCompletionHandlerProvider({ [weak self] response in
            guard let strongSelf = self else {
                return {
                    completionHandler(nil, .clientError(.requestObjectDeallocated))
                }
            }

            var (result, error): ((RSerial.ValueType, Data)?, CallError<ESerial.ValueType>?) = (nil, nil)

            switch response {
            case .success((let data, let response)):
                do {
                    let headerFields: [AnyHashable: Any] = response.allHeaderFields
                    let apiResult = try caseInsensitiveLookup("Dropbox-Api-Result", dictionary: headerFields).orThrow(SerializationError.missingResultHeader)
                    let resultData = try apiResult.data(using: .utf8, allowLossyConversion: false).orThrow(SerializationError.missingResultData)

                    let resultObject = try strongSelf.responseSerializer.deserialize(SerializeUtil.parseJSON(resultData))

                    (result, error) = ((resultObject, data), nil)
                } catch let _error {
                    (result, error) = (nil, CallError.serializationError(_error))
                }
            case .failure(let failure):
                (result, error) = (nil, strongSelf.handleResponseError(networkTaskFailure: failure))
            }

            return {
                completionHandler(result, error)
            }
        }))
        return self
    }
}

private func caseInsensitiveLookup(_ lookupKey: String, dictionary: [AnyHashable: Any]) -> String? {
    for key in dictionary.keys {
        let keyString = key as! String
        if keyString.lowercased() == lookupKey.lowercased() {
            return dictionary[key] as? String
        }
    }
    return nil
}
