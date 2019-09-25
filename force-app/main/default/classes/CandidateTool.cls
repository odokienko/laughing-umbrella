public with sharing class CandidateTool {
    public static void setCandidateHired (List<Candidate__c> updateCandidateList, List<Candidate__c> hiredCandidateList) {
        System.System.debug(updateCandidateList);
        
        for (Candidate__c candidate : updateCandidateList) {
            if (!isOpened(candidate)) {
                continue;
            }

            candidate.Status__c = RecruitmentConstants.CANDIDATE_STATUS_HIRED;
            hiredCandidateList.add(candidate);
        }
    }

    public static boolean isOpened(Candidate__c candidate) {
        return candidate.Status__c != RecruitmentConstants.CANDIDATE_STATUS_DISCUALIFIED
            && candidate.Status__c != RecruitmentConstants.CANDIDATE_STATUS_HIRED;
    }
}
