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

export function syncActorOppgaver(actorId) {
    let params = new OppgaveQueryParams();
    params.aktoerId = actorId;

    return syncOppgaver(params);
}

export function syncAssignedOppgaver(assigneeNavIdent) {
    let params = new OppgaveQueryParams();
    params.tilordnetRessurs = assigneeNavIdent;

    return this.syncOppgaver(params);
}
//input object that is passed to apex performing callout to generate NavTask__c representation of the response
function syncOppgaver(queryParams) {
    return new Promise((resolve, reject) => {
        doCalloutAndSync({ jsonQuery: JSON.stringify(queryParams) })
            .then(() => {
                resolve('Success');
            })
            .catch((error) => {
                reject(error);
            });
    });
}
