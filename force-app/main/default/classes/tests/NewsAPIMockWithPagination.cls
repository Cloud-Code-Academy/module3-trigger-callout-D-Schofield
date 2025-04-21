public class NewsAPIMockWithPagination implements HttpCalloutMock {
    private static Integer callCount = 0;

    // Implement the respond method from HttpCalloutMock interface
    public HttpResponse respond(HttpRequest req) {
        callCount++;

        HttpResponse res = new HttpResponse();
        
        // Simulate paginated responses based on callCount
        if (callCount == 1) {
            String paginatedBody = '{' +
                '"status": "ok",' +
                '"totalResults": 4,' +
                '"articles": [' +
                    '{' +
                        '"source": {"id": "test-1", "name": "Test Source 1"},' +
                        '"title": "Test Article 1",' +
                        '"description": "Test Description 1",' +
                        '"url": "https://test1.com",' +
                        '"urlToImage": "https://test1.com/image.jpg",' +
                        '"publishedAt": "2024-03-28T12:00:00Z"' +
                    '},' +
                    '{' +
                        '"source": {"id": "test-2", "name": "Test Source 2"},' +
                        '"title": "Test Article 2",' +
                        '"description": "Test Description 2",' +
                        '"url": "https://test2.com",' +
                        '"urlToImage": "https://test2.com/image.jpg",' +
                        '"publishedAt": "2024-03-28T13:00:00Z"' +
                    '}' +
                '],' +
                '"page": 1,' +
                '"totalPages": 2' +
            '}';
            res.setBody(paginatedBody);
        } else if (callCount == 2) {
            String paginatedBody = '{' +
                '"status": "ok",' +
                '"totalResults": 4,' +
                '"articles": [],' +
                '"page": 2,' +
                '"totalPages": 2' +
            '}';
            res.setBody(paginatedBody);
        } else {
            // Simulate no more pages
            throw new CalloutException('No more pages left!');
        }

        res.setStatusCode(200); // Set status code for successful response

        return res;
    }

    // Static method to return the mock class instance for paginated mock
    public static NewsAPIMockWithPagination createPaginatedMock() {
        return new NewsAPIMockWithPagination();
    }
}
