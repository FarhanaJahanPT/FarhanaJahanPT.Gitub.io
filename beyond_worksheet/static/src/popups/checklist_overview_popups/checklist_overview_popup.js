/** @odoo-module */
import {Dialog} from "@web/core/dialog/dialog";
import {useService} from "@web/core/utils/hooks";
const {useState, onWillStart, Component, useRef, onMounted, useEffect} = owl;
import {_t} from "@web/core/l10n/translation";
import { UpdateChecklistOverviewPopup } from "../update_checklist_overview_popups/update_checklist_overview_popups"

export class ChecklistOverviewPopup extends Component{

    setup(){
        this.dialogService = useService("dialog");
        console.log('qqqqqqqqqqqqqqqqqqqqqqqqq',this)
    }
    uploadImg(){
        console.log("upload")
        const props = this.props
        this.dialogService.add(UpdateChecklistOverviewPopup,props);
    }
    onClose(){
        this.props.close();
    }
}
ChecklistOverviewPopup.template = "ChecklistOverviewPopup";
ChecklistOverviewPopup.components = {Dialog};