public class MyCandidatesExt {

    private List<VacancyCandidateAssociation__c> SelectedCandidates = new List<VacancyCandidateAssociation__c>();
    Map<Id,VacancyCandidateAssociation__c> selectedCandidatesMap = new Map<Id,VacancyCandidateAssociation__c>();

    public List<CandidateWrapper> candidates { get; private set; } {candidates = new List<CandidateWrapper>();}
    public Vacancy__c vacancy { get; private set; }

    public MyCandidatesExt(ApexPages.StandardController controller) {
        vacancy = [SELECT Status__c FROM Vacancy__c WHERE Id=:controller.getId()];
        System.debug('MyCandidatesExt vacancy:' + vacancy);
    }

    public PageReference onload() {
        CandidateWrapper cw;

        if (vacancy.Status__c == 'In-Process') {
            SelectedCandidates = [SELECT Vacancy__c, Candidate__c FROM VacancyCandidateAssociation__c WHERE Vacancy__c = :vacancy.Id];
            for (VacancyCandidateAssociation__c vcAssociation : SelectedCandidates) {
                selectedCandidatesMap.put(vcAssociation.Candidate__c, vcAssociation);
            }

            for (Candidate__c c: [SELECT Id, Owner.Name, Name, FirstName__c, LastName__c, Comments__c FROM Candidate__c WHERE Status__c = 'Validated By HR']) {
                cw = new CandidateWrapper(c);
                cw.selected = selectedCandidatesMap.containsKey(c.Id);
                candidates.add(cw);
            }
        }
        return null;
    }

    public PageReference getSelected() {
        SelectedCandidates.clear();

        for(CandidateWrapper wrapper: candidates) {
            if (wrapper.selected == true) {
                SelectedCandidates.add(new VacancyCandidateAssociation__c(Candidate__c = wrapper.candidate.Id,Vacancy__c = vacancy.Id));
            }
        }

        return null;
    }

    public PageReference Apply() {
        this.ApplySelected();

        PageReference vacancyPage = new ApexPages.StandardController(vacancy).view();
        vacancyPage.setRedirect(true);

        return vacancyPage;
    }

    private void ApplySelected() {
        List<VacancyCandidateAssociation__c> oldCandidateVacancies = [SELECT Id
            FROM VacancyCandidateAssociation__c 
            WHERE Vacancy__c=:vacancy.Id];

        if (oldCandidateVacancies.size() > 0) {
            delete oldCandidateVacancies;
        }
            
        insert SelectedCandidates;
    }
        
    public class CandidateWrapper
    {
        public Candidate__c candidate {get; set;}
        public Boolean selected {get; set;}
        public CandidateWrapper(Candidate__c c) {
            candidate = c;
            selected = false;
        }
    }
}