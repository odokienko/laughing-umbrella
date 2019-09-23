trigger VacancyApexSharing on Vacancy__c (after insert, after update) {
    List<Vacancy__Share> vacancyShrs  = new List<Vacancy__Share>();
    List<Candidate__Share> candidateShrs  = new List<Candidate__Share>();
    List<Vacancy__Share> sharesToDelete = [SELECT Id 
                                            FROM Vacancy__Share 
                                            WHERE ParentId IN :trigger.newMap.keyset() 
                                            AND RowCause = 'Manual'];
    Vacancy__Share recruiterShr;
    Candidate__Share candidateShr;
    
    for(Vacancy__c vacancy : trigger.new){
        if (vacancy.Status__c == 'In-Process' && vacancy.Responsible__c != null) {
            recruiterShr = new Vacancy__Share(
                ParentId = vacancy.Id,
                UserOrGroupId = vacancy.Responsible__c,
                AccessLevel = 'Read',
                RowCause = Schema.Vacancy__Share.RowCause.Manual
            );
            
            vacancyShrs.add(recruiterShr);
        }
    }
    
    if(!sharesToDelete.isEmpty()){
        Database.Delete(sharesToDelete, false);
    }

    if (vacancyShrs.size() > 0) {
        Database.insert(vacancyShrs,false);
    }
}