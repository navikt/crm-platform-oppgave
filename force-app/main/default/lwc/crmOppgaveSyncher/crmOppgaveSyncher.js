export default { syncOppgaver, syncActorOppgaver, syncAssignedOppgaver };
import doCalloutAndSync from '@salesforce/apex/CRM_OppgaveSyncController.doOppgaveSync';

class OppgaveQueryParams {
    constructor() {
        this.aktoerId;
        this.id;
        this.orgnr;
        this.statuskategori;
        this.tildeltEnhetsnr;
        this.tilordnetRessurs;
        this.fristFom;
        this.fristTom;
        this.opprettetFom;
    }
}

function syncActorOppgaver(actorId) {
    let params = new OppgaveQueryParams();
    params.aktoerId = actorId;

    return this.syncOppgaver(params);
}

function syncAssignedOppgaver(assigneeNavIdent) {
    let params = new OppgaveQueryParams();
    params.tilordnetRessurs = assigneeNavIdent;

    return this.syncOppgaver(params);
}
//input object that is passed to apex performing callout to generate NavTask__c representation of the response
function syncOppgaver(queryParams) {
    return new Promise((resolve, reject) => {
        doCalloutAndSync({ query: queryParams })
            .then(() => {
                resolve('Success');
            })
            .catch((error) => {
                reject(error);
            });
    });
}
