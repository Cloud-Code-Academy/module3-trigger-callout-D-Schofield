/**
 * Queueable Apex class for processing News Category records with pagination support
 */
public class NewsCategoryQueueable implements Queueable, Database.AllowsCallouts {

    private News_Category__c categoryToProcess;
    private Id categoryId;
    private Integer currentPage;
    private static final Integer DEFAULT_PAGE_SIZE = 20;
    
    /**
     * Constructor
     * @param categoryId The Id of the News_Category__c record
     */
    public NewsCategoryQueueable(Id categoryId) {
        // Initialize first page
        this.categoryId = categoryId;
        this.currentPage = 1;
    }

    /**
     * Constructor
     * @param categoryId The Id of the News_Category__c record
     * @param pageFromPreviousJob page from last job, add one to process next page
     */
    public NewsCategoryQueueable(Id categoryId, Integer pageFromPreviousJob) {
        this.categoryId = categoryId;
        this.currentPage = pageFromPreviousJob + 1;
    }
    
    /**
     * Execute method for the queueable job
     * @param context The QueueableContext
     */
    public void execute(QueueableContext context) {

        Queueable_Switch__c qSwitch = Queueable_Switch__c.getOrgDefaults();
        if (!qSwitch.Run_News_API__c) {
            //Logger.error('job aborted, Custom Setting switch is OFF').addTag('NewsAPI');
            //Logger.saveLog();
            return;
        }

        this.categoryToProcess = [SELECT Id, Name, Sync__c, Last_Synced__c
                                  FROM News_Category__c
                                  WHERE Id = :this.categoryId
                                  LIMIT 1
                                 ];
        // - Call NewsAPI for the current page
        NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory(this.categoryToProcess.Name, DEFAULT_PAGE_SIZE, this.currentPage);
        
        if(response.articles.size() > 0) {
            // - Chain to next page if more pages exist
            insertArticles(response); 
            enqueueNextJob();         
        } else {
            // - Update category if last page
            updateCategory();
            //Logger.info('No more articles to process for category:').addTag('NewsAPI');
            //Logger.saveLog(); 
        }
    }

    private List<Article__c> insertArticles(NewsAPIResponse response) {
        List<Article__c> articles = response.toSObjects(this.categoryToProcess);
        // - Process and save articles
        try{
            insert articles; 
            return articles;
        } catch(Exception e) {
            // log error
            throw new NewsCategoryQueueableException();
        }
    }
    
    private void updateCategory() {
        this.categoryToProcess.Last_Synced__c = Datetime.now();
        this.categoryToProcess.Sync__c = false;
        update this.categoryToProcess;
    }

    private Id enqueueNextJob() {
        // can do multiple jobs in test context, but category still needs to be updated
        if(Test.isRunningTest()) {
            updateCategory();
            return null;
        }
        NewsCategoryQueueable nextJob = new NewsCategoryQueueable(this.categoryId, this.currentPage);
        ID jobID = System.enqueueJob(nextJob);
        //Logger.info('Starting another queueable job: ' + jobID).addTag('NewsAPI');
        //Logger.saveLog();
        return jobID;
    }

    /**
     * Custom exception class for NewsAPI errors
     */
    public class NewsCategoryQueueableException extends Exception {}

} 