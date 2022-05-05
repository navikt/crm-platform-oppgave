({
    init: function (cmp, event, helper) {
        helper.runFlow(cmp);
    },

    handleStatusChange: function (component, event) {
        //Check if flow is finished
        const status = event.getParam('status');

        if (status === 'FINISHED' || status === 'FINISHED_SCREEN') {
            let workspaceAPI = component.find('workspace');
            workspaceAPI
                .getEnclosingTabId()
                .then((tabId) => {
                    workspaceAPI
                        .closeTab({ tabId: tabId })
                        .then((response) => {
                            //Success
                        })
                        .catch((error) => {
                            console.log(JSON.stringify(error, null, 2));
                        });
                })
                .catch((error) => {
                    console.log(JSON.stringify(error, null, 2));
                });
        }
    }
});
