@IsTest
private class NewsCategoryTriggerTest {
    
    @TestSetup
    static void setup() {
        // Set org-wide default value
        Queueable_Switch__c orgDefaults = new Queueable_Switch__c(
            SetupOwnerId = UserInfo.getOrganizationId(), // Important!
            Run_News_API__c = true
        );
        insert orgDefaults;

        // Create test data
        List<News_Category__c> categories = new List<News_Category__c>{

            // caused error testInsertWithSyncFalse if this is inserted in testSetup
            /*new News_Category__c(
                Name = 'Technology',
                Sync__c = true,  
                Pages__c = 1
            ),*/

            new News_Category__c(
                Name = 'Business',
                Sync__c = false,
                Pages__c = 1
            )
        };
        insert categories;
    }
    
    @IsTest
    static void testInsertWithSyncTrue() {
        // Set up the mock for API callout
        Test.setMock(HttpCalloutMock.class, NewsAPIMock.createSuccessMock());
        
        Test.startTest();
        
        // Create a new category with Sync__c = true
        News_Category__c newCategory = new News_Category__c(
            Name = 'Science',
            Sync__c = true,
            Pages__c = 1
        );
        insert newCategory;
        
        Test.stopTest();
        
        // Verify the category was updated with Last_Synced__c
        News_Category__c updatedCategory = [
            SELECT Id, Last_Synced__c, Sync__c 
            FROM News_Category__c 
            WHERE Id = :newCategory.Id
        ];
        Assert.isNotNull(updatedCategory.Last_Synced__c, 'Last_Synced__c should be set');
        Assert.areEqual(false, updatedCategory.Sync__c, 'Sync__c should be set to false');
        
        // Verify articles were created
        List<Article__c> articles = [
            SELECT Id, Category__c, News_Category__c 
            FROM Article__c 
            WHERE News_Category__c = :newCategory.Id
        ];
        Assert.areEqual(2, articles.size(), 'Should have created 2 articles');
        Assert.areEqual('Science', articles[0].Category__c, 'Article category should match');
    }
    
    @IsTest
    static void testInsertWithSyncFalse() {
        Test.startTest();
        
        // Create a new category with Sync__c = false
        News_Category__c newCategory = new News_Category__c(
            Name = 'Sports',
            Sync__c = false,
            Pages__c = 1
        );
        insert newCategory;
        
        Test.stopTest();
        
        // Verify no articles were created
        List<Article__c> articles = [
            SELECT Id 
            FROM Article__c 
            WHERE News_Category__c = :newCategory.Id
        ];
        // testsetup will always run
        // it creates technology sync True and business sync false
        Assert.areEqual(0, articles.size(), 'Should not have created any articles');
    }
    
    @IsTest
    static void testUpdateWithSyncChangeToTrue() {
        // Set up the mock for API callout
        Test.setMock(HttpCalloutMock.class, NewsAPIMock.createSuccessMock());

        // Get the business category
        News_Category__c category = [
            SELECT Id, Sync__c 
            FROM News_Category__c 
            WHERE Name = 'Business'
        ];

        Test.startTest();
        // Update Sync__c to true
        category.Sync__c = true;
        update category;
        Test.stopTest();
        
        // Verify the category was updated with Last_Synced__c
        News_Category__c updatedCategory = [
            SELECT Id, Last_Synced__c, Sync__c 
            FROM News_Category__c 
            WHERE Id = :category.Id
        ];
        Assert.isNotNull(updatedCategory.Last_Synced__c, 'Last_Synced__c should be set');
        Assert.areEqual(false, updatedCategory.Sync__c, 'Sync__c should be set to false');
        
        // Verify articles were created
        List<Article__c> articles = [
            SELECT Id, Category__c, News_Category__c 
            FROM Article__c 
            WHERE News_Category__c = :category.Id
        ];
        Assert.areEqual(2, articles.size(), 'Should have created 2 articles');
        Assert.areEqual('Business', articles[0].Category__c, 'Article category should match');
    }
    
    @IsTest
    static void testUpdateWithNoRelevantChanges() {
        // Get the business category
        News_Category__c category = [
            SELECT Id, Sync__c, Pages__c 
            FROM News_Category__c 
            WHERE Name = 'Business'
        ];
        
        Test.startTest();
        
        // Update with no changes to Sync__c or Pages__c
        category.Name = 'Business Updated';
        update category;
        
        Test.stopTest();
        
        // Verify no articles were created
        List<Article__c> articles = [
            SELECT Id 
            FROM Article__c 
            WHERE News_Category__c = :category.Id
        ];
        Assert.areEqual(0, articles.size(), 'Should not have created any articles');
    }

} 