@IsTest
public class TestManageVacanciesExt{

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
        Vacancy__c vacancy;
        System.runAs(manager) {
            List <Vacancy__c> lstVacancy = new List<Vacancy__c>();

            insert  lstVacancy;
 
            // Act
            Test.startTest();
            Test.setCurrentPage(Page.ManageVacancies);
            ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstVacancy);
            stdSetController.setSelected(lstVacancy);
            ManageVacanciesExt ext = new ManageVacanciesExt(stdSetController);

            ext.onload();
            ext.getSelected();

            Test.stopTest();
        }
    }

    private static testMethod void TestMyVacanciesExtHaveVacancy(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c vacancy;
        System.runAs(manager) {
            List <Vacancy__c> lstVacancy = new List<Vacancy__c>();
 
            Vacancy__c testVacancy = new Vacancy__c(Responsible__c=recruiter.Id);
            lstVacancy.add(testVacancy);
            Vacancy__c testVacancy1 = new Vacancy__c(Responsible__c=recruiter.Id);
            lstVacancy.add(testVacancy1);

            insert  lstVacancy;
 
            // Act
            Test.startTest();
            Test.setCurrentPage(Page.ManageVacancies);
            ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstVacancy);
            stdSetController.setSelected(lstVacancy);
            ManageVacanciesExt ext = new ManageVacanciesExt(stdSetController);

            ext.onload();
            ext.getSelected();

            Test.stopTest();
        }
    }

    private static testMethod void TestMyVacanciesExtHaveVacancySelected(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c vacancy;
        System.runAs(manager) {
            List <Vacancy__c> lstVacancy = new List<Vacancy__c>();
 
            Vacancy__c testVacancy = new Vacancy__c(Responsible__c=recruiter.Id);
            lstVacancy.add(testVacancy);
            Vacancy__c testVacancy1 = new Vacancy__c(Responsible__c=recruiter.Id);
            lstVacancy.add(testVacancy1);

            insert  lstVacancy;
 
            // Act
            Test.startTest();
            Test.setCurrentPage(Page.ManageVacancies);
            ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstVacancy);
            stdSetController.setSelected(lstVacancy);
            ManageVacanciesExt ext = new ManageVacanciesExt(stdSetController);

            
            ext.onload();
            ext.vacList[0].selected = true;
            ext.getSelected();

            Test.stopTest();
        }
    }

    private static testMethod void TestMyVacanciesExtHaveVacancySelectedAndCancelled(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c vacancy;
        System.runAs(manager) {
            List <Vacancy__c> lstVacancy = new List<Vacancy__c>();
 
            Vacancy__c testVacancy = new Vacancy__c(Responsible__c=recruiter.Id);
            lstVacancy.add(testVacancy);
            Vacancy__c testVacancy1 = new Vacancy__c(Responsible__c=recruiter.Id);
            lstVacancy.add(testVacancy1);

            insert  lstVacancy;
 
            // Act
            Test.startTest();
            Test.setCurrentPage(Page.ManageVacancies);
            ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstVacancy);
            stdSetController.setSelected(lstVacancy);
            ManageVacanciesExt ext = new ManageVacanciesExt(stdSetController);

            
            ext.onload();
            ext.vacList[0].selected = true;
            ext.getSelected();
            Map<Id, List<Candidate__c>> vacancyCandidateDetails = ext.vacancyCandidateDetailsMap;
            ext.cancelVacancies();

            Test.stopTest();
        }
    }

    private static testMethod void TestMyVacanciesExtHaveVacancyAndCandidatesSelectedAndClosed(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c vacancy;
        Candidate__c candidate;
        



        System.runAs(manager) {
            List <Vacancy__c> lstVacancy = new List<Vacancy__c>();
 
            Vacancy__c testVacancy = new Vacancy__c(Responsible__c=recruiter.Id);
            lstVacancy.add(testVacancy);
            Vacancy__c testVacancy1 = new Vacancy__c(Responsible__c=recruiter.Id);
            lstVacancy.add(testVacancy1);
            insert  lstVacancy;

            

            System.runAs(recruiter) {
                candidate = [SELECT Status__c FROM Candidate__c WHERE OwnerId=:recruiter.Id LIMIT 1];
                vacancy = [SELECT Status__c FROM Vacancy__c LIMIT 1];
                VacancyCandidateAssociation__c vca = new VacancyCandidateAssociation__c(Vacancy__c=vacancy.Id, Candidate__c=candidate.Id);
                insert vca;
            }
 
            // Act
            Test.startTest();
            Test.setCurrentPage(Page.ManageVacancies);
            ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstVacancy);
            stdSetController.setSelected(lstVacancy);
            ManageVacanciesExt ext = new ManageVacanciesExt(stdSetController);

            
            ext.onload();
            ext.vacList[0].selected = true;
            Map<Id, List<Candidate__c>> vacancyCandidateDetails = ext.vacancyCandidateDetailsMap;
            ext.vacList[0].vacancy.Candidate__c = candidate.Id;
            ext.getSelected();

            ext.closeVacancies();

            Test.stopTest();
        }
    }

    // private static testMethod void TestMyVacanciesExtHaveVacancyAndCandidatesDuplicatesSelectedAndClosed(){
	// 	// Arrange
    //     User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
    //     User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
    //     Vacancy__c vacancy;
    //     Candidate__c candidate;

    //     System.runAs(manager) {
    //         List <Vacancy__c> lstVacancy = new List<Vacancy__c>();
 
    //         Vacancy__c testVacancy = new Vacancy__c(Responsible__c=recruiter.Id);
    //         lstVacancy.add(testVacancy);
    //         Vacancy__c testVacancy1 = new Vacancy__c(Responsible__c=recruiter.Id);
    //         lstVacancy.add(testVacancy1);
    //         insert  lstVacancy;

            

    //         System.runAs(recruiter) {
    //             candidate = [SELECT Status__c FROM Candidate__c WHERE OwnerId=:recruiter.Id LIMIT 1];
    //             List<VacancyCandidateAssociation__c> vcas = new List<VacancyCandidateAssociation__c>();
    //             for (Vacancy__c v : lstVacancy) {
    //                 vcas.add(new VacancyCandidateAssociation__c(Vacancy__c=v.Id, Candidate__c=candidate.Id));
    //             }
    //             insert vcas;
    //         }
 
    //         // Act
    //         Test.startTest();
    //         Test.setCurrentPage(Page.ManageVacancies);
    //         ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstVacancy);
    //         stdSetController.setSelected(lstVacancy);
    //         ManageVacanciesExt ext = new ManageVacanciesExt(stdSetController);

            
    //         ext.onload();
    //         ext.vacList[0].selected = true;
    //         ext.vacList[0].vacancy.Candidate__c = candidate.Id;

    //         ext.vacList[1].selected = true;
    //         ext.vacList[1].vacancy.Candidate__c = candidate.Id;
    //         ext.getSelected();

    //         ext.closeVacancies();

    //         Test.stopTest();
    //     }
    // }
}