/** @odoo-module */
import {Dialog} from "@web/core/dialog/dialog";
import {useService} from "@web/core/utils/hooks";
const {useState, onWillStart, Component, useRef, onMounted, useEffect} = owl;
import {_t} from "@web/core/l10n/translation";
import { UpdateChecklistOverviewPopup } from "../update_checklist_overview_popups/update_checklist_overview_popups"

export class ChecklistOverviewPopup extends Component{

    setup(){
        this.dialogService = useService("dialog");
    }
    uploadImg(){
        const props = this.props
        this.dialogService.add(UpdateChecklistOverviewPopup,props);
    }
    onClose(){
        this.props.close();
    }
    onImagePreview(imageData){
        const modal = document.getElementById("imagePreviewModal");
        const previewImage = document.getElementById("previewedImage");
        if (previewImage){
            previewImage.src = `data:image/png;base64,${imageData}`;
        }
        if (modal){
            modal.classList.add("show");
        }
    }
    onClosePreview() {
        const modal = document.getElementById("imagePreviewModal");
        if (modal){
            modal.classList.remove("show");
        }
    }
}
ChecklistOverviewPopup.template = "ChecklistOverviewPopup";
ChecklistOverviewPopup.components = {Dialog};