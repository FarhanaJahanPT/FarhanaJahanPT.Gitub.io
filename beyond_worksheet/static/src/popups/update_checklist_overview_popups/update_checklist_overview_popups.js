/** @odoo-module */
import {Dialog} from "@web/core/dialog/dialog";
import {useService} from "@web/core/utils/hooks";
const {useState, onWillStart, Component, useRef, onMounted, useEffect} = owl;
import {_t} from "@web/core/l10n/translation";
import { session } from "@web/session";

export class UpdateChecklistOverviewPopup extends Component{

    setup(){
        this.orm = useService("orm");
        this.notification = useService("notification");
        this.state = useState({
            imagePreview: null, // For previewing the uploaded image
        });
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
        if ("geolocation" in navigator) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.state.latitude = position.coords.latitude;
                    this.state.longitude = position.coords.longitude;
                },
                (error) => {
                    console.error("Error getting location:", error.message);
                }
            );
        } else {
            console.error("Geolocation is not supported by this browser.");
        }
        if (this.state.imagePreview) {
            if(this.props.type =='installation'){
                await this.orm.call("installation.checklist.item", "create",[{
                    checklist_id: this.props.id,
                    worksheet_id: this.props.worksheet_id,
                    user_id: session.uid,
                    latitude: this.state.latitude,
                    longitude: this.state.longitude,
                    location: 'No location Provided',
                    image: this.state.imagePreview.split(",")[1], // Base64-encoded image
                }]);
            }else{
                await this.orm.call("service.checklist.item", "create",[{
                    service_id: this.props.id,
                    worksheet_id: this.props.worksheet_id,
                    user_id: session.uid,
                    latitude: this.state.latitude,
                    longitude: this.state.longitude,
                    location: 'No location Provided',
                    image: this.state.imagePreview.split(",")[1], // Base64-encoded image
                }]);
            }
            this.onClose(); // Close dialog after upload
        } else {
            this.notification.add("Please select an image to upload", {
                type: "warning",
            });
        }
    }
    onClose(){
        this.props.close();
    }
}
UpdateChecklistOverviewPopup.template = "UpdateChecklistOverviewPopup";
UpdateChecklistOverviewPopup.components = {Dialog};
