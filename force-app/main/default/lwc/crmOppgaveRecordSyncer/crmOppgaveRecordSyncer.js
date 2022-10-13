import { LightningElement, api, wire } from 'lwc';
import { syncOppgaveById } from 'c/crmOppgaveSyncher';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import EXTERNAL_REF_FIELD from '@salesforce/schema/NavTask__c.INT_External_Reference__c';

export default class CrmOppgaveRecordSyncer extends LightningElement {
    @api recordId;
    @api objectApiName;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [EXTERNAL_REF_FIELD]
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
            const oppgaveRef = getFieldValue(data, EXTERNAL_REF_FIELD);
            syncOppgaveById(oppgaveRef)
                .then(() => {
                    //Synced
                    getRecordNotifyChange([{ recordId: this.recordId }]);
                })
                .catch((error) => {
                    console.log('Error syncing oppgave: ' + JSON.stringify(error, null, 2));
                });
        } else if (error) {
            console.log('An error occurred: ' + JSON.stringify(error, null, 2));
        }
    }
}
