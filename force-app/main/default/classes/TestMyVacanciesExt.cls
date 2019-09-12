@IsTest
public class TestMyVacanciesExt{

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

        System.runAs(recruiter) {
            Candidate__c candidate = new Candidate__c(Status__c = 'Validated By HR');
            insert candidate;
        }
    }

    private static testMethod void TestMyVacanciesExtNoVacancies(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Candidate__c candidate = [SELECT Status__c FROM Candidate__c WHERE OwnerId=:recruiter.Id LIMIT 1];

        System.runAs(recruiter) {
            // Act
            Test.startTest();

            PageReference pref = new PageReference('/'+candidate.Id);
            pref.getParameters().put('id', candidate.Id);
            Test.setCurrentPage(pref);
            
            ApexPages.StandardController stdCtr = new ApexPages.StandardController(candidate);
            MyVacanciesExt objMyVacanciesExt  = new MyVacanciesExt(stdCtr);

            Test.setCurrentPageReference(pref);  //vf page request
            objMyVacanciesExt.onload();

            // Assert 
            System.assertEquals(candidate.Id, objMyVacanciesExt.candidate.Id);
            System.assertEquals(0, objMyVacanciesExt.vacancies.size());

            objMyVacanciesExt.getSelected();
            objMyVacanciesExt.Apply();

            Test.stopTest();
        } 
    }

    private static testMethod void TestMyVacanciesExtHaveVacancyAssignedSelectAndApply(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c vacancy;
        System.runAs(manager) {
            vacancy = new Vacancy__c(Responsible__c=recruiter.Id);
            insert vacancy;
        }
        Candidate__c candidate = [SELECT Status__c FROM Candidate__c WHERE OwnerId=:recruiter.Id LIMIT 1];

        System.runAs(recruiter) {
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());

            // Act
            Test.startTest();

            PageReference pref = new PageReference('/'+candidate.Id);
            pref.getParameters().put('id', candidate.Id);
            Test.setCurrentPage(pref);
            
            ApexPages.StandardController stdCtr = new ApexPages.StandardController(candidate);
            MyVacanciesExt objMyVacanciesExt  = new MyVacanciesExt(stdCtr);

            Test.setCurrentPageReference(pref);  //vf page request
            objMyVacanciesExt.onload();

            objMyVacanciesExt.vacancies[0].selected = true;
            objMyVacanciesExt.getSelected();
            objMyVacanciesExt.Apply();

            Test.stopTest();

            // Assert 
            System.assertEquals(candidate.Id, objMyVacanciesExt.candidate.Id);
            System.assertEquals(1, objMyVacanciesExt.vacancies.size());

            VacancyCandidateAssociation__c[] SelectedVacancies = [SELECT Id FROM VacancyCandidateAssociation__c WHERE Candidate__c = :candidate.Id AND Vacancy__c = :vacancy.Id];
            System.assertEquals(1, SelectedVacancies.size());
        } 
    }

    private static testMethod void TestMyVacanciesExtAddValidatedCandidateDeselectThenApply(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c vacancy;
        System.runAs(manager) {
            vacancy = new Vacancy__c(Responsible__c=recruiter.Id);
            insert vacancy;
        }
        Candidate__c candidate = [SELECT Status__c FROM Candidate__c WHERE OwnerId=:recruiter.Id LIMIT 1];

        System.runAs(recruiter) {
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());

            VacancyCandidateAssociation__c vca = new VacancyCandidateAssociation__c(Vacancy__c=vacancy.Id, Candidate__c=candidate.Id);
            insert vca;

            // Act
            Test.startTest();

            PageReference pref = new PageReference('/'+candidate.Id);
            pref.getParameters().put('id', candidate.Id);
            Test.setCurrentPage(pref);
            
            ApexPages.StandardController stdCtr = new ApexPages.StandardController(candidate);
            MyVacanciesExt objMyVacanciesExt  = new MyVacanciesExt(stdCtr);

            Test.setCurrentPageReference(pref);  //vf page request
            objMyVacanciesExt.onload();

            // Assert
            System.assertEquals(candidate.Id, objMyVacanciesExt.candidate.Id);
            System.assertEquals(1, objMyVacanciesExt.vacancies.size());

            // Act
            objMyVacanciesExt.vacancies[0].selected = false;
            objMyVacanciesExt.getSelected();
            objMyVacanciesExt.Apply();

            // Assert
            VacancyCandidateAssociation__c[] SelectedVacancies = [SELECT Id FROM VacancyCandidateAssociation__c WHERE Candidate__c = :candidate.Id AND Vacancy__c = :vacancy.id];
            System.assertEquals(0, SelectedVacancies.size());
            Test.stopTest();
        } 
    }

    private static testMethod void TestMyVacanciesExtNewCandidateIsNotListed(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        List<Vacancy__c> vacancies = new List<Vacancy__c>();
        System.runAs(manager) {
            vacancies.add(new Vacancy__c());
            vacancies.add(new Vacancy__c(Responsible__c=recruiter.Id, Status__c='Closed'));
            vacancies.add(new Vacancy__c(Responsible__c=recruiter.Id, Status__c='Cancelled'));
            insert vacancies;
        }
        Candidate__c candidate = [SELECT Status__c FROM Candidate__c WHERE OwnerId=:recruiter.Id LIMIT 1];

        System.runAs(recruiter) {
            // Act
            Test.startTest();

            PageReference pref = new PageReference('/'+candidate.Id);
            pref.getParameters().put('id', candidate.Id);
            Test.setCurrentPage(pref);
            
            ApexPages.StandardController stdCtr = new ApexPages.StandardController(candidate);
            MyVacanciesExt objMyVacanciesExt  = new MyVacanciesExt(stdCtr);

            Test.setCurrentPageReference(pref);  //vf page request
            objMyVacanciesExt.onload();

            // Assert 
            System.assertEquals(candidate.Id, objMyVacanciesExt.candidate.Id);
            System.assertEquals(0, objMyVacanciesExt.vacancies.size());

            objMyVacanciesExt.getSelected();
            objMyVacanciesExt.Apply();

            Test.stopTest();
        } 
    }
}