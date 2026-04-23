import { LightningElement } from 'lwc';

export default class CrmExpandablePanel extends LightningElement {
    isExpanded = false;

    toggleExpand() {
        this.isExpanded = !this.isExpanded;
    }

    handleKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.toggleExpand();
        }
    }

    get panelHeaderStyle() {
        return 'panel-header-custom panel-header-expandable';
    }

    get chevronClass() {
        return (
            'slds-icon slds-icon-text-default slds-icon_small custom-chevron' +
            (this.isExpanded ? ' rotate-chevron' : '')
        );
    }
}
