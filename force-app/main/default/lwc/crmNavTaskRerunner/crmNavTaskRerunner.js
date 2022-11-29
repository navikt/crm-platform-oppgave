import { LightningElement, track } from 'lwc';
import validateFilter from '@salesforce/apex/CRM_NavTaskRerunCtrl.validateQuery';
import checkRunningJobs from '@salesforce/apex/CRM_NavTaskRerunCtrl.getRunningProcess';
import getJobDetails from '@salesforce/apex/CRM_NavTaskRerunCtrl.getJobInfo';
import queryThemes from '@salesforce/apex/CRM_NavTaskRerunCtrl.getThemes';
import queryTaskTypes from '@salesforce/apex/CRM_NavTaskRerunCtrl.getTaskTypes';
import startJob from '@salesforce/apex/CRM_NavTaskRerunCtrl.initRerun';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CrmNavTaskRerunner extends LightningElement {
    isLoading = false;
    filterError;
    filterRecordCount;

    runningJob;
    themes = [];
    taskTypes = [];

    @track taskTypeFilters = [];
    @track themeFilters = [];

    connectedCallback() {
        this.getThemesFromApex();
        this.getTaskTypesFromApex();
        this.getRunningJob();
    }

    getThemesFromApex() {
        queryThemes({})
            .then((themes) => {
                let retThemes = [];
                themes.forEach((theme) => {
                    retThemes.push({ label: theme.Name, value: theme.CRM_Code__c });
                });
                this.themes = retThemes;
            })
            .catch((error) => {
                console.error(JSON.stringify(error, null, 2));
            });
    }

    getTaskTypesFromApex() {
        queryTaskTypes({})
            .then((taskTypes) => {
                let retTypes = [];
                taskTypes.forEach((taskType) => {
                    retTypes.push({ label: taskType.Name, value: taskType.CRM_Code__c });
                });
                this.taskTypes = retTypes;
            })
            .catch((error) => {
                console.error(JSON.stringify(error, null, 2));
            });
    }

    getRunningJob() {
        this.isLoading = true;
        checkRunningJobs({})
            .then((job) => {
                this.runningJob = job; //returns null if no active job is found
            })
            .catch((error) => {
                console.log('Error: ' + JSON.stringify(error, null, 2));
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Test that the input filter is valid and that the SOQL will not throw any errors;
     */
    testFilter() {
        if (this.metFilterRequirements() === false) {
            return;
        }
        this.invalidateFilter();
        this.isLoading = true;
        validateFilter({ queryFilter: this.queryFilter })
            .then((recordCount) => {
                this.filterRecordCount = recordCount;
            })
            .catch((error) => {
                this.filterError = error.body.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    metFilterRequirements() {
        if (this.taskTypeFilters.length > 0) {
            return true;
        } else {
            this.filterError = 'Choose at least one task type filter';
            return false;
        }
    }

    initiateRerun() {
        startJob({ queryFilter: this.queryFilter })
            .then((out) => {
                this.getRunningJob();
                this.invalidateFilter();
            })
            .catch((error) => {
                const event = new ShowToastEvent({
                    title: 'Job error',
                    variant: 'error',
                    message: 'Error submitting job: ' + error.body.message
                });
                this.dispatchEvent(event);
            });
    }

    refreshRunningJob(event) {
        this.isLoading = true;
        getJobDetails({ jobId: this.runningJob.Id })
            .then((job) => {
                this.runningJob = job;
            })
            .catch((error) => {
                console.log('Error getting job info: ' + JSON.stringify(error, null, 2));
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    invalidateFilter() {
        this.filterError = null;
        this.filterRecordCount = undefined;
    }

    handleThemeFilterRemove(event) {
        const index = event.detail.index;
        this.themeFilters.splice(index, 1);
        this.invalidateFilter();
    }

    handleTaskTypeFilterRemove(event) {
        const index = event.detail.index;
        this.taskTypeFilters.splice(index, 1);
        this.invalidateFilter();
    }

    handleFilterAdd(event) {
        const filterName = event.target.name;
        const filterValue = event.detail.value;
        const filterLabel = event.target.options.find((opt) => opt.value === filterValue).label;

        if (filterName === 'themeFilterInput') {
            this.themeFilters.push({ label: filterLabel, value: filterValue });
        } else if (filterName === 'taskTypeFilterInput') {
            this.taskTypeFilters.push({ label: filterLabel, value: filterValue });
        }

        event.target.value = '';
        this.invalidateFilter();
    }

    get buttonVariant() {
        return this.isValid ? 'success' : 'neutral';
    }

    get notValid() {
        return !this.isValid;
    }

    get isValid() {
        return this.filterRecordCount >= 0;
    }

    get queryFilter() {
        let filter = 'INT_External_Reference__c = null';
        filter += ' ' + this.taskTypeFilterSoql;
        filter += ' ' + this.themeFilterSoql;
        filter += ' ' + this.timeframeSoql;

        return filter;
    }

    get themeFilterSoql() {
        let filter = '';
        if (this.hasThemeFilters) {
            filter += ' AND NKS_Theme__r.CRM_Code__c IN (';
            this.themeFilters.forEach((themeFilter) => {
                filter += "'" + themeFilter.value + "',";
            });
            filter = filter.slice(0, filter.length - 1);
            filter += ')';
        }
        return filter;
    }

    get taskTypeFilterSoql() {
        let filter = '';
        if (this.hasTaskTypeFilters) {
            filter += 'AND NKS_TaskType__r.CRM_Code__c IN (';
            this.taskTypeFilters.forEach((taskTypeFilter) => {
                filter += "'" + taskTypeFilter.value + "',";
            });
            filter = filter.slice(0, filter.length - 1);
            filter += ')';
        }

        return filter;
    }

    get timeframeSoql() {
        return 'AND CreatedDate = LAST_N_DAYS:' + this.template.querySelector('lightning-input')?.value;
    }

    get hasTaskTypeFilters() {
        return this.taskTypeFilters.length > 0;
    }

    get hasThemeFilters() {
        return this.themeFilters.length > 0;
    }
}
