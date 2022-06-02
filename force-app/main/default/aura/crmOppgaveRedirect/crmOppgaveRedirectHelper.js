({
    runFlow: function (cmp) {
        const flow = cmp.find('flow');

        const oppgaveId = this.getOppgaveId(cmp);
        let inputVariables = [];
        inputVariables.push({ name: 'oppgaveId', type: 'String', value: oppgaveId });
        flow.startFlow(cmp.get('v.flowApiName'), inputVariables);
    },

    getOppgaveId: function (cmp) {
        const state = cmp.get('v.pageReference').state;
        const oppgaveId = state['c__oppgaveId'];
        return oppgaveId;
    }
});
