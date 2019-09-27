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
        Vacancy__c Vacancy;
        List<Vacancy__c> actualVacancy;

        System.runAs(manager) {
            Vacancy = new Vacancy__c();
            insert Vacancy;
        }
        
        System.runAs(recruiter) {
            // Act
            actualVacancy = [SELECT Id FROM Vacancy__c WHERE Id = :Vacancy.Id LIMIT 1];
            System.assertEquals(0, actualVacancy.size());
        } 
    }
    
    private static testMethod void TestVacancyApexSharingHasResponsibleSet(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c Vacancy;
        List<Vacancy__c> actualVacancy;

        System.runAs(manager) {
            Vacancy = new Vacancy__c(Responsible__c=recruiter.Id);
            insert Vacancy;
        }
        
        System.runAs(recruiter) {
            // Act
            actualVacancy = [SELECT Id FROM Vacancy__c WHERE Id = :Vacancy.Id LIMIT 1];
            System.assertEquals(1, actualVacancy.size());
        } 
    }
    
    private static testMethod void TestVacancyApexSharingHasResponsibleChanged(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c Vacancy;
        List<Vacancy__c> actualVacancy;

        System.runAs(manager) {
            Vacancy = new Vacancy__c(Responsible__c=recruiter.Id);
            insert Vacancy;
        }
        
        System.runAs(recruiter) {
            // Act
            actualVacancy = [SELECT Id FROM Vacancy__c WHERE Id = :Vacancy.Id LIMIT 1];
            System.assertEquals(1, actualVacancy.size());
        }
        
        System.runAs(manager) {
            Vacancy.Responsible__c=null;
            update Vacancy;
        }
        
        System.runAs(recruiter) {
            // Act
            actualVacancy = [SELECT Id FROM Vacancy__c WHERE Id = :Vacancy.Id LIMIT 1];
            System.assertEquals(0, actualVacancy.size());
        }
    }
    
    private static testMethod void TestVacancyApexSharingHasResponsibleAndGetClosed(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c Vacancy;
        Candidate__c Candidate;
        VacancyCandidateAssociation__c vacancyCandidateAssociation;
        List<Candidate__c> actualCandidate;

        System.runAs(manager) {
            Vacancy = new Vacancy__c(Responsible__c=recruiter.Id);
            insert Vacancy;
        }
        
        System.runAs(recruiter) {
            // Act            
            Candidate = new Candidate__c(Status__c='Validated By HR');
            insert Candidate;
        }

        System.runAs(recruiter) {
            vacancyCandidateAssociation = new VacancyCandidateAssociation__c(Candidate__c= Candidate.Id, Vacancy__c= Vacancy.Id);
            insert vacancyCandidateAssociation;
        }
        
        System.runAs(manager) {
            // Act
            actualCandidate = [SELECT Id FROM Candidate__c WHERE Id = :Candidate.Id LIMIT 1];
            System.assertEquals(1, actualCandidate.size());
            
            Test.startTest();
            Candidate.Status__c = 'Hired';
            Candidate.Vacancies__c = Vacancy.Id;
            update Candidate;
            
            Vacancy.Status__c='Closed';
            Vacancy.Candidate__c= Candidate.Id;
            update Vacancy;
            
            delete vacancyCandidateAssociation;
            Test.stopTest();
            
            // Act
            actualCandidate = [SELECT Id FROM Candidate__c WHERE Id = :Candidate.Id LIMIT 1];
            System.assertEquals(1, actualCandidate.size());
        }
    }
}