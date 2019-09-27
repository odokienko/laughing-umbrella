public with sharing class ManageVacanciesExt {
    private static final String MESSAGE_NO_VACANCIES = 'No matching Vacancies found.';

    private List<Vacancy__c> SelectedVacancies = new List<Vacancy__c>();
    private ApexPages.StandardSetController controller;
    public List<VacancyWrapper> vacList { get; private set; } {vacList = new List<VacancyWrapper>();}


    private List<String> filteredStatuses = new List<String>{
        RecruitmentConstants.VACANCY_STATUS_CANCELLED,
        RecruitmentConstants.VACANCY_STATUS_CLOSED
    };

    public class VacancyWrapper {
        public Vacancy__c Vacancy {get; set;}
        public Boolean selected {get; set;}
        public Id Candidate {get; set;}
        public VacancyWrapper(Vacancy__c v) {
            Vacancy = v;
            selected = false;
            Candidate = null;
        }
    }

    public ApexPages.StandardSetController vacancyRecords {
        get {
            if(vacancyRecords == null) {
                vacancyRecords = new ApexPages.StandardSetController(
                    Database.getQueryLocator([
                        SELECT Id, Status__c, Name, Title__c, Candidate__c, Description__c, Level__c, Responsible__c, StartDate__c,
                            (SELECT Name, Vacancy__c, Candidate__r.Status__c, Candidate__r.Name, Candidate__r.Vacancies__c, Candidate__r.LastName__c, Candidate__r.FirstName__c, Candidate__r.Comments__c, Candidate__r.OwnerId FROM VacancyCandidateAssociations__r) 
                        FROM Vacancy__c
                        WHERE Status__c NOT IN :filteredStatuses ])
                );
            }
            return vacancyRecords;
        }
        private set;
    }

    public Map<Id, List<Candidate__c>> vacancyCandidateDetailsMap {
        get {
            if(vacancyCandidateDetailsMap == null) {
                vacancyCandidateDetailsMap = new Map<Id, List<Candidate__c>>();
                for (Id vacancyId : vacancyRecordsMap.keySet()) {
                    vacancyCandidateDetailsMap.put(vacancyId, candidateDetails(vacancyId));
                }
            }
            return vacancyCandidateDetailsMap;
        }
        private set;
    }

    public PageReference getSelected() {
        SelectedVacancies.clear();

        for(VacancyWrapper wrapper: vacList) {
            if (wrapper.Vacancy.Candidate__c != null) {
                wrapper.Candidate = wrapper.Vacancy.Candidate__c;
            }
            if (wrapper.selected == true) {
                SelectedVacancies.add(wrapper.Vacancy);
            }
        }

        return null;
    }

    public ManageVacanciesExt(ApexPages.StandardSetController setController) {
        controller = setController;
    }

    public PageReference onLoad() {
        VacancyWrapper vw;
        vacList.clear();
        
        if(vacancyRecords.getRecords().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, MESSAGE_NO_VACANCIES));
        }

        for (Vacancy__c v: (List<Vacancy__c>)vacancyRecords.getRecords()) {
            vw = new VacancyWrapper(v);
            vw.selected = false;
            vacList.add(vw);
        }
        
        return null;
    }

    public PageReference closeVacancies() {
//        PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
//        pageRef.setRedirect(true);

        doCloseVacancies(SelectedVacancies);

        vacancyRecords = null;
        onLoad();

        return null;
    }

    public PageReference cancelVacancies() {
//        PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
//        pageRef.setRedirect(true);

        doCancelVacancies(SelectedVacancies);

        vacancyRecords = null;
        onLoad();

        return null;
    }

    private List<Candidate__c> candidateDetails(String vacancyId) {
        List<Candidate__c> candidateList = new List<Candidate__c>();
        List<VacancyCandidateAssociation__c> vacancyCandidateAssociations = vacancyRecordsMap.get(vacancyId).VacancyCandidateAssociations__r;
        
        for(VacancyCandidateAssociation__c vca : vacancyCandidateAssociations) {
            candidateList.add(vca.Candidate__r);
        }

        return candidateList;
    }

    private Map<Id, Vacancy__c> vacancyRecordsMap {
        get {
            if(vacancyRecordsMap == null) {
                vacancyRecordsMap = new Map<Id, Vacancy__c>();
                vacancyRecordsMap.putAll((List<Vacancy__c>)vacancyRecords.getRecords());
            }

            return vacancyRecordsMap;
        }
        private set;
    }

    private void doCloseVacancies(List<Vacancy__c> listVacancies) {
        Map<Id,VacancyCandidateAssociation__c> vacancyCandidateAssociations = new Map<Id,VacancyCandidateAssociation__c>();
        Map<Id,Candidate__c> candidatesToHireMap = new Map<Id,Candidate__c>();
        List<Candidate__c> candidateToHireList = new List<Candidate__c>();        
        List<Vacancy__c> closedVacancyList = new List<Vacancy__c>();
        List<Vacancy__c> cancelledVacancyList = new List<Vacancy__c>();
        
        VacancyTool.splitVacanciesToClosedAndCancelled(listVacancies, closedVacancyList, cancelledVacancyList);
        
        updateVacancyClosedStatusAddingMessages(closedVacancyList, candidatesToHireMap, vacancyCandidateAssociations);
        updateVacancyCancelledStatusAddingMessages(cancelledVacancyList, vacancyCandidateAssociations, true);
        
        getBackVacancyCandidateAssociations(candidatesToHireMap.keySet(), vacancyCandidateAssociations);
        CandidateTool.setCandidateHired(candidatesToHireMap.values(), candidateToHireList);
        
        update candidateToHireList;
        delete vacancyCandidateAssociations.values();
    }

    private void getBackVacancyCandidateAssociations(Set<Id> candidateIds, Map<Id,VacancyCandidateAssociation__c> vacancyCandidateAssociations) {
        vacancyCandidateAssociations.putAll([
            SELECT Id
            FROM VacancyCandidateAssociation__c
            WHERE Candidate__c IN :candidateIds
        ]);
    }

    private void updateVacancyClosedStatusAddingMessages(
        List<Vacancy__c> closedVacancyList,
        Map<Id,Candidate__c> candidatesToHireMap,
        Map<Id,VacancyCandidateAssociation__c> vacancyCandidateAssociations
    ) {
        Candidate__c Candidate;
        List<VacancyCandidateAssociation__c> tempVacancyCandidateAssociations = new List<VacancyCandidateAssociation__c>();
        List<Database.SaveResult> updateResults = Database.update(closedVacancyList, false);
        
        for(Integer i = 0; i < updateResults.size(); i++){
            if (!updateResults.get(i).isSuccess()){
                Database.Error error = updateResults.get(i).getErrors().get(0);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error.getMessage()));

                continue;
            }

            Vacancy__c Vacancy = closedVacancyList.get(i);
            tempVacancyCandidateAssociations = Vacancy.VacancyCandidateAssociations__r;
            vacancyCandidateAssociations.putAll(tempVacancyCandidateAssociations);

            for(VacancyCandidateAssociation__c vca : tempVacancyCandidateAssociations) {
                Candidate = vca.Candidate__r;
                if (Candidate.Id == Vacancy.Candidate__c) {
                    Candidate.Vacancies__c = Vacancy.Id;
                    candidatesToHireMap.put(Candidate.Id, Candidate);
                }    
            }

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Vacancy ' + Vacancy.Name + ' have been successfully closed.'));
        }
    }

    private void doCancelVacancies(List<Vacancy__c> listVacancies) {
        Map<Id,VacancyCandidateAssociation__c> vacancyCandidateAssociations = new Map<Id,VacancyCandidateAssociation__c>();
        List<Vacancy__c> cancelledVacancyList = new List<Vacancy__c>();

        VacancyTool.trySetVacancyCancelledStatus(listVacancies, cancelledVacancyList);
        updateVacancyCancelledStatusAddingMessages(cancelledVacancyList, vacancyCandidateAssociations, false);

        System.debug('doCancelVacancies delete vacancyCandidateAssociations' + vacancyCandidateAssociations.values());
        delete vacancyCandidateAssociations.values();
    }

    private void updateVacancyCancelledStatusAddingMessages(
        List<Vacancy__c> updateList,
        Map<Id,VacancyCandidateAssociation__c> vacancyCandidateAssociations,
        Boolean isCloseVacancyContext
    ) {
        List<Database.SaveResult> updateResults = Database.update(updateList, false);

        for(Integer i=0;i<updateResults.size();i++){
            if (!updateResults.get(i).isSuccess()){
                Database.Error error = updateResults.get(i).getErrors().get(0);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error.getMessage()));
                 
                continue;
            } 
            
            vacancyCandidateAssociations.putAll(vacancyRecordsMap.get(updateList.get(i).Id).VacancyCandidateAssociations__r);

            if (isCloseVacancyContext == true) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Vacancy ' + updateList.get(i).Name + ' has been cancelled since the vacancy has no candidates selected.'));

                return;
            }

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Vacancy ' + updateList.get(i).Name + ' has been successfully cancelled.'));
        }
    }
}