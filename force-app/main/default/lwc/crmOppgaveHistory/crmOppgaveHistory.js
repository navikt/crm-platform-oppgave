import { LightningElement, api } from 'lwc';

export default class CrmOppgaveHistory extends LightningElement {
    @api comment;

    get tekst() {
        return this.comment?.tekst;
    }
}
