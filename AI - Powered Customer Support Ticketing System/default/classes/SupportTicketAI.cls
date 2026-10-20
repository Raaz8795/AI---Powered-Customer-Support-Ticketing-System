public with sharing class SupportTicketAI {
    public class Suggestion {
        @AuraEnabled public String category;
        @AuraEnabled public String priority;
        @AuraEnabled public String sentiment;
        @AuraEnabled public String suggestedResponse;
        @AuraEnabled public String rationale;
    }

    @AuraEnabled
    public static Suggestion suggest(String subject, String description) {
        String textValue = ((subject == null ? '' : subject) + ' ' +
                            (description == null ? '' : description)).toLowerCase();
        Suggestion result = new Suggestion();
        result.category = 'General Inquiry';
        result.priority = 'Medium';
        result.sentiment = 'Neutral';
        result.suggestedResponse =
            'Thank you for contacting support. We have received your request and will investigate it.';
        result.rationale = 'Baseline keyword rules; review before sending.';

        if (textValue.contains('no service') || textValue.contains('outage') ||
            textValue.contains('no internet') || textValue.contains('network down')) {
            result.category = 'Network Issue';
            result.priority = 'High';
            result.suggestedResponse =
                'We are sorry you are experiencing a connectivity issue. Our support team will investigate and update you shortly.';
            result.rationale = 'Connectivity or outage keywords detected.';
        } else if (textValue.contains('bill') || textValue.contains('charged') ||
                   textValue.contains('payment')) {
            result.category = 'Billing';
            result.priority = 'Medium';
            result.suggestedResponse =
                'Thank you for flagging this billing concern. We will review the account charges and follow up.';
            result.rationale = 'Billing-related keywords detected.';
        } else if (textValue.contains('sim') || textValue.contains('activation') ||
                   textValue.contains('esim')) {
            result.category = 'SIM / Activation';
            result.priority = 'Medium';
            result.suggestedResponse =
                'We will check the SIM activation status and share the next steps.';
            result.rationale = 'SIM or activation keywords detected.';
        }

        if (textValue.contains('urgent') || textValue.contains('emergency') ||
            textValue.contains('business critical')) {
            result.priority = 'Critical';
        }
        if (textValue.contains('angry') || textValue.contains('unacceptable') ||
            textValue.contains('frustrated') || textValue.contains('terrible')) {
            result.sentiment = 'Negative';
        } else if (textValue.contains('thank') || textValue.contains('great') ||
                   textValue.contains('appreciate')) {
            result.sentiment = 'Positive';
        }
        return result;
    }
}
