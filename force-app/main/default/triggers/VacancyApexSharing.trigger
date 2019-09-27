trigger VacancyApexSharing on Vacancy__c (after insert, after update) {
    List<Vacancy__Share> vacancyShares = new List<Vacancy__Share>();
    List<Vacancy__Share> sharesToDelete = [SELECT Id
                                            FROM Vacancy__Share 
                                            WHERE ParentId IN :Trigger.newMap.keySet()
                                            AND RowCause = 'Manual'];
    Vacancy__Share recruiterShr;

    for(Vacancy__c Vacancy : Trigger.new){
        if (Vacancy.Responsible__c != null) {
            recruiterShr = new Vacancy__Share(
                ParentId = Vacancy.Id,
                UserOrGroupId = Vacancy.Responsible__c,
                AccessLevel = 'Edit',
                RowCause = Schema.Vacancy__Share.RowCause.Manual
            );
            
            vacancyShares.add(recruiterShr);
        }
    }
    
    if(!sharesToDelete.isEmpty()){
        Database.delete(sharesToDelete, false);
    }

    if (vacancyShares.size() > 0) {
        Database.upsert(vacancyShares,false);
    }
}