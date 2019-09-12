trigger VacancyCandidateShareTrigger on VacancyCandidateAssociation__c (after insert, after delete) {
    List<Candidate__Share> candidateShrs  = new List<Candidate__Share>();
    List<Id> sharesToDelete = new List<Id>();
    
    if(trigger.isInsert){
        Candidate__Share candidateShr;
        Vacancy__c vacancy;
        
        for(VacancyCandidateAssociation__c candidateVacancy : trigger.new){
            vacancy = [SELECT OwnerId FROM Vacancy__c WHERE Id = :candidateVacancy.Vacancy__c limit 1];

            candidateShr = new Candidate__Share(
                ParentId = candidateVacancy.Candidate__c,
                UserOrGroupId = vacancy.OwnerId,
                AccessLevel = 'Edit',
                RowCause = Schema.Candidate__Share.RowCause.Manual
            );

            candidateShrs.add(candidateShr);
        }
        
        Database.insert(candidateShrs,false);
    }

    if(trigger.isDelete){
        for(VacancyCandidateAssociation__c candidateVacancy : trigger.old){
            sharesToDelete.add(candidateVacancy.Candidate__c);
        }

        if(!sharesToDelete.isEmpty()){
            List<Candidate__Share> candidateShrs = [SELECT Id 
                                                    FROM Candidate__Share 
                                                    WHERE ParentId IN :sharesToDelete 
                                                    AND RowCause = 'Manual'];

            Database.Delete(candidateShrs, false);
        }
    }
}