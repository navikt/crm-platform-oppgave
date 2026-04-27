import { LightningElement, api, wire } from 'lwc';
import getCategorization from '@salesforce/apex/CRM_ThemeUtils.getCategorizationByThemeSet';

export default class CrmOppgaveThemeCategorization extends LightningElement {
    @api disabled = false;

    themeSet = 'ARCHIVE_THEMES';

    gjelderMap;
    themeMap;
    chosenTheme;
    chosenGjelder;
    chosenSubtheme;
    chosenSubtype;
    gjelderList;
    themes;

    @wire(getCategorization, { themeSet: '$themeSet' })
    categoryResults({ data, error }) {
        if (data) {
            this.themeMap = data.themeMap;
            this.gjelderMap = data.gjelderMap;
            this.filterThemes();
            if (this.chosenTheme) {
                this.filterGjelder();
                if (this.chosenSubtheme || this.chosenSubtype) {
                    this.chosenGjelder = '';
                    const validGjelder =
                        this.gjelderMap && Object.prototype.hasOwnProperty.call(this.gjelderMap, this.theme)
                            ? this.gjelderMap[this.theme]
                            : [];
                    for (let gjelder of validGjelder) {
                        if (
                            (this.chosenSubtheme == null || gjelder.CRM_Subtheme__c === this.chosenSubtheme) &&
                            (this.chosenSubtype == null || gjelder.CRM_Subtype__c === this.chosenSubtype)
                        ) {
                            this.chosenGjelder = gjelder.Id;
                            break;
                        }
                    }
                }
            }
        } else if (error) {
            console.error('Problem on getCategorization(): ', JSON.stringify(error, null, 2));
        }
    }

    // #### EVENT HANDLERS ####
    handleThemeChange(event) {
        this.chosenTheme = event.detail.value;
        this.chosenGjelder = null;
        this.chosenSubtheme = null;
        this.chosenSubtype = null;
        this.filterGjelder();
        this.dispatchEvent(new CustomEvent('change'));
    }

    handleGjelderChange(event) {
        this.chosenGjelder = event.detail.value;
        this.chosenSubtheme = this.subthemeId;
        this.chosenSubtype = this.subtypeId;
        this.dispatchEvent(new CustomEvent('change'));
    }

    // #### PRIVATE FUNCTIONS ####
    filterThemes() {
        let returnThemes = [{ label: '(Ikke valgt)', value: '' }];
        let listThemes = [];
        if (this.themeMap) {
            // eslint-disable-next-line @salesforce/aura/ecma-intrinsics
            Object.values(this.themeMap).forEach((values) => {
                listThemes = [...listThemes, ...values];
            });
        }
        listThemes
            .filter((theme) => theme.CRM_Available__c)
            .forEach((theme) => {
                returnThemes.push({ label: theme.Name, value: theme.Id });
            });
        this.themes = returnThemes.sort((a, b) => a.label.localeCompare(b.label, 'nb'));
    }

    filterGjelder() {
        const listGjelder =
            this.chosenTheme && this.gjelderMap && this.chosenTheme in this.gjelderMap
                ? this.gjelderMap[this.chosenTheme]
                : [];
        const returnGjelder = listGjelder.length !== 0 ? [{ label: '(Ikke valgt)', value: '' }] : [];
        listGjelder.forEach((gjelder) => {
            returnGjelder.push({ label: gjelder.CRM_Display_Name__c, value: gjelder.Id });
        });
        this.gjelderList = returnGjelder;
    }

    // #### GETTERS / SETTERS ####
    @api
    get theme() {
        return this.chosenTheme;
    }
    set theme(themeValue) {
        this.chosenTheme = themeValue;
    }

    @api
    get themeCode() {
        let themes = [];
        if (this.themeMap) {
            // eslint-disable-next-line @salesforce/aura/ecma-intrinsics
            Object.values(this.themeMap).forEach((values) => {
                themes = [...themes, ...values];
            });
        }
        return themes.find((t) => t.Id === this.theme)?.CRM_Code__c ?? '';
    }

    @api
    get subthemeCode() {
        if (!this.chosenGjelder) return '';
        const validGjelder =
            this.theme && this.gjelderMap && Object.prototype.hasOwnProperty.call(this.gjelderMap, this.theme)
                ? this.gjelderMap[this.theme]
                : [];
        return validGjelder.find((g) => g.Id === this.chosenGjelder)?.CRM_Subtheme_Code__c ?? '';
    }

    @api
    get subtypeCode() {
        if (!this.chosenGjelder) return '';
        const validGjelder =
            this.theme && this.gjelderMap && Object.prototype.hasOwnProperty.call(this.gjelderMap, this.theme)
                ? this.gjelderMap[this.theme]
                : [];
        return validGjelder.find((g) => g.Id === this.chosenGjelder)?.CRM_Subtype_Code__c ?? '';
    }

    get subthemeId() {
        if (!this.chosenGjelder) return '';
        const validGjelder =
            this.theme && this.gjelderMap && Object.prototype.hasOwnProperty.call(this.gjelderMap, this.theme)
                ? this.gjelderMap[this.theme]
                : [];
        return validGjelder.find((g) => g.Id === this.chosenGjelder)?.CRM_Subtheme__c ?? '';
    }

    get subtypeId() {
        if (!this.chosenGjelder) return '';
        const validGjelder =
            this.theme && this.gjelderMap && Object.prototype.hasOwnProperty.call(this.gjelderMap, this.theme)
                ? this.gjelderMap[this.theme]
                : [];
        return validGjelder.find((g) => g.Id === this.chosenGjelder)?.CRM_Subtype__c ?? '';
    }

    get gjelderPlaceholder() {
        if (this.chosenTheme && this.gjelderMap) {
            return this.chosenTheme in this.gjelderMap ? '(Ikke valgt)' : '(Ingen undertema)';
        }
        return '(Ikke valgt)';
    }

    get gjelderDisabled() {
        return this.disabled || !this.chosenTheme || !this.gjelderMap || !(this.chosenTheme in this.gjelderMap);
    }

    get gjelderLabel() {
        return 'Gjelder';
    }
}
