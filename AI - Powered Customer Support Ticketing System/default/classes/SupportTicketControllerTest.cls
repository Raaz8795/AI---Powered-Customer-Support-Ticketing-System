@IsTest
private class SupportTicketControllerTest {

    private static User makeAgent() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String uniq = String.valueOf(Crypto.getRandomInteger()).replace('-', '');
        User u = new User(
            Alias = 'tagent', Email = 'tagent' + uniq + '@example.com',
            Username = 'tagent' + uniq + '@example.com.test', LastName = 'Agent',
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata', ProfileId = p.Id
        );
        insert u;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Telecom_Support_Agent' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        return u;
    }

    @IsTest
    static void createsTicketWithAiFieldsAndSla() {
        User agent;
        System.runAs(new User(Id = UserInfo.getUserId())) { agent = makeAgent(); }
        System.runAs(agent) {
            Id tid = SupportTicketController.createTicket('No internet', 'Network down, urgent', 'Test Customer');
            Support_Ticket__c t = [
                SELECT Subject__c, Category__c, Priority__c, Status__c, SLA_Deadline__c, Customer_Name__c
                FROM Support_Ticket__c WHERE Id = :tid
            ];
            System.assertEquals('Network Issue', t.Category__c);
            System.assertEquals('Critical', t.Priority__c);
            System.assertEquals('New', t.Status__c);
            System.assertEquals('Test Customer', t.Customer_Name__c);
            System.assertNotEquals(null, t.SLA_Deadline__c);
            System.assertEquals(1, SupportTicketController.getTickets().size());
        }
    }

    @IsTest
    static void blankSubjectIsRejected() {
        User agent;
        System.runAs(new User(Id = UserInfo.getUserId())) { agent = makeAgent(); }
        System.runAs(agent) {
            try {
                SupportTicketController.createTicket('  ', 'x', null);
                System.assert(false, 'Expected an exception');
            } catch (AuraHandledException e) {
                System.assert(true);
            }
        }
    }

    @IsTest
    static void appliesSuggestionAndUpdatesStatus() {
        User agent;
        System.runAs(new User(Id = UserInfo.getUserId())) { agent = makeAgent(); }
        System.runAs(agent) {
            Id tid = SupportTicketController.createTicket('Question', 'General question', null);
            SupportTicketController.applySuggestion(tid, 'Billing', 'High', 'Negative');
            SupportTicketController.updateStatus(tid, 'Resolved');
            Support_Ticket__c t = [
                SELECT Category__c, Priority__c, Customer_Sentiment__c, Status__c FROM Support_Ticket__c WHERE Id = :tid
            ];
            System.assertEquals('Billing', t.Category__c);
            System.assertEquals('High', t.Priority__c);
            System.assertEquals('Negative', t.Customer_Sentiment__c);
            System.assertEquals('Resolved', t.Status__c);
        }
    }

    @IsTest
    static void slaHoursByPriority() {
        System.assertEquals(1, SupportTicketController.hoursFor('Critical'));
        System.assertEquals(4, SupportTicketController.hoursFor('High'));
        System.assertEquals(72, SupportTicketController.hoursFor('Low'));
        System.assertEquals(24, SupportTicketController.hoursFor('Unknown'));
    }
}
