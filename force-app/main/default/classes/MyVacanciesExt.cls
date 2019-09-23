public class MyVacanciesExt {

    private List<VacancyCandidateAssociation__c> SelectedVacancies = new List<VacancyCandidateAssociation__c>();
    private Map<Id,VacancyCandidateAssociation__c> selectedVacanciesMap = new Map<Id,VacancyCandidateAssociation__c>();
    
    public List<VacancyWrapper> vacancies { get; private set; } {vacancies = new List<VacancyWrapper>();}
    public Candidate__c candidate { get; private set; }

    public MyVacanciesExt(ApexPages.StandardController controller) {
        candidate = [SELECT Status__c FROM Candidate__c WHERE Id = :controller.getId()];
    }

    public PageReference getSelected() {
        SelectedVacancies.clear();

        for(VacancyWrapper wrapper: vacancies) {
            if (wrapper.selected == true) {
                SelectedVacancies.add(new VacancyCandidateAssociation__c(Candidate__c = candidate.Id,Vacancy__c = wrapper.vacancy.Id));
            }
        }

        return null;
    }

    public PageReference onload() {
        VacancyWrapper vw;

        if (candidate.Status__c == 'Validated By HR') {
            SelectedVacancies = [SELECT Vacancy__c, Candidate__c FROM VacancyCandidateAssociation__c WHERE Candidate__c = :candidate.Id];
            for (VacancyCandidateAssociation__c vcAssociation : SelectedVacancies) {
                selectedVacanciesMap.put(vcAssociation.Vacancy__c, vcAssociation);
            }

            for (Vacancy__c v: [SELECT Id, Owner.Name, Name, Title__c, Level__c, Description__c, DaysLeftToClose__c 
                                FROM Vacancy__c 
                                WHERE Status__c = 'In-Process' and Responsible__c = :userInfo.getUserId()]) {
                vw = new VacancyWrapper(v);
                vw.selected = selectedVacanciesMap.containsKey(v.Id);
                vacancies.add(vw);
            }
        }

        return null;
    }

    public PageReference Apply() {
        this.ApplySelected();

        PageReference candidatePage = new ApexPages.StandardController(candidate).view();
        candidatePage.setRedirect(true);

        return candidatePage;
    }

    private void ApplySelected() {
        List<VacancyCandidateAssociation__c> oldCandidateVacancies = [SELECT Id
            FROM VacancyCandidateAssociation__c 
            WHERE Candidate__c=:candidate.Id ];

        if (oldCandidateVacancies.size() > 0) {
            delete oldCandidateVacancies;
        }
            
        insert SelectedVacancies;
    }

    public class VacancyWrapper
    {
        public Vacancy__c vacancy {get; set;}
        public Boolean selected {get; set;}
        public VacancyWrapper(Vacancy__c v) {
            vacancy = v;
            selected = false;
        }
    }
}