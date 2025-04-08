/**
 * Wrapper class for parsing the NewsAPI response
 */
public class NewsAPIResponse {

    public String status { get; set; }
    public Integer totalResults { get; set; }
    public List<Article> articles { get; set; }
    
    /**
     * Inner class representing a news article
     */
    public class Article {
        public Source source;
        public String author;
        public String title;
        public String description;
        public String url;
        public String urlToImage;
        public String publishedAt;
        public String content;

        /**
         * Converts the API article to a Salesforce Article__c record
         * @return Article__c The Salesforce record
         */
        public Article__c toSObject(String categoryId) {
            // TODO: Implement conversion from API article to Salesforce record
            // Consider:
            // - Handling date conversion
            // - Generating a unique record name
            // - Handling field length limits 

            // ** lots of queries for category record, maybe pass as parameter
            News_Category__c category = [SELECT Id, Name FROM News_Category__c WHERE Id = :categoryId LIMIT 1];
        
            String publishedAtIso = null;
            Datetime publishedAtDT = null;

            if (this.publishedAt != null && this.publishedAt != '') {
                publishedAtIso = this.publishedAt.replace('T', ' ').replace('Z', ''); // 2024-03-28T12:00:00Z -> 2024-03-28 12:00:00
                publishedAtDT = Datetime.valueOfGmt(publishedAtIso);
            }
            Article__c article = new Article__c(
                Author__c       = this.author, // ?
                Category__c     = category.Name,
                Content__c      = this.content,
                Country__c      = '',
                Description__c  = this.description,
                News_Category__c = categoryId,
                Published_At__c = publishedAtDT,
                Source__c       = this.source.name,
                Title__c        = this.title,
                url__c          = this.url,
                urlToImage__c   = this.urlToImage
            );
            return article;
        }
    }
    
    /**
     * Inner class representing a news source
     */
    public class Source {
        public String id;
        public String name;
    }
    
    /**
     * Helper method to convert all articles in this response to Salesforce records
     * @return List<Article__c> List of Salesforce records
     */
    public List<Article__c> toSObjects(String categoryId) {
        // TODO: Implement conversion of all articles to Salesforce records
        List<Article__c> articles = new List<Article__c>();
        for(Article article : this.articles) {
            articles.add( article.toSObject(categoryId) );
        }
        return articles;
    }
} 