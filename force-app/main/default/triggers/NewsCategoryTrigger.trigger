/**
 * Trigger for News_Category__c object to sync news from API when Sync__c field is true
 */
trigger NewsCategoryTrigger on News_Category__c (after insert, after update) {
	NewsCategoryTriggerHandler.handleSync(Trigger.new);
} 