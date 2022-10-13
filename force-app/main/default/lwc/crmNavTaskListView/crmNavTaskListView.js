import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getNavTaskRecords from '@salesforce/apex/CRM_NavTaskListViewCtrl.getRecords';
import syncNavTasks from '@salesforce/apex/CRM_NavTaskListViewCtrl.syncOpenAndAssigned';
import refreshAndSyncNavTasks from '@salesforce/apex/CRM_NavTaskListViewCtrl.refresh_syncOpenAndAssigned';

export default class CrmNavTaskListView extends NavigationMixin(LightningElement) {
    @api fieldsToDisplay;
    @api colHeaders;
    @api filterString;
    @api listTitle;
    @api ownedByRunningUser = false;
    @api numRecords = 10;
    @api listViewApiName;

    records = [];
    isLoading = false;

    connectedCallback() {
        this.isLoading = true;
        this.syncTasks();
    }

    syncTasks() {
        syncNavTasks({})
            .then(() => {
                //Success
                this.getNavTasks();
            })
            .catch((error) => {
                //Failed to sync
                console.log(JSON.stringify(error, null, 2));
            });
    }

    handleRefresh() {
        this.isLoading = true;
        refreshAndSyncNavTasks({ sfRecords: this.records })
            .then(() => {
                this.getNavTasks();
            })
            .catch((error) => {
                //Failed to sync
                console.log(JSON.stringify(error, null, 2));
                this.isLoading = false;
            });
    }

    getNavTasks() {
        getNavTaskRecords({
            fieldsToQuery: this.displayFields,
            filterString: this.filterString,
            ownedByRunningUser: this.ownedByRunningUser,
            numRecords: this.numRecords
        })
            .then((data) => {
                this.records = data;
            })
            .catch((error) => {
                console.log(JSON.stringify(error, null, 2));
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    navigateToListView() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'NavTask__c',
                actionName: 'list'
            },
            state: {
                filterName: this.listViewApiName
            }
        });
    }

    get hasRecords() {
        return this.records.length > 0;
    }

    get emptyState() {
        return this.records.length == 0 && this.isLoading == false;
    }

    get columnHeaders() {
        if (this.colHeaders) {
            return this.colHeaders.split(',');
        }
    }

    get colHeaderSize() {
        return this.columnHeaders.length > 0 ? Math.floor(12 / this.columnHeaders.length) : 12;
    }

    get displayFields() {
        if (this.fieldsToDisplay) {
            return this.fieldsToDisplay.replace(/\s+/g, '').split(',');
        }
    }
}
