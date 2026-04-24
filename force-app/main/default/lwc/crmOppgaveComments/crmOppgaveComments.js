import { LightningElement, api, wire } from 'lwc';
import getOppgaveOppfolging from '@salesforce/apex/OppgaveManager.getOppgaveOppfolging';

export default class CrmOppgaveComments extends LightningElement {
    @api oppgaveId;

    comment;
    errorMessage;

    @wire(getOppgaveOppfolging, { oppgaveId: '$oppgaveId' })
    wiredComment({ data, error }) {
        if (data) {
            this.comment = data.map((item) => ({
                ...item,
                opprettetTidspunktFormatted: item.opprettetTidspunkt
                    ? new Date(item.opprettetTidspunkt).toLocaleString('nb-NO', {
                          day: '2-digit',
                          month: '2-digit',
                          year: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit'
                      })
                    : ''
            }));
        }
        if (error) {
            console.error('Error in wiredComment:', JSON.stringify(error, null, 2));
            this.errorMessage = error?.body?.message ?? JSON.stringify(error);
        }
    }

    get hasComments() {
        return this.comment?.length > 0;
    }
}
