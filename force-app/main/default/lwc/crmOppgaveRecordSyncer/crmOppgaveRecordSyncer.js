import { LightningElement, api, wire } from 'lwc';
import { syncOppgaveById, syncOppgaveOppfolgingById } from 'c/crmOppgaveSyncher';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
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
            Promise.allSettled([syncOppgaveById(oppgaveRef), syncOppgaveOppfolgingById(oppgaveRef)])
                .then((results) => {
                    const success = results.some(result => result.status === 'fulfilled');
                    if (success) {
                        // One or both syncs completed successfully
                        notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                    }
                })
                .catch((error) => {
                    console.error('Error syncing oppgave and/or oppfølging: ' + JSON.stringify(error, null, 2));
                });
        } else if (error) {
            console.log('An error occurred: ' + JSON.stringify(error, null, 2));
        }
    }
}
