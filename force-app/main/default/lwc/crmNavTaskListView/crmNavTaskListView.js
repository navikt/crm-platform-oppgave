import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getListInfoByName } from 'lightning/uiListsApi';
import NAV_TASK_OBJECT from '@salesforce/schema/NavTask__c';
import getNavTaskRecords from '@salesforce/apex/CRM_NavTaskListViewCtrl.getRecords';

export default class CrmNavTaskListView extends NavigationMixin(LightningElement) {
    @api listViewApiName;
    @api listTitle;
    @api ownedByRunningUser = false;
    @api numRecords = 10;

    records = [];
    isLoading = false;
    queryFields = [];
    filteredByInfo = [];

    @wire(getListInfoByName, { objectApiName: NAV_TASK_OBJECT.objectApiName, listViewApiName: '$listViewApiName' })
    listInfoCallback({ error, data }) {
        if (data) {
            let columns = [];
            data.displayColumns.forEach((column) => {
                columns.push(column.fieldApiName);
            });
            this.filteredByInfo = data.filteredByInfo;
            this.queryFields = columns;
            if (this.queryFields.length > 0) this.getNavTasks();
        }
        if (error) {
            console.log('List info error: ' + JSON.stringify(error, null, 2));
        }
    }

    connectedCallback() {
        this.isLoading = true;
    }

    handleRefresh() {
        this.isLoading = true;
        this.getNavTasks();
    }

    getNavTasks() {
        getNavTaskRecords({
            fieldsToQuery: this.queryFields,
            filteredByJson: JSON.stringify(this.filteredByInfo),
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

    get tableColumns() {
        let tableCols = [];
        if (this.records.length > 0) {
            this.queryFields.forEach((field) => {
                tableCols.push({ label: field, fieldName: field });
            });
        }
        return tableCols;
    }
}
