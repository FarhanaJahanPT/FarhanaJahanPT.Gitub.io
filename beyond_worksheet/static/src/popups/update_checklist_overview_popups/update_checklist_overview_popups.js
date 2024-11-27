/** @odoo-module */
import {Dialog} from "@web/core/dialog/dialog";
//import {useService} from "@web/core/utils/hooks";
const {useState, onWillStart, Component, useRef, onMounted, useEffect} = owl;
import {_t} from "@web/core/l10n/translation";

export class UpdateChecklistOverviewPopup extends Component{

    setup(){
        console.log('qqqqqqqqqqqqqqqqqqqqqqqqq',this)
        this.state = useState({
            imagePreview: null, // For previewing the uploaded image
        });
    }
    uploadImg(){
        console.log("upload")
//        this.dialogService.add(ChecklistOverviewPopup,props);
    }
    onFileChange(ev) {
        const file = ev.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (event) => {
                this.state.imagePreview = event.target.result; // Set image preview
            };
            reader.readAsDataURL(file);
        }
    }

    async onUpload() {
    navigator.geolocation.getCurrentPosition(
        (position) => {
            console.log("Latitude:", position.coords.latitude);
            console.log("Longitude:", position.coords.longitude);
        },
        (error) => {
            console.error("Error getting location:", error.message);
        }
        );
//        if (this.state.imagePreview) {
//            await this.orm.call("your.model", "create", {
//                // Assuming 'id' is passed in props
//                id: this.props.id,navigator.geolocation
//                image: this.state.imagePreview.split(",")[1], // Base64-encoded image
//            });
//            this.onClose(); // Close dialog after upload
//        } else {
//            this.notification.add("Please select an image to upload", {
//                type: "warning",
//            });
//        }
    }
    onClose(){
        this.props.close();
    }

}
UpdateChecklistOverviewPopup.template = "UpdateChecklistOverviewPopup";
UpdateChecklistOverviewPopup.components = {Dialog};