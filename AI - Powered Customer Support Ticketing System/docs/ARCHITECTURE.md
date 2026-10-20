# Architecture

- **Experience layer:** Lightning Web Component `telecomSupportConsole`.
- **Application logic:** Apex `SupportTicketAI` returns baseline category, priority, sentiment, and response suggestions.
- **Data layer:** `Support_Ticket__c` custom object.
- **Security:** starter permission set; production must validate CRUD/FLS, sharing, and access to any AI grounding source.
- **AI extension point:** replace the baseline Apex keyword service with a supported Agentforce prompt template or agent action.
- **Analytics:** add native Salesforce reports and dashboards for ticket volume, SLA compliance, category mix, and agent performance.

The current LWC uses seed data for its interactive prototype. Ticket creation and “Use suggestion” modify local component state only; they do not insert or update Salesforce records. Connect record persistence through secure Apex or Lightning Data Service before using it operationally.
