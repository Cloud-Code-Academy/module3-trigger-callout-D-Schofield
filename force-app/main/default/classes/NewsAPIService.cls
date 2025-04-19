/**
 * Service class to interact with the NewsAPI for fetching top headlines
 */
public with sharing class NewsAPIService {
    // TODO: Define API endpoint constants
    private static final String API_NAMED_CREDENTIAL = 'callout:NewsAPI'; //https://newsapi.org
    private static final String API_ENDPOINT = '/v2/top-headlines';

    /**
     * Fetches top headlines for a specified category with pagination support
     * @param category The news category (business, entertainment, general, health, science, sports, technology)
     * @param pageSize Number of results per page (default: 20, max: 100)
     * @param page Page number for pagination
     * @return NewsAPIResponse The wrapper object containing the API response
     */
    public static NewsAPIResponse getTopHeadlinesByCategory(String category, Integer pageSize, Integer page) {
        String endpoint = API_NAMED_CREDENTIAL + API_ENDPOINT + '?category=' + category + '&pageSize=' + pageSize + '&page=' + page;
        HttpResponse res = makeCallout(endpoint);
        NewsAPIResponse newsRS = parseResponse(res.getBody());
        return newsRS;
    }
    
    /**
     * Helper method to make the HTTP callout
     * @param endpoint The full URL with parameters
     * @return HttpResponse The HTTP response
     */
    private static HttpResponse makeCallout(String endpoint) {
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(endpoint); 
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');

        HttpResponse res = new Http().send(req);
        
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
        try{
            NewsAPIResponse newsWrapper = (NewsAPIResponse) JSON.deserialize(jsonResponse, NewsAPIResponse.class);
            return newsWrapper;
        }
        catch(Exception parsingError) {
            String errorMsg = 'Error parsing response to wrapper: ' + parsingError.getMessage() + '.';
            //Logger.error(errorMsg).addTag('NewsAPI');
            //Logger.saveLog();
            throw new NewsAPIException (errorMsg);
        }
    }
   
    /**
     * Custom exception class for NewsAPI errors
     */
    public class NewsAPIException extends Exception {}
} 