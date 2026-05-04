({
    init: function (component) {
        const pageRef = component.get('v.pageReference');
        const state = (pageRef && pageRef.state) || {};

        const ownedByRunningUser = state.c__ownedByRunningUser === 'true' || state.c__ownedByRunningUser === true;
        component.set('v.ownedByRunningUser', ownedByRunningUser);
        component.set('v.personIdent', state.c__personIdent || null);
        component.set('v.actorId', state.c__actorId || null);

        const workspace = component.find('workspace');
        if (workspace && workspace.getEnclosingTabId) {
            workspace
                .getEnclosingTabId()
                .then(function (tabId) {
                    if (!tabId) return;
                    workspace.setTabLabel({ tabId: tabId, label: 'Oppgaver' });
                    workspace.setTabIcon({ tabId: tabId, icon: 'standard:task' });
                })
                .catch(function () {});
        }
    }
});
