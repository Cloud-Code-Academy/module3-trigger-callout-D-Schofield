/**
 * Queueable Apex class for processing News Category records with pagination support
 */
public class NewsCategoryQueueable implements Queueable, Database.AllowsCallouts {
    private Id categoryId;
    private String categoryName;
    private Integer pages;
    private Integer currentPage;
    
    @testVisible
    private static Boolean doChainJob = true;
    
    /**
     * Constructor
     * @param categoryId The Id of the News_Category__c record
     * @param categoryName The category name
     * @param pages Total pages to sync
     */
    public NewsCategoryQueueable(Id categoryId, String categoryName, Integer pages) {
        // TODO: Initialize first page
        this.categoryId = categoryId; 
        this.categoryName = categoryName; 
        this.pages = pages; 
        this.currentPage = 1;
    }
    
    /**
     * Constructor with current page
     * @param categoryId The Id of the News_Category__c record
     * @param categoryName The category name
     * @param pages Total pages to sync
     * @param currentPage Current page being processed
     */
    public NewsCategoryQueueable(Id categoryId, String categoryName, Integer pages, Integer pageFromPreviousJob) {
        // TODO: Initialize with specific page
        this.categoryId = categoryId; 
        this.categoryName = categoryName; 
        this.pages = pages; 
        this.currentPage = pageFromPreviousJob + 1;
    }
    
    /**
     * Execute method for the queueable job
     * @param context The QueueableContext
     */
    public void execute(QueueableContext context) {
        // *Implement a switch to prevent run away jobs

        // TODO: Implement execute method
        // - Call NewsAPI for the current page
        NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory(this.categoryName, 20, this.currentPage); ///default page size 20? 
        if(response.articles.size() > 0) {
            // - Chain to next page if more pages exist
            insertArticles(response); 
            if( !Test.isRunningTest() ) { // doChainJob 
                enqueueNextJob(); 
            }
            // should category be updated here or from the Trigger/Trigger handler? 
            updateCategory(this.categoryId);
        } else {
            // - Update category if last page
            Logger.info('No more articles to process for category:').addTag('NewsAPI');
            Logger.saveLog(); 
        }
    }

    private List<Article__c> insertArticles(NewsAPIResponse response) {
        List<Article__c> articles = response.toSObjects(this.categoryId);
        // - Process and save articles
        try{
            insert articles; 
            return articles;
        } catch(Exception e) {
            // log error
            throw new NewsCategoryQueueableException();
        }
    }

    private News_Category__c updateCategory(String categoryId) {
        News_Category__c category = [SELECT Id FROM News_Category__c WHERE Id = :categoryId LIMIT 1];
        category.Last_Synced__c = Datetime.now();
        category.Sync__c = false;
        update category;
        return category;
    }

    private Id enqueueNextJob() {
        NewsCategoryQueueable nextJob = new NewsCategoryQueueable(this.categoryId, this.categoryName, this.pages, this.currentPage);
        ID jobID = System.enqueueJob(nextJob);
        Logger.info('Starting another queueable job: ' + jobID).addTag('NewsAPI');
        Logger.saveLog();
        return jobID;
    }

    /**
     * Custom exception class for NewsAPI errors
     */
    public class NewsCategoryQueueableException extends Exception {}

} 