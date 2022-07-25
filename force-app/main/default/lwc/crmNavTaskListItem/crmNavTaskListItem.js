import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class CrmNavTaskListItem extends NavigationMixin(LightningElement) {
    @api navTaskRecord;
    @api displayFields;

    dataFields = [];
    connectedCallback() {
        let fields = [];

        this.displayFields.forEach((field) => {
            fields.push({
                fieldName: field,
                fieldValue: this.resolve(field, this.navTaskRecord),
                isRelationshipField: this.isRelationshipField(field)
            });
        });

        this.dataFields = fields;
    }

    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

    isRelationshipField(fieldPath) {
        return fieldPath.includes('__r');
    }

    get recordId() {
        return this.navTaskRecord ? this.navTaskRecord.Id : null;
    }

    get columnSize() {
        return this.dataFields.length > 0 ? Math.floor(12 / this.dataFields.length) : 12;
    }

    /**
     * Retrieves the value from the given object's data path
     * @param {data path} path
     * @param {JS object} obj
     */
    resolve(path, obj) {
        return path.split('.').reduce(function (prev, curr) {
            return prev ? prev[curr] : null;
        }, obj || self);
    }
}
