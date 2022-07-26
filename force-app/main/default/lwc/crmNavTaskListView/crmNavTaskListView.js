import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getNavTaskRecords from '@salesforce/apex/CRM_NavTaskListViewCtrl.getRecords';

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
        this.getNavTasks();
    }

    handleRefresh() {
        this.isLoading = true;
        this.getNavTasks();
    }

    getNavTasks() {
        getNavTaskRecords({
            fieldsToQuery: this.displayFields,
            filterString: this.filterString,
            ownedByRunningUser: this.ownedByRunningUser,
            numRecords: this.numRecords
        })
            .then((data) => {
                console.log(JSON.stringify(data, null, 2));
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
        return this.records.length > 0 || this.isLoading == false;
    }

    get emptyState() {
        return this.records.length == 0 && this.isLoading == false;
    }

    get columnHeaders() {
        if (this.colHeaders) {
            return this.colHeaders.split(',');
        }
    }

    get displayFields() {
        if (this.fieldsToDisplay) {
            return this.fieldsToDisplay.replace(/\s+/g, '').split(',');
        }
    }
}
