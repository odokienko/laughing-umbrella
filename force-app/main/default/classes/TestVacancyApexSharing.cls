@IsTest
public class TestVacancyApexSharing{

    @TestSetup static void setup() {
        // Create common user accounts 
        Profile mp = [SELECT Id FROM Profile WHERE Name='Manager']; 
        User manager = new User(Alias = 'muser', Email='muser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Los_Angeles', Username='muser@testorg.com');
        manager.ProfileId = mp.Id;
        insert manager;

        Profile rp = [SELECT Id FROM Profile WHERE Name='Recruiter'];
        User recruiter = new User(Alias = 'ruser', Email='ruser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Los_Angeles', Username='ruser@testorg.com');
        recruiter.ProfileId = rp.Id;
        insert recruiter;
    }

    private static testMethod void TestVacancyApexSharingNoResponsibleSet(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c vacancy;
        List<Vacancy__c> actualVacancy;

        System.runAs(manager) {
            vacancy = new Vacancy__c();
            insert vacancy;
        }
        
        System.runAs(recruiter) {
            // Act
            actualVacancy = [SELECT Id FROM Vacancy__c WHERE Id = :vacancy.Id LIMIT 1];
            System.assertEquals(0, actualVacancy.size());
        } 
    }
    
    private static testMethod void TestVacancyApexSharingHasResponsibleSet(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c vacancy;
        List<Vacancy__c> actualVacancy;

        System.runAs(manager) {
            vacancy = new Vacancy__c(Responsible__c=recruiter.Id);
            insert vacancy;
        }
        
        System.runAs(recruiter) {
            // Act
            actualVacancy = [SELECT Id FROM Vacancy__c WHERE Id = :vacancy.Id LIMIT 1];
            System.assertEquals(1, actualVacancy.size());
        } 
    }
    
    private static testMethod void TestVacancyApexSharingHasResponsibleChanged(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c vacancy;
        List<Vacancy__c> actualVacancy;

        System.runAs(manager) {
            vacancy = new Vacancy__c(Responsible__c=recruiter.Id);
            insert vacancy;
        }
        
        System.runAs(recruiter) {
            // Act
            actualVacancy = [SELECT Id FROM Vacancy__c WHERE Id = :vacancy.Id LIMIT 1];
            System.assertEquals(1, actualVacancy.size());
        }
        
        System.runAs(manager) {
            vacancy.Responsible__c=null;
            update vacancy;
        }
        
        System.runAs(recruiter) {
            // Act
            actualVacancy = [SELECT Id FROM Vacancy__c WHERE Id = :vacancy.Id LIMIT 1];
            System.assertEquals(0, actualVacancy.size());
        }
    }
    
    private static testMethod void TestVacancyApexSharingHasResponsibleAndGetClosed(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c vacancy;
        Candidate__c candidate;
        VacancyCandidateAssociation__c vca;
        List<Candidate__c> actualCandidate;

        System.runAs(manager) {
            vacancy = new Vacancy__c(Responsible__c=recruiter.Id);
            insert vacancy;
        }
        
        System.runAs(recruiter) {
            // Act            
            candidate = new Candidate__c(Status__c='Validated By HR');
            insert candidate;
        }
        
        //System.runAs(manager) {
        //    // Act
        //    actualCandidate = [SELECT Id FROM Candidate__c WHERE Id = :candidate.Id LIMIT 1];
        //    System.assertEquals(0, actualCandidate.size());
        //}
        
        System.runAs(recruiter) {
            vca = new VacancyCandidateAssociation__c(Candidate__c=candidate.Id, Vacancy__c=vacancy.Id);
            insert vca;
        }
        
        System.runAs(manager) {
            // Act
            actualCandidate = [SELECT Id FROM Candidate__c WHERE Id = :candidate.Id LIMIT 1];
            System.assertEquals(1, actualCandidate.size());
            
            Test.startTest();
            candidate.Status__c = 'Hired';
            candidate.Vacancies__c = vacancy.Id;
            update candidate;
            
            vacancy.Status__c='Closed';
            vacancy.Candidate__c=candidate.Id;
            update vacancy;
            
            delete vca;
            Test.stopTest();
            
            // Act
            actualCandidate = [SELECT Id FROM Candidate__c WHERE Id = :candidate.Id LIMIT 1];
            System.assertEquals(1, actualCandidate.size());
        }
    }
}