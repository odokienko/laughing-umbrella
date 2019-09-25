public with sharing class ManageVacanciesExt {
    private List<Vacancy__c> SelectedVacancies = new List<Vacancy__c>();
    private ApexPages.StandardSetController controller;
    public List<VacancyWrapper> vacList { get; private set; } {vacList = new List<VacancyWrapper>();}
    private List<String> filteredStatuses = new List<String>{
        RecruitmentConstants.VACANCY_STATUS_CENCELLED,
        RecruitmentConstants.VACANCY_STATUS_CLOSED
    };

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
                for (ID vacancyId : vacancyRecordsMap.keySet()) {
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
            if (wrapper.vacancy.Candidate__c != null) {
                wrapper.candidate = wrapper.vacancy.Candidate__c;
            }
            if (wrapper.selected == true) {
                SelectedVacancies.add(wrapper.vacancy);
            }
        }

        return null;
    }

    public ManageVacanciesExt(ApexPages.StandardSetController setController) {
        controller = setController;
    }

    public PageReference onload() {
        VacancyWrapper vw;
        vacList.clear();
        
        if(vacancyRecords.GetRecords().Size() == 0) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Info, 'No matching Vacancies found.'));
        }

        for (Vacancy__c v: (List<Vacancy__c>)vacancyRecords.GetRecords()) {
            vw = new VacancyWrapper(v);
            vw.selected = false;
            vacList.add(vw);
        }
        
        return null;
    }

    public PageReference closeVacancies() {
        PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl()); 
        pageRef.setRedirect(true); 

        doCloseVacancies();

        vacancyRecords = null;
        onload();

        return null;
    }

    public PageReference cancelVacancies() {
        PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl()); 
        pageRef.setRedirect(true); 

        doCanselVacancies();

        vacancyRecords = null;
        onload();

        return null;
    }

    public class VacancyWrapper {
        public Vacancy__c vacancy {get; set;}
        public Boolean selected {get; set;}
        public Id candidate {get; set;}
        public VacancyWrapper(Vacancy__c v) {
            vacancy = v;
            selected = false;
            candidate = null;
        }
    }

    private List<Candidate__c> candidateDetails(String vacancyId) {
        List<Candidate__c> candidatelist = new List<Candidate__c>();
        List<VacancyCandidateAssociation__c> vcas = vacancyRecordsMap.get(vacancyId).VacancyCandidateAssociations__r;
        
        for(VacancyCandidateAssociation__c vca : vcas) {
            candidatelist.add(vca.Candidate__r);
        }

        return candidatelist;
    }

    private Map<Id, Vacancy__c> vacancyRecordsMap {
        get {
            if(vacancyRecordsMap == null) {
                vacancyRecordsMap = new Map<id, Vacancy__c>();
                vacancyRecordsMap.putAll((List<Vacancy__c>)vacancyRecords.GetRecords());
            }

            return vacancyRecordsMap;
        }
        private set;
    }

    private void doCloseVacancies() {
        Map<Id,VacancyCandidateAssociation__c> vacancyCandidateAssociations = new Map<Id,VacancyCandidateAssociation__c>();
        Map<Id,Candidate__c> candidatesToHireMap = new Map<Id,Candidate__c>();
        List<Candidate__c> candidateToHireList = new List<Candidate__c>();        
        List<Vacancy__c> closedVacancyList = new List<Vacancy__c>();
        List<Vacancy__c> cancelledVacancyList = new List<Vacancy__c>();
        
        VacancyTool.splitVacanciesToClosedCancelled(SelectedVacancies, closedVacancyList, cancelledVacancyList);
        
        updateVacancyClosedStatusAddingMessages(closedVacancyList, candidatesToHireMap, vacancyCandidateAssociations);
        updateVacancyCancelledStatusAddingMessages(cancelledVacancyList, vacancyCandidateAssociations, ApexPages.Severity.WARNING);
        
        getBackVacancyCandidateAssociations(candidatesToHireMap.keySet(), vacancyCandidateAssociations);
        CandidateTool.setCandidateHired(candidatesToHireMap.values(), candidateToHireList);
        
        update candidateToHireList;
        System.debug('doCloseVacancies delete vacancyCandidateAssociations' + vacancyCandidateAssociations.values());
        // delete vacancyCandidateAssociations.values();
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
        Candidate__c candidate;
        List<VacancyCandidateAssociation__c> vcas = new List<VacancyCandidateAssociation__c>();
        List<Database.SaveResult> updateResults = Database.update(closedVacancyList, false);
        
        for(Integer i = 0; i < updateResults.size(); i++){
            if (!updateResults.get(i).isSuccess()){
                Database.Error error = updateResults.get(i).getErrors().get(0);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error.getMessage()));

                continue;
            }

            Vacancy__c vacancy = closedVacancyList.get(i);

            vcas = vacancyRecordsMap.get(vacancy.Id).VacancyCandidateAssociations__r;
            System.System.debug('vcas 1' + vcas);

            vcas = vacancy.VacancyCandidateAssociations__r;
            System.System.debug('vcas 2' + vcas);

            vacancyCandidateAssociations.putAll(vcas);

            for(VacancyCandidateAssociation__c vca : vcas) {
                candidate = vca.Candidate__r;
                if (candidate.Id == vacancy.Candidate__c) {
                    candidate.Vacancies__c = vacancy.Id;
                    candidatesToHireMap.put(candidate.Id, candidate);
                }    
            }

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Vacancy ' + vacancy.Name + ' have been successfully closed.'));
        }
    }

    private void doCanselVacancies() { 
        Map<Id,VacancyCandidateAssociation__c> vacancyCandidateAssociations = new Map<Id,VacancyCandidateAssociation__c>();
        List<Vacancy__c> cancelledVacancyList = new List<Vacancy__c>();

        VacancyTool.trySetVacancyCancelledStatus(SelectedVacancies, cancelledVacancyList);
        updateVacancyCancelledStatusAddingMessages(cancelledVacancyList, vacancyCandidateAssociations, ApexPages.Severity.CONFIRM);

        System.debug('doCanselVacancies delete vacancyCandidateAssociations' + vacancyCandidateAssociations.values());
        delete vacancyCandidateAssociations.values();
    }

    private void updateVacancyCancelledStatusAddingMessages(
        List<Vacancy__c> updateList,
        Map<Id,VacancyCandidateAssociation__c> vacancyCandidateAssociations,
        ApexPages.Severity severity
    ) {
        List<Database.SaveResult> updateResults = Database.update(updateList, false);

        for(Integer i=0;i<updateResults.size();i++){
            if (!updateResults.get(i).isSuccess()){
                Database.Error error = updateResults.get(i).getErrors().get(0);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error.getMessage()));
                 
                continue;
            } 
            
            vacancyCandidateAssociations.putAll(vacancyRecordsMap.get(updateList.get(i).Id).VacancyCandidateAssociations__r);
            ApexPages.addMessage(new ApexPages.Message(severity,'Vacancy ' + updateList.get(i).Name + ' has been successfully cancelled.'));
        }
    }

    private void HireCandidate(Id vacancyId, Id selectedCandidateId) {
        Map<String, Object> params = new Map<String, Object>();
        System.debug('HireCandidate vacancyId: ' + vacancyId);
        System.debug('HireCandidate selectedCandidateId: ' + selectedCandidateId);
        If (vacancyId == null || selectedCandidateId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to hire'));
            return;
        }
        
        params.put('varVacancyId', vacancyId);
        params.put('selectedCandidateId', selectedCandidateId);

        Flow.Interview.Hire_Candidate Hire_CandidateFlow = new Flow.Interview.Hire_Candidate(params);
        Hire_CandidateFlow.start();
    }
}
