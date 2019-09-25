public class VacancyTool {
    public static void splitVacanciesToClosedCancelled (
        List<Vacancy__c> sourceVacancyList,
        List<Vacancy__c> closedVacancyList,
        List<Vacancy__c> cancelledVacancyList
    ) {
        for (Vacancy__c vacancy : sourceVacancyList) {
            if (!isOpened(vacancy)) {
                continue;
            }

            if (canBeClosed(vacancy)) {
                vacancy.Status__c = RecruitmentConstants.VACANCY_STATUS_CLOSED;
                closedVacancyList.add(vacancy);
            } else {
                vacancy.Status__c = RecruitmentConstants.VACANCY_STATUS_CENCELLED;
                cancelledVacancyList.add(vacancy);
            }
        }
    }

    public static void trySetVacancyCancelledStatus (List<Vacancy__c> sourceVacancyList, List<Vacancy__c> cancelledVacancyList) {
        for (Vacancy__c vacancy : sourceVacancyList) {
            if (!isOpened(vacancy)) {
                continue;
            }

            vacancy.Status__c = RecruitmentConstants.VACANCY_STATUS_CENCELLED;
            cancelledVacancyList.add(vacancy);
        }
    }

    public static boolean isOpened(Vacancy__c vacancy) {
        return vacancy.Status__c != RecruitmentConstants.VACANCY_STATUS_CENCELLED
            && vacancy.Status__c != RecruitmentConstants.VACANCY_STATUS_CLOSED;
    }

    public static boolean isCancelled(Vacancy__c vacancy) {
        return (vacancy.Candidate__c == null || String.IsEmpty(vacancy.Candidate__c)) && vacancy.Status__c == RecruitmentConstants.VACANCY_STATUS_CENCELLED;
    }

    public static boolean isClosed(Vacancy__c vacancy) {
        return vacancy.Candidate__c != null && !String.IsEmpty(vacancy.Candidate__c) && vacancy.Status__c == RecruitmentConstants.VACANCY_STATUS_CLOSED;
    }

    public static boolean canBeClosed(Vacancy__c vacancy) {
        return isOpened(vacancy) && vacancy.Candidate__c != null && !String.IsEmpty(vacancy.Candidate__c);
    }
}