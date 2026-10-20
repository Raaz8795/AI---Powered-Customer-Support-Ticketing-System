public with sharing class SupportTicketController {

    private static final Map<String, Integer> SLA_HOURS = new Map<String, Integer>{
        'Critical' => 1,
        'High'     => 4,
        'Medium'   => 24,
        'Low'      => 72
    };

    @AuraEnabled(cacheable=true)
    public static List<Support_Ticket__c> getTickets() {
        return [
            SELECT Id, Name, Subject__c, Description__c, Category__c, Priority__c,
                   Status__c, Customer_Name__c, Customer_Sentiment__c, SLA_Deadline__c, CreatedDate
            FROM Support_Ticket__c
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }

    /** Creates a ticket and fills category, priority, sentiment and SLA from the AI suggestion. */
    @AuraEnabled
    public static Id createTicket(String subject, String description, String customerName) {
        if (String.isBlank(subject)) {
            throw new AuraHandledException('Subject is required.');
        }
        SupportTicketAI.Suggestion s = SupportTicketAI.suggest(subject, description);
        Support_Ticket__c t = new Support_Ticket__c(
            Subject__c = subject.trim().left(255),
            Description__c = description,
            Customer_Name__c = String.isBlank(customerName) ? null : customerName.trim().left(120),
            Category__c = s.category,
            Priority__c = s.priority,
            Customer_Sentiment__c = s.sentiment,
            Status__c = 'New',
            SLA_Deadline__c = Datetime.now().addHours(hoursFor(s.priority))
        );
        try {
            insert as user t;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        }
        return t.Id;
    }

    /** Applies the AI suggestion to an existing ticket and recalculates the SLA from creation time. */
    @AuraEnabled
    public static void applySuggestion(Id ticketId, String category, String priority, String sentiment) {
        Support_Ticket__c t = loadTicket(ticketId);
        t.Category__c = category;
        t.Priority__c = priority;
        t.Customer_Sentiment__c = sentiment;
        t.SLA_Deadline__c = t.CreatedDate.addHours(hoursFor(priority));
        saveTicket(t);
    }

    @AuraEnabled
    public static void updateStatus(Id ticketId, String status) {
        Support_Ticket__c t = new Support_Ticket__c(Id = ticketId, Status__c = status);
        saveTicket(t);
    }

    private static Support_Ticket__c loadTicket(Id ticketId) {
        List<Support_Ticket__c> rows = [
            SELECT Id, CreatedDate FROM Support_Ticket__c WHERE Id = :ticketId WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) {
            throw new AuraHandledException('Ticket not found or you do not have access.');
        }
        return rows[0];
    }

    private static void saveTicket(Support_Ticket__c t) {
        try {
            update as user t;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        }
    }

    @TestVisible
    private static Integer hoursFor(String priority) {
        return SLA_HOURS.containsKey(priority) ? SLA_HOURS.get(priority) : 24;
    }
}
