trigger VacancyCandidateDuplicatePreventer on VacancyCandidateAssociation__c
                               (before insert, before update) {

    Map<String, VacancyCandidateAssociation__c> VacancyCandidateAssociationMap = new Map<String, VacancyCandidateAssociation__c>();
    String key;
    for (VacancyCandidateAssociation__c VacancyCandidateAssociation : System.Trigger.new) {
    
        if (VacancyCandidateAssociation.Unique_Candidate_Vacancy__c != null && VacancyCandidateAssociation.Unique_Candidate_Vacancy__c != '') {
            if (VacancyCandidateAssociationMap.containsKey(VacancyCandidateAssociation.Unique_Candidate_Vacancy__c)) {
                VacancyCandidateAssociation.Vacancy__c.addError('Another new Vacancy to Candidate association already exists.');
            } else {
                VacancyCandidateAssociationMap.put(VacancyCandidateAssociation.Unique_Candidate_Vacancy__c, VacancyCandidateAssociation);
            }
       }
    }
    
    for (VacancyCandidateAssociation__c VacancyCandidateAssociation : [SELECT Unique_Candidate_Vacancy__c FROM VacancyCandidateAssociation__c
                      WHERE Unique_Candidate_Vacancy__c IN :VacancyCandidateAssociationMap.KeySet()]) {
        
        VacancyCandidateAssociation__c newVacancyCandidateAssociation = VacancyCandidateAssociationMap.get(VacancyCandidateAssociation.Unique_Candidate_Vacancy__c);
        newVacancyCandidateAssociation.Vacancy__c.addError('Vacancy to Candidate association already exists.');
    }
}