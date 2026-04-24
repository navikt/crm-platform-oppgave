import { LightningElement, api, wire } from 'lwc';
import getOppgaveById from '@salesforce/apex/OppgaveManager.getOppgaveById';

export default class CrmOppgaveComments extends LightningElement {
    @api oppgaveId;

    comment;
    errorMessage;

    @wire(getOppgaveById, { oppgaveId: '$oppgaveId' })
    wiredComment({ data, error }) {
        if (data) {
            this.comment = (data.kommentarer ?? []).map((item) => ({
                ...item,
                opprettetTidspunktFormatted: item.opprettet?.tidspunkt
                    ? new Date(item.opprettet.tidspunkt).toLocaleString('nb-NO', {
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
