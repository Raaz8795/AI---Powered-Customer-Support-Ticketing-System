import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTickets from '@salesforce/apex/SupportTicketController.getTickets';
import createTicketApex from '@salesforce/apex/SupportTicketController.createTicket';
import applySuggestionApex from '@salesforce/apex/SupportTicketController.applySuggestion';
import updateStatusApex from '@salesforce/apex/SupportTicketController.updateStatus';
import suggest from '@salesforce/apex/SupportTicketAI.suggest';

const EMPTY_SUGGESTION = {
    category: 'General Inquiry', priority: 'Medium', sentiment: 'Neutral',
    suggestedResponse: 'Thank you for contacting support. We have received your request and will investigate it.',
    rationale: 'Select Reclassify to generate a baseline suggestion.'
};

const STATUS_OPTIONS = ['New', 'In Progress', 'Waiting on Customer', 'Escalated', 'Resolved', 'Closed']
    .map(v => ({ label: v, value: v }));

export default class TelecomSupportConsole extends LightningElement {
    tickets = [];
    wiredResult;
    isLoading = true;
    isBusy = false;
    searchTerm = '';
    selectedId;
    suggestion = { ...EMPTY_SUGGESTION };
    responseDraft = '';
    errorMessage = '';
    showNewTicket = false;
    draftSubject = '';
    draftDescription = '';
    draftCustomer = '';
    statusOptions = STATUS_OPTIONS;

    @wire(getTickets)
    wiredTickets(result) {
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            this.tickets = data.map(r => ({
                id: r.Id,
                number: r.Name,
                subject: r.Subject__c || r.Name,
                description: r.Description__c || '',
                category: r.Category__c || 'General Inquiry',
                priority: r.Priority__c || 'Medium',
                status: r.Status__c || 'New',
                customer: r.Customer_Name__c || 'Unspecified Customer',
                sla: r.SLA_Deadline__c
            }));
            this.errorMessage = '';
            if (!this.tickets.some(t => t.id === this.selectedId)) {
                this.selectedId = this.tickets.length ? this.tickets[0].id : undefined;
                if (this.selectedId) {
                    this.runSuggestion();
                }
            }
        } else if (error) {
            this.tickets = [];
            this.errorMessage = this.reduceError(error, 'Could not load tickets. Confirm the permission set is assigned.');
        }
        this.isLoading = false;
    }

    get filteredTickets() {
        const q = (this.searchTerm || '').toLowerCase();
        return this.tickets
            .filter(t => `${t.number} ${t.subject} ${t.description} ${t.category} ${t.status} ${t.customer}`
                .toLowerCase().includes(q))
            .map(t => ({
                ...t,
                rowClass: `ticket-row ${t.id === this.selectedId ? 'selected' : ''}`,
                priorityClass: `priority priority-${t.priority.toLowerCase()}`
            }));
    }
    get hasTickets() { return this.filteredTickets.length > 0; }
    get selectedTicket() {
        const t = this.tickets.find(item => item.id === this.selectedId);
        return t ? { ...t, priorityClass: `priority priority-${t.priority.toLowerCase()}` } : null;
    }
    get totalCount() { return this.tickets.length; }
    get openCount() { return this.tickets.filter(t => t.status !== 'Resolved' && t.status !== 'Closed').length; }
    get urgentCount() { return this.tickets.filter(t => ['High', 'Critical'].includes(t.priority)).length; }

    handleSearch(event) { this.searchTerm = event.target.value; }

    selectTicket(event) {
        this.selectedId = event.currentTarget.dataset.id;
        this.errorMessage = '';
        this.runSuggestion();
    }

    async runSuggestion() {
        const ticket = this.tickets.find(t => t.id === this.selectedId);
        if (!ticket) return;
        try {
            this.suggestion = await suggest({ subject: ticket.subject, description: ticket.description });
            this.responseDraft = this.suggestion.suggestedResponse;
            this.errorMessage = '';
        } catch (error) {
            this.suggestion = { ...EMPTY_SUGGESTION };
            this.errorMessage = this.reduceError(error, 'Could not load suggestions. Confirm Apex deployment and permissions.');
        }
    }

    handleResponseChange(event) {
        this.responseDraft = event.target.value;
        this.suggestion = { ...this.suggestion, suggestedResponse: event.target.value };
    }

    async useSuggestion() {
        if (!this.selectedId) return;
        this.isBusy = true;
        try {
            await applySuggestionApex({
                ticketId: this.selectedId,
                category: this.suggestion.category,
                priority: this.suggestion.priority,
                sentiment: this.suggestion.sentiment
            });
            await refreshApex(this.wiredResult);
            this.toast('Ticket updated', 'Category, priority, sentiment and SLA deadline were saved.', 'success');
        } catch (error) {
            this.toast('Could not save', this.reduceError(error, 'Update failed.'), 'error');
        } finally {
            this.isBusy = false;
        }
    }

    async handleStatusChange(event) {
        const status = event.detail.value;
        if (!this.selectedId) return;
        this.isBusy = true;
        try {
            await updateStatusApex({ ticketId: this.selectedId, status });
            await refreshApex(this.wiredResult);
            this.toast('Status updated', `Ticket moved to ${status}.`, 'success');
        } catch (error) {
            this.toast('Could not save', this.reduceError(error, 'Status update failed.'), 'error');
        } finally {
            this.isBusy = false;
        }
    }

    openNewTicket() { this.showNewTicket = true; }
    closeNewTicket() { this.showNewTicket = false; }
    changeDraftSubject(event) { this.draftSubject = event.target.value; }
    changeDraftDescription(event) { this.draftDescription = event.target.value; }
    changeDraftCustomer(event) { this.draftCustomer = event.target.value; }

    async createTicket() {
        if (!this.draftSubject.trim()) {
            this.toast('Subject required', 'Enter a ticket subject.', 'error');
            return;
        }
        this.isBusy = true;
        try {
            const newId = await createTicketApex({
                subject: this.draftSubject,
                description: this.draftDescription,
                customerName: this.draftCustomer
            });
            this.selectedId = newId;
            this.showNewTicket = false;
            this.draftSubject = '';
            this.draftDescription = '';
            this.draftCustomer = '';
            await refreshApex(this.wiredResult);
            this.runSuggestion();
            this.toast('Ticket created', 'Category, priority and SLA were set automatically.', 'success');
        } catch (error) {
            this.toast('Could not create ticket', this.reduceError(error, 'Create failed.'), 'error');
        } finally {
            this.isBusy = false;
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error, fallback) {
        const body = error && error.body;
        if (Array.isArray(body)) return body.map(e => e.message).join(', ');
        return (body && body.message) || (error && error.message) || fallback;
    }
}
