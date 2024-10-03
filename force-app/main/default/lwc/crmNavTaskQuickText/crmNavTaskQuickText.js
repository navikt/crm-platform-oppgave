import { LightningElement, api } from 'lwc';
import hurtigtekster from '@salesforce/resourceUrl/NKS_NavTaskQuickText';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import addBusinessDays from '@salesforce/apex/CRM_DueDateUtility.addBusinessDays';

export default class CrmNavTaskQuickText extends LightningElement {
    @api selectedValue;
    selectedValueLabel;

    options = [];
    items = [];

    connectedCallback() {
        if (this.items.length === 0) {
            fetch(hurtigtekster)
                .then((response) => response.json())
                .then((data) => {
                    this.items = data;
                    this.options = this.items.map((item) => {
                        return { label: item.name, value: item.hurtigtekst };
                    });
                })
                .catch((error) => {
                    console.error('Error loading quick text from static resource', error);
                });
        }
    }

    handleChange(event) {
        const selectedOption = this.options.find((opt) => opt.value === event.detail.value);
        this.displayedValue = selectedOption.label;
        this.selectedValue = selectedOption.value;
        if (this.selectedValue?.includes('{TO_VIRKEDAGER_FRA_DAGENS_DATO}')) {
            this.calculateAndReplaceBusinessDate(2);
        } else {
            this.dispatchAttributeChange();
        }
    }

    calculateAndReplaceBusinessDate(numberOfBusinessDays) {
        addBusinessDays({ numberofBusinessdays: numberOfBusinessDays })
            .then((result) => {
                let formattedDate = this.formatDateDDMMYYYY(new Date(result));
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

    formatDateDDMMYYYY(date) {
        let day = String(date.getDate()).padStart(2, '0');
        let month = String(date.getMonth() + 1).padStart(2, '0');
        let year = date.getFullYear();

        return `${day}.${month}.${year}`;
    }
}
