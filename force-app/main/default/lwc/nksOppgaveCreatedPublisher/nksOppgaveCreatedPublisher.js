import { LightningElement, api, wire } from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { publish, MessageContext } from 'lightning/messageService';
import OPPGAVE_CREATED_CHANNEL from '@salesforce/messageChannel/oppgaveCreated__c';

export default class NksOppgaveCreatedPublisher extends LightningElement {
    @api availableActions = [];
    @api assignedResource;
    @api actorId;

    @wire(MessageContext) messageContext;

    connectedCallback() {
        try {
            publish(this.messageContext, OPPGAVE_CREATED_CHANNEL, {
                assignedResource: this.assignedResource ?? null,
                actorId: this.actorId ?? null
            });
        } catch (error) {
            console.error('Error publishing oppgaveCreated message:', error);
        } finally {
            if (this.availableActions?.includes('NEXT')) {
                this.dispatchEvent(new FlowNavigationNextEvent());
            } else if (this.availableActions?.includes('FINISH')) {
                this.dispatchEvent(new FlowNavigationFinishEvent());
            }
        }
    }
}
