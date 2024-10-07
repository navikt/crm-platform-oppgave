import { LightningElement, api, wire } from 'lwc';
import hurtigtekster from '@salesforce/resourceUrl/NKS_NavTaskCommunalQuickText';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import crmSingleValueUpdate from '@salesforce/messageChannel/crmSingleValueUpdate__c';
import addBusinessDays from '@salesforce/apex/CRM_DueDateUtility.addBusinessDays';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';

const communalTheme = 'KOM';

export default class CrmNavTaskQuickText extends LightningElement {
    @api selectedValue;

    selectedValueLabel;
    isCommunalTheme = false;

    options = [];
    items = [];

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscribeToMessageChannel();
        if (this.items.length === 0) {
            fetch(hurtigtekster)
                .then((response) => response.json())
                .then((data) => {
                    this.items = data;
                    this.options = this.items.map((item) => {
                        return { label: item.name, value: item.hurtigtekst, hasVirkedager: item.hasVirkedager };
                    });
                })
                .catch((error) => {
                    console.error('Error loading quick text from static resource', error);
                });
        }
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
        if (message.name == 'themeCode') {
            this.isCommunalTheme = message.value == communalTheme ? true : false;
        }
    }

    handleChange(event) {
        const selectedOption = this.options.find((opt) => opt.value === event.detail.value);
        this.displayedValue = selectedOption.label;
        this.selectedValue = selectedOption.value;
        if (selectedOption?.hasVirkedager) {
            this.calculateAndReplaceBusinessDate(2);
        } else {
            this.dispatchAttributeChange();
        }
    }

    calculateAndReplaceBusinessDate(numberOfBusinessDays) {
        addBusinessDays({ numberofBusinessdays: numberOfBusinessDays })
            .then((result) => {
                const dateFromString = new Date(result);
                let formattedDate = dateFromString.toLocaleDateString('no-NO', {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit'
                });
                this.selectedValue = this.selectedValue.replace('{TO_VIRKEDAGER_FRA_DAGENS_DATO}', formattedDate);
                this.dispatchAttributeChange();
            })
            .catch((error) => {
                console.error('Error calculating business date:', error);
            });
    }

    dispatchAttributeChange() {
        const attributeChangeEvent = new FlowAttributeChangeEvent('selectedValue', this.selectedValue);
        this.dispatchEvent(attributeChangeEvent);
    }
}
