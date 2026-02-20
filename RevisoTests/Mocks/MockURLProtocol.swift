//
//  MockURLProtocol.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Foundation

final class MockURLProtocol: URLProtocol {
    private static let lock = NSLock()

    private static var _mockResponseData: Data?
    private static var _mockStatusCode: Int = 200
    private static var _mockError: Error?
    private static var _lastRequest: URLRequest?
    private static var _lastRequestBody: Data?

    static var mockResponseData: Data? {
        get { lock.withLock { _mockResponseData } }
        set { lock.withLock { _mockResponseData = newValue } }
    }

    static var mockStatusCode: Int {
        get { lock.withLock { _mockStatusCode } }
        set { lock.withLock { _mockStatusCode = newValue } }
    }

    static var mockError: Error? {
        get { lock.withLock { _mockError } }
        set { lock.withLock { _mockError = newValue } }
    }

    static var lastRequest: URLRequest? {
        get { lock.withLock { _lastRequest } }
        set { lock.withLock { _lastRequest = newValue } }
    }

    static var lastRequestBody: Data? {
        get { lock.withLock { _lastRequestBody } }
        set { lock.withLock { _lastRequestBody = newValue } }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        lastRequest = request
        // Capture httpBody here since URLSession may convert it to a stream later
        if let body = request.httpBody {
            lastRequestBody = body
        }
        return request
    }

    override func startLoading() {
        // Also try to capture body from the stream if httpBody was nil in canonicalRequest
        if MockURLProtocol.lastRequestBody == nil {
            if let body = request.httpBody {
                MockURLProtocol.lastRequestBody = body
            } else if let stream = request.httpBodyStream {
                MockURLProtocol.lastRequestBody = Self.readStream(stream)
            }
        }

        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: MockURLProtocol.mockStatusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        if let data = MockURLProtocol.mockResponseData {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset() {
        lock.withLock {
            _mockResponseData = nil
            _mockStatusCode = 200
            _mockError = nil
            _lastRequest = nil
            _lastRequestBody = nil
        }
    }

    private static func readStream(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let count = stream.read(buffer, maxLength: bufferSize)
            if count > 0 {
                data.append(buffer, count: count)
            } else {
                break
            }
        }
        return data
    }
}
