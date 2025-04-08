/**
 * Service class to interact with the NewsAPI for fetching top headlines
 */
public with sharing class NewsAPIService {
    // TODO: Define API endpoint constants
    private static final String API_NAMED_CREDENTIAL = 'callout:NewsAPI'; //https://newsapi.org
    private static final String API_ENDPOINT = '/v2/top-headlines';

    //private static final Boolean USE_MOCK = TRUE;
    private static final Boolean USE_MOCK = FALSE;
    private static String MOCK_RESPONSE_BODY = [SELECT Id, Body FROM StaticResource WHERE NAME = 'NewsAPIMockResponse' LIMIT 1].Body.toString();
    
    // TODO: Define default parameters
    private static final Integer DEFAULT_PAGE_SIZE = 20; 
    
    /**
     * Fetches top headlines for a specified category with pagination support
     * @param category The news category (business, entertainment, general, health, science, sports, technology)
     * @param pageSize Number of results per page (default: 20, max: 100)
     * @param page Page number for pagination
     * @return NewsAPIResponse The wrapper object containing the API response
     */
    public static NewsAPIResponse getTopHeadlinesByCategory(String category, Integer pageSize, Integer page) {
        // TODO: Implement method to fetch headlines by category
        // - Validate and set defaults for parameters
        // - Build the request URL
        // - Make the callout
        // - Parse and return the response
        String endpoint = API_NAMED_CREDENTIAL + API_ENDPOINT + '?category=' + category + '&pageSize=' + pageSize + '&page=' + page;
        HttpResponse res = makeCallout(endpoint);
        NewsAPIResponse newsRS = parseResponse(res.getBody());
        return newsRS;
    }

    @future(callout=true)
    public static void getTopHeadlinesByCategoryFuture(String categoryName) {
        // futures can't return anything!
        News_Category__c category = [SELECT Id FROM News_Category__c WHERE Name = :categoryName LIMIT 1];
        List<Article__c> articles = new List<Article__c>();
        NewsAPIResponse newsResponse = getTopHeadlinesByCategory(categoryName, DEFAULT_PAGE_SIZE, 1);
        if(newsResponse.articles.size() > 0) {
            articles.addAll(newsResponse.toSObjects(category.Id));
            // retry until no more articles to process? 
        } else {
            // no more articles to process
        }
        try {
            insert articles;
            // update last synced on Category record
        } catch(Exception e) {

        }

    }
    
    /**
     * Helper method to make the HTTP callout
     * @param endpoint The full URL with parameters
     * @return HttpResponse The HTTP response
     */
    private static HttpResponse makeCallout(String endpoint) {
        // TODO: Implement HTTP callout
        // - Create and configure HTTP request
        // - Make the callout
        // - Handle exceptions
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(endpoint); 
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');

        HttpResponse res; 
        if(USE_MOCK) {
            res = getMockResponse();
        }
        else {
            res = new Http().send(req); 
        }
        
        if(res.getStatusCode() == 200) {
            return res;
        } else {
            String logMsg = 'Callout error. Status Code: ' + res.getStatusCode() + ' | Body: ' + res.getBody();
            //Logger.error(logMsg).addTag('NewsAPI');
            //Logger.saveLog();
            throw new NewsAPIException(logMsg);
        }
    }
    
    /**
     * Helper method to parse the JSON response
     * @param jsonResponse The JSON response string
     * @return NewsAPIResponse The parsed response object
     */
    private static NewsAPIResponse parseResponse(String jsonResponse) {
        // TODO: Implement JSON parsing
        // - Deserialize JSON to NewsAPIResponse
        try{
            NewsAPIResponse newsWrapper = (NewsAPIResponse) JSON.deserialize(jsonResponse, NewsAPIResponse.class);
            return newsWrapper;
        }
        catch(Exception parsingError) {
            // - Handle exceptions
            String errorMsg = 'Error parsing response to wrapper: ' + parsingError.getMessage() + '.';
            //Logger.error(errorMsg).addTag('NewsAPI');
            //Logger.saveLog();
            throw new NewsAPIException (errorMsg);
        }
    }

    private static HttpResponse getMockResponse() {
        HttpResponse mockRS = new HttpResponse();
        mockRS.setStatusCode(200);
        mockRS.setBody(MOCK_RESPONSE_BODY);
        return mockRS;
    }
    
    /**
     * Custom exception class for NewsAPI errors
     */
    public class NewsAPIException extends Exception {}
} 