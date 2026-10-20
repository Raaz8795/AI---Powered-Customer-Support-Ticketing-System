## Overview

Telecom Support is designed to help support teams track customer issues in one place, apply consistent service-level targets, and monitor ticket workload. The solution uses a custom **Support Ticket** object and Salesforce Flow Builder for declarative automation.

The application includes a Support Ticket Overview report and a Telecom Support Dashboard. The dashboard visualizes ticket counts by priority so that support teams can quickly review the current workload.

## Objectives

- Centralize telecom customer issues in a dedicated Support Ticket record.
- Calculate SLA deadlines according to ticket priority.
- Escalate eligible Low-priority tickets to High after four hours.
- Send notifications for high-priority tickets, approaching SLA deadlines, and SLA breaches.
- Summarize ticket data through reports and dashboards.
- Document configuration and testing evidence for maintenance and review.

## Features

| Feature | Description |
|---|---|
| Ticket management | Stores ticket subject, customer, category, description, priority, status, sentiment, and SLA deadline. |
| Automatic ticket numbering | Uses an auto-number ticket identifier with the `ST-{00000}` display pattern. |
| Priority-based SLA | Calculates the deadline from the selected priority. |
| Scheduled escalation | Checks eligible Low-priority tickets after four hours and escalates tickets that remain open and Low. |
| Email notifications | Includes flows for high-priority alerts, SLA reminders, and SLA-breach alerts. |
| Reporting | Groups support ticket records by priority and displays key ticket fields. |
| Dashboard | Shows ticket record counts by priority. |

## Technology Stack

- **Platform:** Salesforce Lightning Experience
- **Automation:** Salesforce Flow Builder (record-triggered flows and scheduled paths)
- **Data:** Salesforce custom object and fields
- **Analytics:** Salesforce Reports and Dashboards
- **Notifications:** Salesforce email alerts/actions configured in the org

## System Architecture

```text
Salesforce Lightning App: Telecom Support
                  |
                  v
        Support Ticket Object
                  |
       +----------+-----------+
       |                      |
       v                      v
 Flow Builder             Reporting Layer
       |                      |
       +-- Set Support        +-- Support Ticket Overview
       |   Ticket SLA         |
       +-- Escalate Critical  +-- Telecom Support Dashboard
       |   Support Tickets
       +-- High Priority Ticket Notification
       +-- SLA Deadline Reminder
       +-- SLA Breach Detection
                  |
                  v
       Email alerts when configured
       flow conditions are satisfied
```

**Typical process:** A ticket is created or updated → the SLA flow calculates its deadline → scheduled or update-triggered flows evaluate relevant conditions → an eligible escalation or email alert runs → reports and dashboards summarize the records.

## Data Model

Primary object: **Support Ticket** (`Support_Ticket__c`).

| Field | Purpose |
|---|---|
| Ticket Number | Auto-generated ticket reference, displayed as `ST-{00000}`. |
| Subject | Short title describing the issue. |
| Customer Name | Customer label associated with the ticket. |
| Category | Issue category, such as Network Issue. |
| Description | Details supplied about the issue. |
| Priority | Low, Medium, or High; drives SLA timing and escalation checks. |
| SLA Deadline | Target date/time calculated by the SLA flow. |
| Status | Ticket lifecycle status, such as New or Closed. |
| Customer Sentiment | Positive, Neutral, or Negative. |

Confirm exact field API names and picklist values in **Setup → Object Manager → Support Ticket** before importing or deploying metadata.

## Automation and Business Rules

### 1. Set Support Ticket SLA

- **Purpose:** Set the SLA deadline when a Support Ticket is created.
- **Trigger / optimization:** Record-triggered flow, configured for Fast Field Updates.
- **Logic:** A priority decision routes the record through the High, Medium, or Low branch.
- **Configured targets:**

| Priority | SLA target |
|---|---:|
| High | 4 hours |
| Medium | 8 hours |
| Low | 24 hours (1 day) |

These are elapsed-time offsets. They do not automatically account for business hours, weekends, or holidays.

### 2. Escalate Critical Support Tickets

- **Purpose:** Escalate tickets that remain Low priority and open.
- **Scheduled path:** `Escalate After 4 Hours`.
- **Condition:** At the scheduled evaluation, the ticket must still be Low priority and not Closed.
- **Action:** Set Priority to High.
- **Validation:** Test with a Low/New ticket and verify that it qualifies after four hours. Also test a ticket that is closed or changed to another priority before the scheduled path executes.

### 3. High Priority Ticket Notification

- **Purpose:** Send an alert when a ticket meets the configured high-priority flow entry criteria.
- **Action:** `Send High Priority Alert`.
- **Validation:** Update or create a ticket that satisfies the actual start conditions, then verify the flow interview and email delivery. A debug run that does not meet entry conditions is not proof of a successful notification.

### 4. SLA Deadline Reminder

- **Purpose:** Notify the configured recipient when a ticket meets the reminder criteria.
- **Scheduled path:** `SLA Reminder`.
- **Action:** `Send SLA Deadline Reminder`.
- **Validation:** Confirm the scheduled time, decision conditions, recipient configuration, and email delivery using a qualifying test record.

### 5. SLA Breach Detection

- **Purpose:** Identify an overdue ticket and send a breach alert.
- **Scheduled path:** `SLA Breach Check`.
- **Logic:** Evaluates ticket status and compares the SLA Deadline with the configured current date/time resource.
- **Action:** `Send SLA Breach Alert`.
- **Validation:** Test with a ticket whose SLA deadline has passed and whose status meets the flow conditions.

> **Important:** Flow names, active status, and visible configuration do not by themselves prove that scheduled paths executed or emails were delivered. Verify each behavior with test records and debug/run evidence.

## Reports and Dashboard

### Support Ticket Overview

The report uses the **Support Tickets** report type and includes fields such as:

- Ticket Number
- Subject
- Status
- Category
- SLA Deadline
- Customer Sentiment

Records are grouped by Priority. Sample evidence captured five tickets, with counts of Low = 3, Medium = 1, and High = 1. These are example counts from the captured report and will change as records change.

### Telecom Support Dashboard

The dashboard includes a donut chart showing record count by Priority. The captured example showed five total tickets. Dashboard values are live summaries of the underlying report and should not be treated as fixed project metrics.

## Repository Structure

Keep the repository organized so that implementation files, documentation, and evidence are easy to find. Adjust folder names to match the actual files committed to GitHub.

```text
Telecom-Support/
├── README.md
├── force-app/                 # Salesforce metadata, if included
│   └── main/
│       └── default/
│           ├── objects/
│           ├── flows/
│           ├── layouts/
│           └── ...
├── docs/
│   ├── Telecom_Support_Project_Documentation.docx
│   └── screenshots/
│       ├── support-ticket-report.png
│       ├── support-dashboard.png
│       ├── sla-calculation-flow.png
│       ├── sla-breach-flow.png
│       ├── sla-reminder-flow.png
│       ├── escalation-flow.png
│       └── priority-notification-flow.png
└── sfdx-project.json           # Include if this is a Salesforce DX project
```

Only include folders and files that actually exist in the repository. If the Salesforce metadata or `sfdx-project.json` is not available, do not create placeholder claims that imply a deployable Salesforce DX project is present.

## Setup and Configuration

### Prerequisites

- Access to a Salesforce org with permission to create or edit custom objects, flows, email alerts, reports, and dashboards.
- The required Support Ticket object, fields, picklist values, and automation configured in that org.
- Email deliverability and sender/recipient settings configured if testing notifications.

### Configure in Salesforce

1. Open **Setup → Object Manager** and confirm the Support Ticket object and its fields.
2. Confirm the priority and status picklist values used by each flow.
3. Open **Setup → Flows** and review each flow's trigger, entry criteria, decisions, scheduled paths, and actions.
4. Verify that email alerts/actions have valid recipients and are permitted by org email settings.
5. Open **Reports** and confirm the Support Ticket Overview report fields and grouping.
6. Open **Dashboards** and confirm the Telecom Support Dashboard is connected to the intended report.
7. Run the test cases below before presenting the solution as production-ready.

### Salesforce DX deployment (only if metadata is included)

If the repository contains `sfdx-project.json` and Salesforce metadata, open a terminal in the project root, authenticate to the target org, and deploy using the Salesforce CLI appropriate to your installed version. Review deployment output and test the deployed flows in the target org. A README alone or a screenshots-only repository cannot deploy the Salesforce configuration.

## Testing Checklist

- [ ] Create a ticket with High priority and verify an SLA deadline approximately four hours from creation.
- [ ] Create a ticket with Medium priority and verify an SLA deadline approximately eight hours from creation.
- [ ] Create a ticket with Low priority and verify an SLA deadline approximately 24 hours from creation.
- [ ] Verify a Low/New ticket escalates to High after the scheduled four-hour path when it still qualifies.
- [ ] Verify a closed ticket is not escalated.
- [ ] Verify a ticket changed from Low before the scheduled path is evaluated is handled as intended.
- [ ] Test the high-priority notification with a record that meets its entry criteria.
- [ ] Test the SLA reminder with a qualifying ticket.
- [ ] Test the SLA-breach alert with an overdue ticket.
- [ ] Verify actual email delivery and recipients.
- [ ] Confirm report groupings and dashboard totals match the underlying records.



## Known Limitations

- SLA targets currently use elapsed-time offsets and may include nights, weekends, and holidays.
- Scheduled automation and email delivery require end-to-end verification in the target org.
- Report and dashboard values depend on the current sample records.
- Notification delivery depends on email settings, recipient configuration, and org permissions.
- A configured Flow is declarative automation; do not describe it as generative AI unless an actual AI service or Agentforce capability is implemented and verified.
- Deployment instructions apply only if Salesforce metadata and a valid Salesforce DX project are included in the repository.

## Future Enhancements

- Add business-hours SLA calculations and holiday handling.
- Add fault paths and error logging for critical flows.
- Track escalation history and notification outcomes.
- Expand reports for open tickets, overdue tickets, ticket aging, and resolution trends.
- Add repeatable test data and documented test results.
- Consider AI-assisted classification or response suggestions only after selecting, configuring, and validating the relevant Salesforce AI capability.

