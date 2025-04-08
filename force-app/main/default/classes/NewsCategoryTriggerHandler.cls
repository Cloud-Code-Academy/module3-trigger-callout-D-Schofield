/**
 * Handler class for NewsCategoryTrigger
 */
public with sharing class NewsCategoryTriggerHandler {
    
    /**
     * Handles after insert events for News_Category__c
     * Uses Future method for callouts when Sync__c is true
     * @param newRecords List of newly inserted News_Category__c records
     */
    public static void handleInsert(List<News_Category__c> newRecords) {
        // TODO: Implement insert handler
        // - Filter categories that need to be synced
        List<String> categoryNamesToSync = new List<String>();
        for(News_Category__c category : newRecords) {
            System.debug('**Category name: ' + category.Name + ' | sync: ' + category.Sync__c);
            if(category.Sync__c) {
                categoryNamesToSync.add(category.Name);
            }
        }
        System.debug('cat names to sync: ' + categoryNamesToSync.size());
        // - Call future method for callouts
        if(categoryNamesToSync.size() > 0) {
            syncCategoriesWithFuture(categoryNamesToSync);
        }
    }
    
    /**
     * Handles after update events for News_Category__c
     * Uses Queueable Apex for callouts when Sync__c is true
     * @param newRecords List of updated News_Category__c records
     * @param oldMap Map of old record states
     */
    public static void handleUpdate(List<News_Category__c> newRecords, Map<Id, News_Category__c> oldMap) {
        // TODO: Implement update handler
        // - Filter categories that need to be synced
        List<News_Category__c> categoriesToSync = new List<News_Category__c>();
        for(News_Category__c category : newRecords) {
            if(category.Sync__c) {
                categoriesToSync.add(category);
            }
        }
        // - Call queueable method for callouts
        if(categoriesToSync.size() > 0) {
            syncCategoriesWithQueueable(categoriesToSync);
        }
    }
    
    /**
     * Future method to sync categories using the NewsAPI
     * Used for insert operations
     * @param categoryNames List of category names to sync
     */
    @future(callout=true)
    public static void syncCategoriesWithFuture(List<String> categoryNames) {
        System.debug('**syncCategoriesWithFuture called');
        // TODO: Implement future method
        // - Get categories by name
        List<News_Category__c> categories = [SELECT Id, Name FROM News_Category__c WHERE Name IN :categoryNames];
        // - Make callouts to NewsAPI for each category
        for(News_Category__c category : categories) {
            // this is not a future method yet - need to implement it
            try{
                NewsAPIService.getTopHeadlinesByCategoryFuture(category.Name);
                category.Last_Synced__c = Datetime.now();
            } catch(Exception e) {

            }
            // future method is void, doesn't return anything
        }
        update categories;
        // - Insert retrieved articles
        // - Update categories with last synced date
        // don't love this, should make sure the article insert is successful before updating the category
        // could probably do it better in queueable - one job per category
    }
    
    /**
     * Queueable method to sync categories using the NewsAPI
     * Used for update operations
     * @param categoriesToSync List of News_Category__c records to sync
     */
    private static void syncCategoriesWithQueueable(List<News_Category__c> categoriesToSync) {
        // TODO: Implement queueable job enqueuing
        // - Determine pages to sync for each category???
        // - Create and enqueue NewsCategoryQueueable job for each category
        for(News_Category__c category : categoriesToSync) {
            Integer pages = 1; // ?? placeholder, don't know what this is
            NewsCategoryQueueable queueableJob = new NewsCategoryQueueable(category.Id, category.Name, pages); 
            System.enqueueJob(queueableJob);
        }
    }
    
} 