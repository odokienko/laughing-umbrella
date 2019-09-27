public class VacancyTool {
    public static void splitVacanciesToClosedAndCancelled(
        List<Vacancy__c> sourceVacancyList,
        List<Vacancy__c> closedVacancyList,
        List<Vacancy__c> cancelledVacancyList
    ) {
        for (Vacancy__c Vacancy : sourceVacancyList) {
            if (!isOpened(Vacancy)) {
                continue;
            }

            if (canBeClosed(Vacancy)) {
                Vacancy.Status__c = RecruitmentConstants.VACANCY_STATUS_CLOSED;
                closedVacancyList.add(Vacancy);
            } else {
                Vacancy.Status__c = RecruitmentConstants.VACANCY_STATUS_CANCELLED;
                cancelledVacancyList.add(Vacancy);
            }
        }
    }

    public static void trySetVacancyCancelledStatus (List<Vacancy__c> sourceVacancyList, List<Vacancy__c> cancelledVacancyList) {
        for (Vacancy__c Vacancy : sourceVacancyList) {
            if (!isOpened(Vacancy)) {
                continue;
            }

            Vacancy.Status__c = RecruitmentConstants.VACANCY_STATUS_CANCELLED;
            cancelledVacancyList.add(Vacancy);
        }
    }

    public static Boolean isOpened(Vacancy__c Vacancy) {
        return Vacancy.Status__c != RecruitmentConstants.VACANCY_STATUS_CANCELLED
            && Vacancy.Status__c != RecruitmentConstants.VACANCY_STATUS_CLOSED;
    }

    public static Boolean canBeClosed(Vacancy__c Vacancy) {
        return isOpened(Vacancy) && Vacancy.Candidate__c != null && !String.isEmpty(Vacancy.Candidate__c);
    }
}