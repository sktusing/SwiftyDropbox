///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///
/// Auto-generated by Stone, do not modify.
///

import Foundation

/// Routes for the file_requests namespace
/// For Objective-C compatible routes see DBFileRequestsRoutes
public class FileRequestsRoutes: DropboxTransportClientOwning {
    public let client: DropboxTransportClient
    required init(client: DropboxTransportClient) {
        self.client = client
    }

    /// Returns the total number of file requests owned by this user. Includes both open and closed file requests.
    ///
    /// - scope: file_requests.read
    ///
    ///
    /// - returns: Through the response callback, the caller will receive a `FileRequests.CountFileRequestsResult`
    /// object on success or a `FileRequests.CountFileRequestsError` object on failure.
    @discardableResult public func count() -> RpcRequest<FileRequests.CountFileRequestsResultSerializer, FileRequests.CountFileRequestsErrorSerializer> {
        let route = FileRequests.count
        return client.request(route)
    }

    /// Creates a file request for this user.
    ///
    /// - scope: file_requests.write
    ///
    /// - parameter title: The title of the file request. Must not be empty.
    /// - parameter destination: The path of the folder in the Dropbox where uploaded files will be sent. For apps with
    /// the app folder permission, this will be relative to the app folder.
    /// - parameter deadline: The deadline for the file request. Deadlines can only be set by Professional and Business
    /// accounts.
    /// - parameter open: Whether or not the file request should be open. If the file request is closed, it will not
    /// accept any file submissions, but it can be opened later.
    /// - parameter description_: A description of the file request.
    ///
    /// - returns: Through the response callback, the caller will receive a `FileRequests.FileRequest` object on success
    /// or a `FileRequests.CreateFileRequestError` object on failure.
    @discardableResult public func create(
        title: String,
        destination: String,
        deadline: FileRequests.FileRequestDeadline? = nil,
        open: Bool = true,
        description_: String? = nil
    ) -> RpcRequest<FileRequests.FileRequestSerializer, FileRequests.CreateFileRequestErrorSerializer> {
        let route = FileRequests.create
        let serverArgs = FileRequests.CreateFileRequestArgs(title: title, destination: destination, deadline: deadline, open: open, description_: description_)
        return client.request(route, serverArgs: serverArgs)
    }

    /// Delete a batch of closed file requests.
    ///
    /// - scope: file_requests.write
    ///
    /// - parameter ids: List IDs of the file requests to delete.
    ///
    /// - returns: Through the response callback, the caller will receive a `FileRequests.DeleteFileRequestsResult`
    /// object on success or a `FileRequests.DeleteFileRequestError` object on failure.
    @discardableResult public func delete(ids: [String])
        -> RpcRequest<FileRequests.DeleteFileRequestsResultSerializer, FileRequests.DeleteFileRequestErrorSerializer> {
        let route = FileRequests.delete
        let serverArgs = FileRequests.DeleteFileRequestArgs(ids: ids)
        return client.request(route, serverArgs: serverArgs)
    }

    /// Delete all closed file requests owned by this user.
    ///
    /// - scope: file_requests.write
    ///
    ///
    /// - returns: Through the response callback, the caller will receive a
    /// `FileRequests.DeleteAllClosedFileRequestsResult` object on success or a
    /// `FileRequests.DeleteAllClosedFileRequestsError` object on failure.
    @discardableResult public func deleteAllClosed()
        -> RpcRequest<FileRequests.DeleteAllClosedFileRequestsResultSerializer, FileRequests.DeleteAllClosedFileRequestsErrorSerializer> {
        let route = FileRequests.deleteAllClosed
        return client.request(route)
    }

    /// Returns the specified file request.
    ///
    /// - scope: file_requests.read
    ///
    /// - parameter id: The ID of the file request to retrieve.
    ///
    /// - returns: Through the response callback, the caller will receive a `FileRequests.FileRequest` object on success
    /// or a `FileRequests.GetFileRequestError` object on failure.
    @discardableResult public func get(id: String) -> RpcRequest<FileRequests.FileRequestSerializer, FileRequests.GetFileRequestErrorSerializer> {
        let route = FileRequests.get
        let serverArgs = FileRequests.GetFileRequestArgs(id: id)
        return client.request(route, serverArgs: serverArgs)
    }

    /// Returns a list of file requests owned by this user. For apps with the app folder permission, this will only
    /// return file requests with destinations in the app folder.
    ///
    /// - scope: file_requests.read
    ///
    ///
    /// - returns: Through the response callback, the caller will receive a `FileRequests.ListFileRequestsResult` object
    /// on success or a `FileRequests.ListFileRequestsError` object on failure.
    @discardableResult public func list_() -> RpcRequest<FileRequests.ListFileRequestsResultSerializer, FileRequests.ListFileRequestsErrorSerializer> {
        let route = FileRequests.list_
        return client.request(route)
    }

    /// Returns a list of file requests owned by this user. For apps with the app folder permission, this will only
    /// return file requests with destinations in the app folder.
    ///
    /// - scope: file_requests.read
    ///
    /// - parameter limit: The maximum number of file requests that should be returned per request.
    ///
    /// - returns: Through the response callback, the caller will receive a `FileRequests.ListFileRequestsV2Result`
    /// object on success or a `FileRequests.ListFileRequestsError` object on failure.
    @discardableResult public func listV2(limit: UInt64 = 1_000)
        -> RpcRequest<FileRequests.ListFileRequestsV2ResultSerializer, FileRequests.ListFileRequestsErrorSerializer> {
        let route = FileRequests.listV2
        let serverArgs = FileRequests.ListFileRequestsArg(limit: limit)
        return client.request(route, serverArgs: serverArgs)
    }

    /// Once a cursor has been retrieved from listV2, use this to paginate through all file requests. The cursor must
    /// come from a previous call to listV2 or listContinue.
    ///
    /// - scope: file_requests.read
    ///
    /// - parameter cursor: The cursor returned by the previous API call specified in the endpoint description.
    ///
    /// - returns: Through the response callback, the caller will receive a `FileRequests.ListFileRequestsV2Result`
    /// object on success or a `FileRequests.ListFileRequestsContinueError` object on failure.
    @discardableResult public func listContinue(cursor: String)
        -> RpcRequest<FileRequests.ListFileRequestsV2ResultSerializer, FileRequests.ListFileRequestsContinueErrorSerializer> {
        let route = FileRequests.listContinue
        let serverArgs = FileRequests.ListFileRequestsContinueArg(cursor: cursor)
        return client.request(route, serverArgs: serverArgs)
    }

    /// Update a file request.
    ///
    /// - scope: file_requests.write
    ///
    /// - parameter id: The ID of the file request to update.
    /// - parameter title: The new title of the file request. Must not be empty.
    /// - parameter destination: The new path of the folder in the Dropbox where uploaded files will be sent. For apps
    /// with the app folder permission, this will be relative to the app folder.
    /// - parameter deadline: The new deadline for the file request. Deadlines can only be set by Professional and
    /// Business accounts.
    /// - parameter open: Whether to set this file request as open or closed.
    /// - parameter description_: The description of the file request.
    ///
    /// - returns: Through the response callback, the caller will receive a `FileRequests.FileRequest` object on success
    /// or a `FileRequests.UpdateFileRequestError` object on failure.
    @discardableResult public func update(
        id: String,
        title: String? = nil,
        destination: String? = nil,
        deadline: FileRequests.UpdateFileRequestDeadline = .noUpdate,
        open: Bool? = nil,
        description_: String? = nil
    ) -> RpcRequest<FileRequests.FileRequestSerializer, FileRequests.UpdateFileRequestErrorSerializer> {
        let route = FileRequests.update
        let serverArgs = FileRequests.UpdateFileRequestArgs(
            id: id,
            title: title,
            destination: destination,
            deadline: deadline,
            open: open,
            description_: description_
        )
        return client.request(route, serverArgs: serverArgs)
    }
}
