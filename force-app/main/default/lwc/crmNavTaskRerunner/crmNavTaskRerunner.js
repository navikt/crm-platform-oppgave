import { LightningElement } from 'lwc';
import validateFilter from '@salesforce/apex/CRM_NavTaskRerunCtrl.validateQuery';
import checkRunningJobs from '@salesforce/apex/CRM_NavTaskRerunCtrl.getRunningProcess';
import getJobDetails from '@salesforce/apex/CRM_NavTaskRerunCtrl.getJobInfo';
import startJob from '@salesforce/apex/CRM_NavTaskRerunCtrl.initRerun';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CrmNavTaskRerunner extends LightningElement {
    queryFilter = 'INT_External_Reference__c = null';
    isLoading = false;
    filterError;
    filterRecordCount;

    runningJob;

    connectedCallback() {
        this.getRunningJob();
    }

    getRunningJob(jobId) {
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
        this.filterError = null;
        this.filterRecordCount = undefined;
        this.isLoading = true;
        validateFilter({ queryFilter: this.queryFilter })
            .then((recordCount) => {
                this.filterRecordCount = recordCount;
                this.textArea.setCustomValidity('');
                this.textArea.reportValidity();
            })
            .catch((error) => {
                this.filterError = error.body.message;
                this.textArea.setCustomValidity(error.body.message);
                this.textArea.reportValidity();
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    initiateRerun() {
        startJob({ queryFilter: this.queryFilter })
            .then((out) => {
                this.getRunningJob();
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

    filterChange(event) {
        this.queryFilter = event.detail.value;
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

    get textArea() {
        return this.template.querySelector('lightning-textarea');
    }
}
