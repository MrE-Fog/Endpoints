import XCTest
@testable import Endpoints

class RequestTests: XCTestCase {    
    func testRelativeRequestEncoding() {
        let base = "https://httpbin.org/"
        let queryParams = [ "q": "Äin €uro", "a": "test" ]
        let encodedQueryString = "q=%C3%84in%20%E2%82%ACuro&a=test"
        let expectedUrlString = "https://httpbin.org/get?\(encodedQueryString)"
        
        var req = testRequestEncoding(baseUrl: base, path: "get", queryParams: queryParams)
        XCTAssertEqual(req.url?.absoluteString, expectedUrlString)
        
        req = testRequestEncoding(baseUrl: base + "get", queryParams: queryParams)
        XCTAssertEqual(req.url?.absoluteString, expectedUrlString)
    }
    
    func testHATEOASRequest() {
        let absoluteURL = URL(string: "https://httpbin.org/get?x=z")!
        let body = try! JSONEncodedBody(jsonObject: [ "x": "y" ])
        
        var req = Request(.get, "post", query: ["x": "y"], header: [ "x": "y" ], body: body)
        req.url = absoluteURL
        let c = AnyCall<Data>(req)
        
        let urlReq = AnyClient(baseURL: URL(string: "http://google.com")!).encode(call: c)
        
        XCTAssertEqual(urlReq.url, absoluteURL)
        XCTAssertEqual(urlReq.httpBody, body.requestData)
        XCTAssertEqual(urlReq.allHTTPHeaderFields?["Content-Type"], "application/json")
        XCTAssertEqual(urlReq.allHTTPHeaderFields?["x"], "y")
    }
    
    func testEmptyCurlRepresentation() {
        let r = Request(.get, url: URL(string: "https://httpbin.org/get?x=z")!, header: [ "a": "b"], body: "BODY".data(using: .utf8))
        let curl = r.cURLRepresentation(prettyPrinted: false)
        
        print(curl)
        print(r.cURLRepresentation(prettyPrinted: true))
        
        XCTAssertEqual(curl, "$ curl -i -X GET -H \"a: b\" -d \"BODY\" \"https://httpbin.org/get?x=z\"")
    }
    
    func testEmptyBodyCurlRepresentation() {
        let r = Request(.get, url: URL(string: "https://httpbin.org/get?x=z")!, header: [ "a": "b"])
        let curl = r.cURLRepresentation(prettyPrinted: false)
        
        print(curl)
        print(r.cURLRepresentation(prettyPrinted: true))
        
        XCTAssertEqual(curl, "$ curl -i -X GET -H \"a: b\" -d \"\" \"https://httpbin.org/get?x=z\"", "-d should always be added for correct Content-Length header")
    }
    
    func testBinaryDataCurlRepresentation() {
        let url = Bundle(for: RequestTests.self).url(forResource: "binary", withExtension: "jpg")!
        let body = try! Data(contentsOf: url)
        let r = Request(.get, url: URL(string: "https://httpbin.org/get?x=z")!, header: [ "a": "b"], body: body)
        let curl = r.cURLRepresentation(prettyPrinted: false, bodyEncoding: .utf8)
        
        print(curl)
        print(r.cURLRepresentation(prettyPrinted: true))
        
        XCTAssertEqual(curl, "$ curl -i -X GET -H \"a: b\" -d \"<binary data (420 bytes) not convertible to Unicode (UTF-8)>\" \"https://httpbin.org/get?x=z\"", "binary data")
    }
}

extension RequestTests {
    func testRequestEncoding(baseUrl: String, path: String?=nil, queryParams: [String: String]?=nil) -> URLRequest {
        let request = Request(.get, path, query: queryParams)
        let call = AnyCall<Data>(request)
        let client = AnyClient(baseURL: URL(string: baseUrl)!)
        let urlRequest = client.encode(call: call)
        
        let exp = expectation(description: "")
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            let httpResponse = response as! HTTPURLResponse
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            XCTAssertEqual(httpResponse.statusCode, 200)
            
            exp.fulfill()
        }.resume()
        
        waitForExpectations(timeout: 10, handler: nil)
        
        return urlRequest
    }
}
