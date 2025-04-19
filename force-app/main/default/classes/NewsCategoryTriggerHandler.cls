/**
 * Handler class for NewsCategoryTrigger
 */
public with sharing class NewsCategoryTriggerHandler {

    /**
     * Handles after update events for News_Category__c
     * Uses Queueable Apex for callouts when Sync__c is true
     * @param newRecords List of updated News_Category__c records
     */
    public static void handleSync(List<News_Category__c> recordsToSync) {
        // - Filter categories that need to be synced
        List<News_Category__c> categoriesToSync = new List<News_Category__c>();
        for(News_Category__c category : recordsToSync) {
            if(category.Sync__c) {
                categoriesToSync.add(category);
            }
        }
        if(categoriesToSync.size() > 0) {
            syncCategoriesWithQueueable(categoriesToSync);
        }
    }
    
    /**
     * Queueable method to sync categories using the NewsAPI
     * Used for update operations
     * @param categoriesToSync List of News_Category__c records to sync
     */
    private static void syncCategoriesWithQueueable(List<News_Category__c> categoriesToSync) {
        List<News_Category__c> categoriesToUpdate = new List<News_Category__c>();
        for(News_Category__c category : categoriesToSync) {
            NewsCategoryQueueable queueableJob = new NewsCategoryQueueable(category.Id); 
            System.enqueueJob(queueableJob);
        }
    }
    
} 