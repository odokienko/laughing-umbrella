trigger VacancyDuplicatePreventer on Vacancy__c
                               (before insert, before update) {

    Map<String, Vacancy__c> VacancyByCandidateMap = new Map<String, Vacancy__c>();
    Map<String, Vacancy__c> VacancyMap = new Map<String, Vacancy__c>();
    Vacancy__c newVacancy;
    Candidate__c Candidate;
    Map<Id,Candidate__c> candidateMap = new Map<Id,Candidate__c>();
    String displayName1, displayName2, CandidateName;

    for (Vacancy__c Vacancy : System.Trigger.new) {
        if (!(Vacancy.Candidate__c == null || String.isEmpty(Vacancy.Candidate__c))) {
            VacancyByCandidateMap.put(Vacancy.Candidate__c, Vacancy);
        }
    }

    if (VacancyByCandidateMap.size() > 0) {
        candidateMap.putAll([SELECT Name, FirstName__c, LastName__c FROM Candidate__c WHERE Id IN :VacancyByCandidateMap.keySet()]);
    }

    VacancyByCandidateMap.clear();

    for (Vacancy__c Vacancy : System.Trigger.new) {
        if (!(Vacancy.Candidate__c == null || String.isEmpty(Vacancy.Candidate__c))) {
            Candidate = candidateMap.get(Vacancy.Candidate__c);
            if (VacancyByCandidateMap.containsKey(Vacancy.Candidate__c)) {
                newVacancy = VacancyByCandidateMap.get(Vacancy.Candidate__c);
                displayName1 = !String.isEmpty(Vacancy.Title__c) ? Vacancy.Title__c + ' (' + Vacancy.Name + ')' : Vacancy.Name;
                displayName2 = !String.isEmpty(newVacancy.Title__c) ? newVacancy.Title__c + ' (' + newVacancy.Name + ')' : newVacancy.Name;
                CandidateName = String.isEmpty(Candidate.FirstName__c) ? Candidate.FirstName__c + ' ' + Candidate.LastName__c + ' (' + Candidate.Name + ')' : Candidate.Name;


                Vacancy.Candidate__c.addError('This vacancy, ' + displayName1 + ', and the ' + displayName2 + ', have candidate ' + CandidateName + ' selected. Please choose different ones.');
                newVacancy.Candidate__c.addError('This vacancy, ' + displayName2 + ', and the ' + displayName1 + ', have candidate ' + CandidateName + ' selected. Please choose different ones.');
            } else {
                VacancyByCandidateMap.put(Vacancy.Candidate__c, Vacancy);
            }
        }

        if (Trigger.isUpdate) {
            VacancyMap.put(Vacancy.Id, Vacancy);
        }
    }

    for (Vacancy__c Vacancy : [SELECT Name, Candidate__c, Title__c, Candidate__r.Name, Candidate__r.FirstName__c, Candidate__r.LastName__c FROM Vacancy__c
                      WHERE Candidate__c IN :VacancyByCandidateMap.keySet() AND Id NOT IN :VacancyMap.keySet()]) {
        newVacancy = VacancyByCandidateMap.get(Vacancy.Candidate__c);
        displayName1 = !String.isEmpty(Vacancy.Title__c) ? Vacancy.Title__c + ' (' + Vacancy.Name + ')' : Vacancy.Name;
        CandidateName = String.isEmpty(Vacancy.Candidate__r.FirstName__c) ? Vacancy.Candidate__r.FirstName__c + ' ' + Vacancy.Candidate__r.LastName__c + ' (' + Vacancy.Candidate__r.Name + ')' : Vacancy.Candidate__r.Name;
        System.System.debug('VacancyDuplicatePreventer:' + Vacancy);
        newVacancy.Candidate__c.addError('Another vacancy, ' + displayName1 + ', has already candidate ' + CandidateName + ' approved. Please choose another one.');
    }
}