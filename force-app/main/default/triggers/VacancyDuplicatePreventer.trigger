trigger VacancyDuplicatePreventer on Vacancy__c
                               (before insert, before update) {

    Map<String, Vacancy__c> VacancyMap = new Map<String, Vacancy__c>();

    
    for (Vacancy__c vacancy : System.Trigger.new) {
        if (vacancy.Candidate__c != null && (Trigger.isInsert || (Trigger.isInsert && Trigger.oldMap.get(vacancy.Id).Candidate__c != vacancy.Candidate__c))) {
            if (VacancyMap.containsKey(vacancy.Candidate__c)) {
                vacancy.Candidate__c.addError('It\'s impossible that one candidate being approved to several vacancies. Please fix this.');
            } else {
                VacancyMap.put(vacancy.Candidate__c, vacancy);
            }
       }
    }

    for (Vacancy__c vacancy : [SELECT Name, Candidate__r.Name FROM Vacancy__c
                      WHERE Candidate__c IN :VacancyMap.KeySet()]) {
        Vacancy__c newVacancy = VacancyMap.get(vacancy.Candidate__c);
        newVacancy.Candidate__c.addError('Another vacancy, ' + vacancy.Name + ' has already candidate ' + vacancy.Candidate__r.Name + ' approved. Please choose another one.');
    }
}