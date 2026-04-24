import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USER_NAV_IDENT_FIELD from '@salesforce/schema/User.CRM_NAV_Ident__c';
import getAllAssignedOpenOppgaver from '@salesforce/apex/OppgaveManager.getAllAssignedOpenOppgaver';
import getPersonInfo from '@salesforce/apex/OppgaveManager.getPersonInfo';

const DATE_FORMAT = { day: '2-digit', month: '2-digit', year: 'numeric' };

// TODO: Add this component to Home page

export default class CrmOppgaveListHome extends NavigationMixin(LightningElement) {
    oppgaver = [];
    personData = {};
    isRefreshDisabled = false;
    isLoading = false;
    navIdent = '1234'; // TODO: Harcoded value to match test data in Mock. Remove hardcoded value once connected to real user data.

    @wire(getRecord, { recordId: USER_ID, fields: [USER_NAV_IDENT_FIELD] })
    wiredUser({ data, error }) {
        if (data) {
            this.navIdent = getFieldValue(data, USER_NAV_IDENT_FIELD) ?? this.navIdent;
            console.log('Fetched user navIdent:', this.navIdent);
            this.loadOppgaver();
        } else if (error) {
            console.error('Error fetching user:', error);
        }
    }

    async loadOppgaver() {
        if (!this.navIdent) return;
        this.isLoading = true;
        try {
            this.oppgaver = ((await getAllAssignedOpenOppgaver({ navIdent: this.navIdent })) ?? [])
                .filter((oppgave) => oppgave.id != null)
                .sort((a, b) => {
                    if (!a.fristFerdigstillelse) return 1;
                    if (!b.fristFerdigstillelse) return -1;
                    return new Date(a.fristFerdigstillelse) - new Date(b.fristFerdigstillelse);
                })
                .slice(0, 10)
                .map((oppgave) => ({
                    ...oppgave,
                    fristFormatted: oppgave.fristFerdigstillelse
                        ? new Date(oppgave.fristFerdigstillelse).toLocaleDateString('nb-NO', DATE_FORMAT)
                        : '',
                    brukerIdent:
                        oppgave.bruker?.type === 'PERSON' ? oppgave.bruker.ident : (oppgave.personIdent ?? null)
                }));

            const personIdents = [...new Set(this.oppgaver.map((t) => t.brukerIdent).filter(Boolean))];
            this.personData = await getPersonInfo({ personIdents });
        } catch (error) {
            console.error('Error fetching oppgaver:', error);
        } finally {
            this.isLoading = false;
        }
    }

    handleRefresh() {
        if (this.isLoading || this.isRefreshDisabled) return;
        this.isRefreshDisabled = true;

        this.loadOppgaver();

        setTimeout(() => {
            // 10 sec delay to avoid spamming requests
            this.isRefreshDisabled = false;
        }, 10000);
    }

    handleNavigateToOppgave(event) {
        const oppgaveId = event.currentTarget.dataset.id;
        const oppgavetype = event.currentTarget.dataset.oppgavetype;
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__crmOppgaveNavigation'
            },
            state: {
                c__oppgaveId: oppgaveId,
                c__oppgavetype: oppgavetype
            }
        });
    }

    navigateToOppgaveTable() {
        // TODO: Legg inn navigering til tabellen som JR lager.
    }

    get hasOppgaver() {
        return this.oppgaver.length > 0;
    }

    get emptyState() {
        return !this.hasOppgaver && !this.isLoading;
    }

    get oppgaverWithPersonData() {
        return this.oppgaver.map((oppgave) => {
            const fullName = this.personData[oppgave.brukerIdent]?.CRM_FullName__c ?? oppgave.brukerIdent;
            const age = this.personData[oppgave.brukerIdent]?.CRM_Age__c;
            return {
                ...oppgave,
                personNameAndAge: age ? `${fullName} (${age} år)` : fullName
            };
        });
    }
}
