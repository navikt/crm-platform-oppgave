import doCalloutAndSync from '@salesforce/apex/CRM_OppgaveSyncController.doOppgaveSync';
import syncByExtRef from '@salesforce/apex/CRM_OppgaveSyncController.syncOppgaveByExtRef';

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

export function syncOppgaveById(oppgaveRef) {
    return syncByOppgaveId(oppgaveRef);
}

export function syncAssignedOppgaver(assigneeNavIdent) {
    let params = new OppgaveQueryParams();
    params.tilordnetRessurs = assigneeNavIdent;

    return this.syncOppgaver(params);
}

function syncByOppgaveId(oppgaveRef) {
    return new Promise((resolve, reject) => {
        syncByExtRef({ oppgaveRef: oppgaveRef })
            .then(() => {
                resolve('Success');
            })
            .catch((error) => {
                reject(error);
            });
    });
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
