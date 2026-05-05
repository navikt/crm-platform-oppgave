({
    init: function (component) {
        const pageRef = component.get('v.pageReference');
        if (!pageRef || !pageRef.state) return;
        const state = pageRef.state;
        const ownedByRunningUser = state.c__ownedByRunningUser === 'true' || state.c__ownedByRunningUser === true;

        const oppgaveTable = component.find('oppgaveTable');
        oppgaveTable.set('v.ownedByRunningUser', ownedByRunningUser);
        oppgaveTable.set('v.personIdent', state.c__personIdent || null);
        oppgaveTable.set('v.actorId', state.c__actorId || null);

        const workspace = component.find('workspace');
        workspace.getEnclosingTabId().then(function (tabId) {
            if (!tabId) return;
            workspace.setTabLabel({ tabId: tabId, label: 'Oppgaver' });
            workspace.setTabIcon({ tabId: tabId, icon: 'standard:task' });
        });
    }
});
