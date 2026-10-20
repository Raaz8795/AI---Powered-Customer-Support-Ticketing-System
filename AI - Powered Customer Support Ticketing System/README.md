# Telecom Support — Salesforce Support Ticket Management System

## Project Overview
Telecom Support is a Salesforce Lightning application designed to manage customer support tickets, calculate SLA deadlines, escalate unresolved tickets, send email notifications, and visualize ticket metrics through reports and dashboards.

## Features
- Support Ticket management with priority, status, category, and customer sentiment.
- Automatic SLA deadline calculation based on priority.
- Scheduled escalation of eligible Low-priority tickets to High after four hours.
- High-priority ticket email notifications.
- SLA deadline reminders and SLA-breach alerts.
- Support Ticket Overview report grouped by priority.
- Telecom Support Dashboard with a donut chart showing ticket counts by priority.

## Technology Stack
- Salesforce Lightning Experience
- Salesforce Flow Builder
- Custom Support Ticket object
- Salesforce Email Alerts
- Salesforce Reports and Dashboards

## Project Architecture
Support Ticket Records → Record-Triggered Flows → SLA Calculation and Scheduled Actions → Email Alerts → Reports and Dashboard.

## Test Evidence
See the `screenshots/` folder for screenshots of the Support Ticket records, report results, and dashboard.

## Documentation
The `docs/` folder contains the project documentation and system architecture.

## Notes
The project was configured and tested in a Salesforce Developer Edition environment. Scheduled execution and email delivery should be verified in the target environment before production use.
