import { LightningElement, wire, track, api } from 'lwc';
import crmSingleValueUpdate from '@salesforce/messageChannel/crmSingleValueUpdate__c';
import getTaskTypes from '@salesforce/apex/CRM_NAVTaskTypeController.getTaskTypes';
import { publish, subscribe, unsubscribe, MessageContext } from 'lightning/messageService';

//##LABEL IMPORTS
import TASK_TYPE_REQUIRED_ERROR from '@salesforce/label/c.CRM_NAV_Task_Type_Validation_Error';

const themesWithoutNormalPriority = ['PEN', 'BID', 'OKO'];

export default class NksTaskTypePicklist extends LightningElement {
    labels = {
        TASK_TYPE_REQUIRED_ERROR
    };

    @api showcomponent;
    @api theme;

    @track tasktypes = [];

    @track tasktype;
    commoncodes;
    isSupported = true;
    loaded = false;

    @wire(MessageContext)
    messageContext;

    @api
    get selectedTaskType() {
        let selectedTaskType = '';
        if (this.commoncodes) {
            for (let tt of this.commoncodes) {
                if (tt.id === this.tasktype) {
                    selectedTaskType = tt.commoncode;
                    break;
                }
            }
        }
        return selectedTaskType;
    }

    @api
    get selectedTaskTypeId() {
        return this.tasktype;
    }

    set selectedTaskTypeId(taskId) {
        this.tasktype = taskId;
    }

    get noValidTaskTypes() {
        return this.tasktypes.length === 0;
    }

    handleTaskTypeChange(event) {
        this.tasktype = event.detail.value;
        this.publishFieldChange('tasktype', this.selectedTaskType);
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
        this.findTaskTypes();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(this.messageContext, crmSingleValueUpdate, (message) =>
                this.handleMessage(message)
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(message) {
        let fieldName = message.name;
        let value = message.value;

        switch (fieldName) {
            case 'themeCode':
                this.theme = value;
                this.loaded = false;
                this.handleThemeChange();
                this.findTaskTypes();
                break;
            case 'createtask':
                this.showcomponent = value;
                break;
        }
    }

    async findTaskTypes() {
        const input = {
            themeCode: this.theme
        };
        try {
            getTaskTypes(input).then((result) => {
                this.commoncodes = result;
                let availableTypes = [];
                result.forEach((tasktype) => {
                    const option = {
                        value: tasktype.id,
                        label: tasktype.name
                    };
                    availableTypes.push(option);
                });
                this.tasktypes = availableTypes;

                // if the list of tasktypes changed and the previoursly selected value not in the list
                // reset selected value
                if (this.tasktype) {
                    if (!this.tasktypes.some((e) => e.value === this.tasktype)) {
                        this.tasktype = null;
                    }
                }
                this.loaded = true;
            }, this);
        } catch (error) {
            this.errorMessage = error.body.message;
            this.loaded = true;
        }
    }

    publishFieldChange(field, value) {
        const payload = { name: field, value: value };
        publish(this.messageContext, crmSingleValueUpdate, payload);
    }

    @api
    validate() {
        let valid =
            (this.showcomponent == true && this.selectedTaskType != '') ||
            this.showcomponent == false ||
            !this.showcomponent;
        if (valid) {
            return { ivValid: true };
        } else {
            return {
                isValid: false,
                errorMessage: TASK_TYPE_REQUIRED_ERROR
            };
        }
    }

    handleThemeChange() {
        if (themesWithoutNormalPriority.includes(this.theme)) {
            this.isSupported = false;
        } else {
            this.isSupported = true;
        }
    }
}
