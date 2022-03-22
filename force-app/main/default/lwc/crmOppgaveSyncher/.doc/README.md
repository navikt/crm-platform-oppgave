# Oppgave Syncher

The crmOppgaveSyncher is a reusable component which export functionality to perform callouts to the oppgave API and synch the results in the NavTask\_\_c table. This keeps the sharing and access control intact. The query wrapper is defined as follows.

```
class OppgaveQueryParams {
    constructor() {
        this.aktoerId;
        this.id;
        this.orgnr;
        this.statuskategori;
        this.tildeltEnhetsnr;
        this.tilordnetRessurs;s
        this.fristFom;
        this.fristTom;
        this.opprettetFom;
    }
}
```

Also two essenstial functions can be imported from this component:

1. function syncActorOppgaver(actorId) --> Syncs oppgaver related to the given actor ID
2. function syncAssignedOppgaver(assigneeNavIdent) -> Syncs oppgave which are assigned to the specified NAV-ident
