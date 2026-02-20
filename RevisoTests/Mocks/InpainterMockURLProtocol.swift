//
//  InpainterMockURLProtocol.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import Foundation

/// Isolated mock URL protocol for AIInpainterTests to avoid
/// shared static state with MockURLProtocol used by AIProviderTests.
final class InpainterMockURLProtocol: URLProtocol {
    private static let lock = NSLock()

    private static var _mockResponseData: Data?
    private static var _mockStatusCode: Int = 200
    private static var _mockError: Error?

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

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        if let error = InpainterMockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: InpainterMockURLProtocol.mockStatusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        if let data = InpainterMockURLProtocol.mockResponseData {
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
        }
    }
}
