@IsTest
public class TestMyCandidatesExt{

    @TestSetup static void setup() {
        // Create common user accounts 
        Profile mp = [SELECT Id FROM Profile WHERE Name='Manager'];
        System.debug('Manager Profile: ' + mp.Id);
        User manager = new User(Alias = 'muser', Email='muser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Los_Angeles', Username='muser@testorg.com');
        manager.ProfileId = mp.Id;
        insert manager;

        Profile rp = [SELECT Id FROM Profile WHERE Name='Recruiter']; 
        System.debug('Recruiter Profile: ' + rp.Id);
        User recruiter = new User(Alias = 'ruser', Email='ruser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Los_Angeles', Username='ruser@testorg.com');
        recruiter.ProfileId = rp.Id;
        insert recruiter;

        System.runAs(manager) {
            Vacancy__c vacancy = new Vacancy__c(Responsible__c=recruiter.Id);
            insert vacancy;
        }
    }

    private static testMethod void TestMyCandidatesExtNoCandidates(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c vacancy;
        List<Vacancy__c> actualVacancy;

        // Act
        System.runAs(manager) {
            vacancy = new Vacancy__c();
            insert vacancy;
        }

        System.runAs(recruiter) {
            actualVacancy = [SELECT Status__c FROM Vacancy__c WHERE Id = : vacancy.Id LIMIT 1];
        }
        
        // Assert
        System.assertEquals(0, actualVacancy.size());
    }

    private static testMethod void TestMyCandidatesExtAddValidatedCandidateThenApply(){
		// Arrange
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c vacancy = [SELECT Status__c, Responsible__c FROM Vacancy__c WHERE Responsible__c=:recruiter.Id LIMIT 1];

        System.runAs(recruiter) {
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
            Candidate__c candidate = new Candidate__c(Status__c = 'Validated By HR');
            insert candidate;

            // Act
            Test.startTest();

            PageReference pref = new PageReference('/'+vacancy.Id);
            pref.getParameters().put('id', vacancy.Id);
            Test.setCurrentPage(pref);
            
            ApexPages.StandardController stdCtr = new ApexPages.StandardController(vacancy);
            MyCandidatesExt objMyCandidatesExt  = new MyCandidatesExt(stdCtr);

            Test.setCurrentPageReference(pref);  //vf page request
            objMyCandidatesExt.onload();

            objMyCandidatesExt.candidates[0].selected = true;
            objMyCandidatesExt.getSelected();
            objMyCandidatesExt.Apply();

            Test.stopTest();

            // Assert 
            System.assertEquals(vacancy.Id, objMyCandidatesExt.vacancy.Id);
            System.assertEquals('In-Process', vacancy.Status__c);
            System.assertEquals(recruiter.Id, vacancy.Responsible__c);
            System.assertEquals(1, objMyCandidatesExt.candidates.size());

            VacancyCandidateAssociation__c[] SelectedVacancies = [SELECT Id FROM VacancyCandidateAssociation__c WHERE Candidate__c = :candidate.Id AND Vacancy__c = :vacancy.Id];
            System.assertEquals(1, SelectedVacancies.size());
        } 
    }

    private static testMethod void TestMyCandidatesExtAddValidatedCandidateDeselectThenApply(){
		// Arrange
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c vacancy = [SELECT Status__c, Responsible__c FROM Vacancy__c WHERE Responsible__c=:recruiter.Id LIMIT 1];

        System.runAs(recruiter) {
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
            Candidate__c candidate = new Candidate__c(Status__c = 'Validated By HR');
            insert candidate;

            VacancyCandidateAssociation__c vca = new VacancyCandidateAssociation__c(Vacancy__c=vacancy.Id, Candidate__c=candidate.Id);
            insert vca;

            // Act
            Test.startTest();

            PageReference pref = new PageReference('/'+vacancy.Id);
            pref.getParameters().put('id', vacancy.Id);
            Test.setCurrentPage(pref);
            
            ApexPages.StandardController stdCtr = new ApexPages.StandardController(vacancy);
            MyCandidatesExt objMyCandidatesExt  = new MyCandidatesExt(stdCtr);

            Test.setCurrentPageReference(pref);  //vf page request
            objMyCandidatesExt.onload();

            // Assert
            System.assertEquals(1, objMyCandidatesExt.candidates.size());
            System.assertEquals(true, objMyCandidatesExt.candidates[0].selected);
            System.assertEquals(recruiter.Id, vacancy.Responsible__c);

            // Act
            objMyCandidatesExt.candidates[0].selected = false;
            objMyCandidatesExt.getSelected();
            objMyCandidatesExt.Apply();

            // Assert 
            System.assertEquals(1, objMyCandidatesExt.candidates.size());

            VacancyCandidateAssociation__c[] SelectedVacancies = [SELECT Id FROM VacancyCandidateAssociation__c WHERE Candidate__c = :candidate.Id AND Vacancy__c = :vacancy.Id];
            System.assertEquals(0, SelectedVacancies.size());
            Test.stopTest();
        } 
    }

    private static testMethod void TestMyCandidatesExtNewCandidateIsNotListed(){
		// Arrange
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c vacancy = [SELECT Status__c, Responsible__c FROM Vacancy__c WHERE Responsible__c=:recruiter.Id LIMIT 1];

        System.runAs(recruiter) {
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
            Candidate__c candidate = new Candidate__c();
            insert candidate;

            // Act
            Test.startTest();

            PageReference pref = new PageReference('/'+vacancy.Id);
            pref.getParameters().put('id', vacancy.Id);
            Test.setCurrentPage(pref);
            
            ApexPages.StandardController stdCtr = new ApexPages.StandardController(vacancy);
            MyCandidatesExt objMyCandidatesExt  = new MyCandidatesExt(stdCtr);

            Test.setCurrentPageReference(pref);  //vf page request
            objMyCandidatesExt.onload();

            // Assert
            System.assertEquals(0, objMyCandidatesExt.candidates.size());
            Test.stopTest();
        } 
    }
}