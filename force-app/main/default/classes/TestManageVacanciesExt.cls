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
            Candidate__c Candidate = new Candidate__c(Status__c = RecruitmentConstants.CANDIDATE_STATUS_VALIDATED);
            insert Candidate;
        }
    }

    @IsTest
    private static void TestMyVacanciesExtNoVacancies(){
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

            ext.onLoad();
            ext.getSelected();

            Test.stopTest();
        }
    }

    @IsTest
    private static void TestMyVacanciesExtHaveVacancy(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c Vacancy;
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

            ext.onLoad();
            ext.getSelected();

            Test.stopTest();
        }
    }

    @IsTest
    private static void TestMyVacanciesExtHaveVacancySelected(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];

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

            
            ext.onLoad();
            ext.vacList[0].selected = true;
            ext.getSelected();

            Test.stopTest();
        }
    }

    @IsTest
    private static void TestMyVacanciesExtHaveVacancySelectedAndCancelled(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];

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

            
            ext.onLoad();
            ext.vacList[0].selected = true;
            ext.getSelected();
            Map<Id, List<Candidate__c>> vacancyCandidateDetails = ext.vacancyCandidateDetailsMap;
            ext.cancelVacancies();

            Test.stopTest();
        }
    }

    @IsTest
    private static void TestMyVacanciesExtHaveVacancyAndCandidatesSelectedAndClosed(){
		// Arrange
        User manager = [SELECT Id FROM User WHERE Alias='muser' LIMIT 1];
        User recruiter = [SELECT Id FROM User WHERE Alias='ruser' LIMIT 1];
        Vacancy__c Vacancy;
        Candidate__c Candidate;

        System.runAs(manager) {
            List <Vacancy__c> lstVacancy = new List<Vacancy__c>();
 
            Vacancy__c testVacancy = new Vacancy__c(Responsible__c=recruiter.Id);
            lstVacancy.add(testVacancy);
            Vacancy__c testVacancy1 = new Vacancy__c(Responsible__c=recruiter.Id);
            lstVacancy.add(testVacancy1);
            insert  lstVacancy;

            

            System.runAs(recruiter) {
                Candidate = [SELECT Status__c FROM Candidate__c WHERE OwnerId=:recruiter.Id LIMIT 1];
                Vacancy = [SELECT Status__c FROM Vacancy__c LIMIT 1];
                VacancyCandidateAssociation__c vacancyCandidateAssociation = new VacancyCandidateAssociation__c(Vacancy__c= Vacancy.Id, Candidate__c= Candidate.Id);
                insert vacancyCandidateAssociation;
            }
 
            // Act
            Test.startTest();
            Test.setCurrentPage(Page.ManageVacancies);
            ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstVacancy);
            stdSetController.setSelected(lstVacancy);
            ManageVacanciesExt ext = new ManageVacanciesExt(stdSetController);

            
            ext.onLoad();
            ext.vacList[0].selected = true;
            Map<Id, List<Candidate__c>> vacancyCandidateDetails = ext.vacancyCandidateDetailsMap;
            ext.vacList[0].Vacancy.Candidate__c = Candidate.Id;
            ext.getSelected();

            ext.closeVacancies();

            Test.stopTest();
        }
    }
}