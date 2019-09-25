trigger VacancyDuplicatePreventer on Vacancy__c
                               (before insert, before update) {

    Map<String, Vacancy__c> VacancyByCandidateMap = new Map<String, Vacancy__c>();
    Vacancy__c newVacancy;
    Candidate__c candidate;
    Map<Id,Candidate__c> candidateMap = new Map<Id,Candidate__c>();
    String displayName1, displayName2, CandidateName;

    for (Vacancy__c vacancy : System.Trigger.new) {
        if (!(vacancy.Candidate__c == null || String.IsEmpty(vacancy.Candidate__c))) {
            VacancyByCandidateMap.put(vacancy.Candidate__c, vacancy);
        }
    }

    if (VacancyByCandidateMap.size() > 0) {
        candidateMap.putAll([SELECT Name, FirstName__c, LastName__c FROM Candidate__c WHERE id IN :VacancyByCandidateMap.KeySet()]);
    }

    VacancyByCandidateMap.clear();

    for (Vacancy__c vacancy : System.Trigger.new) {
        if (!(vacancy.Candidate__c == null || String.IsEmpty(vacancy.Candidate__c))) {
            candidate = candidateMap.get(vacancy.Candidate__c);
            if (VacancyByCandidateMap.containsKey(vacancy.Candidate__c)) {
                newVacancy = VacancyByCandidateMap.get(vacancy.Candidate__c);
                displayName1 = !String.IsEmpty(vacancy.Title__c) ? vacancy.Title__c + ' (' + vacancy.Name + ')' : vacancy.Name;
                displayName2 = !String.IsEmpty(newVacancy.Title__c) ? newVacancy.Title__c + ' (' + newVacancy.Name + ')' : newVacancy.Name;
                CandidateName = String.IsEmpty(candidate.FirstName__c) ? candidate.FirstName__c + ' ' + candidate.LastName__c + ' (' + candidate.Name + ')' : candidate.Name;


                vacancy.Candidate__c.addError('This vacancy, ' + displayName1 + ', and the ' + displayName2 + ', have candidate ' + CandidateName + ' selected. Please choose different ones.');
                newVacancy.Candidate__c.addError('This vacancy, ' + displayName2 + ', and the ' + displayName1 + ', have candidate ' + CandidateName + ' selected. Please choose different ones.');
            } else {
                VacancyByCandidateMap.put(vacancy.Candidate__c, vacancy);
            }
       }
    }

    for (Vacancy__c vacancy : [SELECT Name, Candidate__c, Title__c, Candidate__r.Name, Candidate__r.FirstName__c, Candidate__r.LastName__c FROM Vacancy__c
                      WHERE Candidate__c IN :VacancyByCandidateMap.KeySet()]) {
        newVacancy = VacancyByCandidateMap.get(vacancy.Candidate__c);
        displayName1 = !String.IsEmpty(vacancy.Title__c) ? vacancy.Title__c + ' (' + vacancy.Name + ')' : vacancy.Name;
        CandidateName = String.IsEmpty(vacancy.Candidate__r.FirstName__c) ? vacancy.Candidate__r.FirstName__c + ' ' + vacancy.Candidate__r.LastName__c + ' (' + vacancy.Candidate__r.Name + ')' : vacancy.Candidate__r.Name;
        System.System.debug('VacancyDuplicatePreventer:' + vacancy);
        newVacancy.Candidate__c.addError('Another vacancy, ' + displayName1 + ', has already candidate ' + CandidateName + ' approved. Please choose another one.');
    }
}