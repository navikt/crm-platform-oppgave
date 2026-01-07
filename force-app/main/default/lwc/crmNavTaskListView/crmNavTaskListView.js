import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getNavTaskRecords from '@salesforce/apex/CRM_NavTaskListViewCtrl.getRecords';
import syncNavTasks from '@salesforce/apex/CRM_NavTaskListViewCtrl.syncOpenAndAssigned';
import refreshAndSyncNavTasks from '@salesforce/apex/CRM_NavTaskListViewCtrl.refresh_syncOpenAndAssigned';
import { refreshApex } from '@salesforce/apex';

export default class CrmNavTaskListView extends NavigationMixin(LightningElement) {
    @api fieldsToDisplay = '';
    @api colHeaders;
    @api filterString = '';
    @api listTitle;
    @api ownedByRunningUser = false;
    @api numRecords = 10;
    @api listViewApiName;

    records = [];
    wiredNavTaskResult;
    isRefreshDisabled = false;
    isLoading = false;

    connectedCallback() {
        this.syncTasks();
    }

    syncTasks() {
        this.isLoading = true;
        syncNavTasks({})
            .then(() => {
                refreshApex(this.wiredNavTaskResult);
            })
            .catch((error) => {
                console.error('Error syncing tasks:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleRefresh() {
        if (this.isLoading || this.isRefreshDisabled) return;
        this.isLoading = true;
        this.isRefreshDisabled = true;

        refreshAndSyncNavTasks({ sfRecords: this.records })
            .then(() => {
                refreshApex(this.wiredNavTaskResult);
            })
            .catch((error) => {
                console.error('Error syncing tasks:', error);
            })
            .finally(() => {
                this.isLoading = false;
                setTimeout(() => {
                    // 10 sec delay to avoid spamming requests
                    this.isRefreshDisabled = false;
                }, 10000);
            });
    }

    @wire(getNavTaskRecords, {
        fieldsToQuery: '$displayFields',
        filterString: '$filterString',
        ownedByRunningUser: '$ownedByRunningUser',
        numRecords: '$numRecords'
    })
    wiredTasks(result) {
        this.wiredNavTaskResult = result;
        if (result.data) {
            this.records = result.data;
        } else if (result.error) {
            console.error('Error fetching tasks:', result.error);
        }
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
        return !this.hasRecords && !this.isLoading;
    }

    get columnHeaders() {
        return this.colHeaders?.split(',') || [];
    }

    get colHeaderSize() {
        return this.columnHeaders.length > 0 ? Math.floor(12 / this.columnHeaders.length) : 12;
    }

    get displayFields() {
        return this.fieldsToDisplay?.replace(/\s+/g, '').split(',') || [];
    }
}
