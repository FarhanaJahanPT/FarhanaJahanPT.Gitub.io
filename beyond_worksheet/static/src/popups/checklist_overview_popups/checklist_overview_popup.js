/** @odoo-module */
import {Dialog} from "@web/core/dialog/dialog";
import {useService} from "@web/core/utils/hooks";
const {useState, onWillStart, Component, useRef, onMounted, useEffect} = owl;
import {_t} from "@web/core/l10n/translation";

export class ChecklistOverviewPopup extends Component{

    setup(){

    }
    uploadImg(){
        console.log("upload")
    }
    onClose(){
        this.props.close();
    }

}
ChecklistOverviewPopup.template = "ChecklistOverviewPopup";
ChecklistOverviewPopup.components = {Dialog};