import { LightningElement, api } from 'lwc';

export default class CrmOppgaveComments extends LightningElement {
    @api kommentarer;

    get formattedComments() {
        return (this.kommentarer ?? []).map((item) => ({
            tekst: item.tekst,
            opprettetAv: item.opprettet?.av?.medarbeider?.navident ?? '',
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

    get hasComments() {
        return this.kommentarer?.length > 0;
    }
}
