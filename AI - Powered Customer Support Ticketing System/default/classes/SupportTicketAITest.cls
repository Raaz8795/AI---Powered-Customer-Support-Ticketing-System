@IsTest
private class SupportTicketAITest {
    @IsTest
    static void classifiesNetworkOutage() {
        SupportTicketAI.Suggestion s = SupportTicketAI.suggest(
            'No internet connection', 'Network down for our office; urgent'
        );
        System.assertEquals('Network Issue', s.category);
        System.assertEquals('Critical', s.priority);
    }

    @IsTest
    static void detectsNegativeSentiment() {
        SupportTicketAI.Suggestion s = SupportTicketAI.suggest(
            'Billing problem', 'This charge is unacceptable and frustrating'
        );
        System.assertEquals('Billing', s.category);
        System.assertEquals('Negative', s.sentiment);
    }
}
