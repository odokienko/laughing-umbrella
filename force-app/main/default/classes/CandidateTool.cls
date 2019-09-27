public with sharing class CandidateTool {
    public static void setCandidateHired (List<Candidate__c> updateCandidateList, List<Candidate__c> hiredCandidateList) {
        System.System.debug(updateCandidateList);
        
        for (Candidate__c Candidate : updateCandidateList) {
            if (!isOpened(Candidate)) {
                continue;
            }

            Candidate.Status__c = RecruitmentConstants.CANDIDATE_STATUS_HIRED;
            hiredCandidateList.add(Candidate);
        }
    }

    public static Boolean isOpened(Candidate__c Candidate) {
        return Candidate.Status__c != RecruitmentConstants.CANDIDATE_STATUS_DISQUALIFIED
            && Candidate.Status__c != RecruitmentConstants.CANDIDATE_STATUS_HIRED;
    }
}