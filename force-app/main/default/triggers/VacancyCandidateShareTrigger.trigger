trigger VacancyCandidateShareTrigger on VacancyCandidateAssociation__c (after insert, after delete) {
    List<Candidate__Share> candidateShares = new List<Candidate__Share>();
    List<Id> sharesToDelete = new List<Id>();
    
    if(Trigger.isInsert){
        Candidate__Share candidateShr;
        Vacancy__c vacancy;
        
        for(VacancyCandidateAssociation__c candidateVacancy : Trigger.new){
            vacancy = [SELECT OwnerId FROM Vacancy__c WHERE Id = :candidateVacancy.Vacancy__c LIMIT 1];

            candidateShr = new Candidate__Share(
                ParentId = candidateVacancy.Candidate__c,
                UserOrGroupId = vacancy.OwnerId,
                AccessLevel = 'Edit',
                RowCause = Schema.Candidate__Share.RowCause.Manual
            );

            candidateShares.add(candidateShr);
        }
        
        Database.insert(candidateShares,false);
    }

    if(Trigger.isDelete){
        for(VacancyCandidateAssociation__c candidateVacancy : Trigger.old){
            sharesToDelete.add(candidateVacancy.Candidate__c);
        }

        if(!sharesToDelete.isEmpty()){
            List<Candidate__Share> candidateShares = [SELECT Id
                                                    FROM Candidate__Share 
                                                    WHERE ParentId IN :sharesToDelete 
                                                    AND RowCause = 'Manual'];

            Database.delete(candidateShares, false);
        }
    }
}