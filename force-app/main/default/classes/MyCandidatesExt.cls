public class MyCandidatesExt {

    private List<VacancyCandidateAssociation__c> SelectedCandidates = new List<VacancyCandidateAssociation__c>();
    Map<Id,VacancyCandidateAssociation__c> selectedCandidatesMap = new Map<Id,VacancyCandidateAssociation__c>();

    public class CandidateWrapper
    {
        public Candidate__c Candidate {get; set;}
        public Boolean selected {get; set;}
        public CandidateWrapper(Candidate__c c) {
            Candidate = c;
            selected = false;
        }
    }

    public List<CandidateWrapper> candidates { get; private set; } {candidates = new List<CandidateWrapper>();}
    public Vacancy__c Vacancy { get; private set; }

    public MyCandidatesExt(ApexPages.StandardController controller) {
        Vacancy = [SELECT Status__c FROM Vacancy__c WHERE Id=:controller.getId()];
    }

    public PageReference onLoad() {
        CandidateWrapper cw;

        if (Vacancy.Status__c == RecruitmentConstants.VACANCY_STATUS_IN_PROCESS) {
            SelectedCandidates = [SELECT Vacancy__c, Candidate__c FROM VacancyCandidateAssociation__c WHERE Vacancy__c = :Vacancy.Id];
            for (VacancyCandidateAssociation__c vcAssociation : SelectedCandidates) {
                selectedCandidatesMap.put(vcAssociation.Candidate__c, vcAssociation);
            }

            for (Candidate__c c: [SELECT Id, Owner.Name, Name, FirstName__c, LastName__c, Comments__c FROM Candidate__c WHERE Status__c = :RecruitmentConstants.CANDIDATE_STATUS_VALIDATED]) {
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
                SelectedCandidates.add(new VacancyCandidateAssociation__c(Candidate__c = wrapper.Candidate.Id,Vacancy__c = Vacancy.Id));
            }
        }

        return null;
    }

    public PageReference Apply() {
        this.ApplySelected();

        PageReference vacancyPage = new ApexPages.StandardController(Vacancy).view();
        vacancyPage.setRedirect(true);

        return vacancyPage;
    }

    private void ApplySelected() {
        List<VacancyCandidateAssociation__c> oldCandidateVacancies = [SELECT Id
            FROM VacancyCandidateAssociation__c 
            WHERE Vacancy__c=:Vacancy.Id];

        if (oldCandidateVacancies.size() > 0) {
            delete oldCandidateVacancies;
        }
            
        insert SelectedCandidates;
    }
}