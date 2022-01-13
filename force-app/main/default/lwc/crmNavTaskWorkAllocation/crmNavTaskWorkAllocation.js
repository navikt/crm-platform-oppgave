import { LightningElement, api, track, wire } from 'lwc';
import crmSingleValueUpdate from '@salesforce/messageChannel/crmSingleValueUpdate__c';
import getWorkAllocations from '@salesforce/apex/CRM_NavTaskWorkAllocationController.getWorkAllocations';
import getUserNavUnit from '@salesforce/apex/CRM_NavTaskWorkAllocationController.getUserNavUnit';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/NavUnit__c.Id';
import NAME_FIELD from '@salesforce/schema/NavUnit__c.Name';
import UNIT_NUMBER_FIELD from '@salesforce/schema/NavUnit__c.INT_UnitNumber__c';
import USER_ID from '@salesforce/user/Id';
import USER_NAV_UNIT_FIELD from '@salesforce/schema/User.Department';
import USER_NAV_IDENT_FIELD from '@salesforce/schema/User.CRM_NAV_Ident__c';

import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';

//#### LABEL IMPORTS ####
import VALIDATION_ERROR from '@salesforce/label/c.CRM_Nav_Task_Work_Allocation_Validation_Error';
import DELEGATE_TO_SELF_LABEL from '@salesforce/label/c.CRM_Nav_Task_Work_Allocation_Delegate_to_Self';

export default class NksNavTaskWorkAllocation extends LightningElement {
    labels = {
        VALIDATION_ERROR,
        DELEGATE_TO_SELF_LABEL
    };

    @api personId;
    @api taskType;
    @api themeGroup;
    @api theme;
    @api subTheme;
    @api subType;
    alwaysShow = false;
    @track result;
    isSearching;
    errorMessage;
    selectedLabel;
    selectedId;
    selectedManualSearchId;
    allocationSuggestionList;
    runningUserUnitNumber;
    runningUserIdent;
    delegateToSelf = false;
    @api hideDelegateToSelf = false;

    set disableConditionalRendering(value) {
        if (value && (value === true || value.toLowerCase() === 'true')) {
            this.alwaysShow = true;
        }
    }

    @api
    get disableConditionalRendering() {
        return this.alwaysShow;
    }

    @api
    get selectedUnitName() {
        let value =
            this.selectedLabel === 'delegateSelf'
                ? this.userNavUnit.data.Name
                : this.selectedLabel === 'other'
                ? getFieldValue(this.manualSearchNavUnit.data, NAME_FIELD)
                : getFieldValue(this.navUnit.data, NAME_FIELD);
        return value ? value : '';
    }

    @api
    get selectedUnitId() {
        let value =
            this.selectedLabel === 'delegateSelf'
                ? this.userNavUnit.data.Id
                : this.selectedLabel === 'other'
                ? getFieldValue(this.manualSearchNavUnit.data, ID_FIELD)
                : getFieldValue(this.navUnit.data, ID_FIELD);
        return value ? value : '';
    }

    set selectedUnitId(unitId) {
        this.selectedId = unitId;
    }

    @api
    get selectedUnitNumber() {
        let value =
            this.selectedLabel === 'delegateSelf'
                ? this.userNavUnit.data.INT_UnitNumber__c
                : this.selectedLabel === 'other'
                ? getFieldValue(this.manualSearchNavUnit.data, UNIT_NUMBER_FIELD)
                : getFieldValue(this.navUnit.data, UNIT_NUMBER_FIELD);
        return value ? value : '';
    }

    @api
    get assignedResource() {
        return this.delegateToSelf === true ? this.runningUserIdent : null;
    }

    get navUnitInputDisabled() {
        return this.isSearching || this.delegateToSelf === true;
    }

    get canSearch() {
        return this.showContent && null != this.theme && null != this.taskType && this.delegateToSelf === false;
    }

    get isUnavailable() {
        return this.isSearching || this.isSearching == null || this.theme == null || this.taskType == null;
    }

    get navUnits() {
        let temp = [];
        if (this.allocationSuggestionList && this.allocationSuggestionList.length > 0) {
            temp = this.allocationSuggestionList.map((navUnit) => {
                return { label: navUnit.Name + ' (' + navUnit.INT_UnitNumber__c + ')', value: navUnit.Id };
            });
        }
        if (!this.hideDelegateToSelf) {
            temp.push({ label: 'Send til meg', value: 'delegateSelf' });
        }
        temp.push({ label: 'Annen:', value: 'other' });
        return temp;
    }

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, {
        recordId: '$selectedId',
        fields: [ID_FIELD, NAME_FIELD, UNIT_NUMBER_FIELD]
    })
    navUnit;

    @wire(getRecord, {
        recordId: '$selectedManualSearchId',
        fields: [ID_FIELD, NAME_FIELD, UNIT_NUMBER_FIELD]
    })
    manualSearchNavUnit;

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [USER_NAV_UNIT_FIELD, USER_NAV_IDENT_FIELD]
    })
    wireUser({ error, data }) {
        if (data) {
            this.runningUserIdent = data.fields.CRM_NAV_Ident__c.value;
            this.runningUserUnitNumber = data.fields.Department.value;
        }
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
        if (this.canSearch) {
            this.findAllocation();
        }
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    get showContent() {
        return null != this.personId && ((null != this.theme && null != this.taskType) || this.alwaysShow === true);
    }

    get required() {
        return this.selectedLabel === 'other' || this.selectedLabel === 'delegateSelf';
    }

    //Lightning message service subscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(this.messageContext, crmSingleValueUpdate, (message) =>
                this.handleMessage(message)
            );
        }
    }

    //Lightning message service unsubsubscribe
    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    // Handler for message received by component
    handleMessage(message) {
        let fieldName = message.name;
        let value = message.value ? message.value : null;

        switch (fieldName) {
            case 'themeGroupCode':
                this.allocationSuggestionList = null;
                this.themeGroup = null;
                this.theme = null;
                this.subTheme = null;
                this.subType = null;
                break;
            case 'themeCode':
                this.theme = value;
                this.subTheme = null;
                this.subType = null;
                break;
            case 'subThemeCode':
                this.subTheme = value;
                break;
            case 'subTypeCode':
                this.subType = value;
                break;
            case 'tasktype':
                this.taskType = value;
                break;
        }

        if (this.canSearch) {
            this.findAllocation();
        }
    }

    //Send query to NORG2
    async findAllocation() {
        this.isSearching = true;
        const input = {
            personId: this.personId,
            themeGroupCode: this.themeGroup,
            themeCode: this.theme,
            themeSubThemeCode: this.subTheme,
            themeSubTypeCode: this.subType,
            taskType: this.taskType
        };
        try {
            const data = await getWorkAllocations(input);
            if (data && 1 <= data.length) {
                this.selectedId = this.selectedLabel = data[0].Id;
                this.allocationSuggestionList = data;
            }
            this.isSearching = false;
        } catch (error) {
            this.errorMessage = error.body.message;
            this.isSearching = false;
        }
    }

    @wire(getUserNavUnit, { userUnitNumber: '$runningUserUnitNumber' })
    userNavUnit;

    onChange(event) {
        let ids = event.detail.value;
        this.delegateToSelf = ids === 'delegateSelf';
        this.selectedLabel = ids;
        this.selectedId = this.delegateToSelf
            ? this.userNavUnit.data.Id
            : ids === 'other'
            ? this.selectedManualSearchId
            : ids
            ? ids
            : null;
    }

    onManualSearchChange(event) {
        let ids = event.detail.value;
        this.delegateToSelf = false;
        if (ids && ids.length === 1) {
            this.selectedLabel = 'other';
            this.selectedManualSearchId = ids[0];
        } else {
            this.selectedManualSearchId = null;
        }
    }

    @api
    validate() {
        //Theme and theme group must be set
        // return { isValid: true };
        if (
            !this.required ||
            (this.selectedLabel === 'other' && this.selectedManualSearchId && this.navUnit) ||
            (this.selectedLabel === 'delegateSelf' && this.selectedId && this.userNavUnit)
        ) {
            return { isValid: true };
        } else {
            return {
                isValid: false,
                errorMessage: VALIDATION_ERROR
            };
        }
    }
}
