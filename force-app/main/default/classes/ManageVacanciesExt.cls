public with sharing class ManageVacanciesExt {
    private List<Vacancy__c> SelectedVacancies = new List<Vacancy__c>();
    private ApexPages.StandardSetController controller;
    public List<VacancyWrapper> vacList { get; private set; } {vacList = new List<VacancyWrapper>();}

    public ApexPages.StandardSetController vacancyRecords {
        get {
            if(vacancyRecords == null) {
                vacancyRecords = new ApexPages.StandardSetController(
                    Database.getQueryLocator([
                        SELECT Id, Status__c, Name, Title__c, Candidate__c, Description__c, Level__c, Responsible__c, StartDate__c,
                            (SELECT Name, Vacancy__c, Candidate__r.Name, Candidate__r.LastName__c, Candidate__r.FirstName__c, Candidate__r.Comments__c, Candidate__r.OwnerId FROM VacancyCandidateAssociations__r) 
                        FROM Vacancy__c
                        WHERE Status__c NOT IN ('Cancelled', 'Closed')])
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
            System.debug('vacancy ' + wrapper.vacancy.id + ' : ' + wrapper.vacancy.Candidate__c);
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

    public class VacancyWrapper
    {
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

    private List<Vacancy__c> setVacancyStatus (String status) {
        List<Vacancy__c> updateList = new List<Vacancy__c>();
        for (Vacancy__c vacancy : SelectedVacancies)
        {
            vacancy.Status__c = status;
            updateList.add(vacancy);
        }

        return updateList;
    }

    private void doCloseVacancies() {
        List<Vacancy__c> updateList = setVacancyStatus('Closed');
        
        List<Database.SaveResult> updateResults = Database.update(updateList, false);
        for(Integer i=0;i<updateResults.size();i++){
            if (updateResults.get(i).isSuccess()){
                System.debug('doCloseVacancies vacancy: ' + updateList.get(i));
                System.debug('doCloseVacancies: ' + updateList.get(i).Candidate__c);
                if (updateList.get(i).Candidate__c == null ) {
                    Map<String, Object> params = new Map<String, Object>();
                    params.put('varVacancyId', updateResults.get(i).getId());
                    doCancellStaff(params);
                    
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Vacancy ' + updateList.get(i).Name + ' had no candidates selected, so it has been cancelled.'));
                } else {
                    Map<String, Object> params = new Map<String, Object>();
                    params.put('varVacancyId', updateResults.get(i).getId());
                    params.put('selectedCandidateId', updateList.get(i).Candidate__c);
                    HireCandidate(params);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Vacancy ' + updateList.get(i).Name + ' have been successfully closed.'));
                }
                
            } else if (!updateResults.get(i).isSuccess()){
                Database.Error error = updateResults.get(i).getErrors().get(0);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error.getMessage()));
            }
        }
    }

    private void doCanselVacancies() {
        List<Vacancy__c> updateList = setVacancyStatus('Cancelled');
        
        List<Database.SaveResult> updateResults = Database.update(updateList, false);
        for(Integer i=0;i<updateResults.size();i++){
            if (updateResults.get(i).isSuccess()){
                Map<String, Object> params = new Map<String, Object>();
                params.put('varVacancyId', updateResults.get(i).getId());
                doCancellStaff(params);
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Vacancy ' + updateList.get(i).Name + ' have been successfully cancelled.'));
            } else if (!updateResults.get(i).isSuccess()){
                Database.Error error = updateResults.get(i).getErrors().get(0);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error.getMessage()));
            }
        }
    }

    private void HireCandidate(Map<String, Object> params) {
        Flow.Interview.Hire_Candidate Hire_CandidateFlow = new Flow.Interview.Hire_Candidate(params);
        Hire_CandidateFlow.start();
    }

    private void doCancellStaff(Map<String, Object> params) {
        Flow.Interview.Cancel_Vacancy Cancel_VacancyFlow = new Flow.Interview.Cancel_Vacancy(params);
        Cancel_VacancyFlow.start();
    }
}
