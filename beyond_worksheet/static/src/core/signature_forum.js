/** @odoo-module **/
import { registry } from "@web/core/registry";
import { patch } from "@web/core/utils/patch";
import dom from "@web/legacy/js/core/dom";
import { redirect } from "@web/core/utils/urls";


patch(registry.category("public_components").get("portal.signature_form").prototype,{
    async onClickSubmit() {
        const button = document.querySelector('.o_portal_sign_submit')
        const icon = button.removeChild(button.firstChild)
        const restoreBtnLoading = dom.addButtonLoadingEffect(button);

        const name = this.signature.name;
        const signature = this.signature.getSignatureImage()[1];
        const data = await this.rpc(this.props.callUrl, { name, signature });
        if (data.force_refresh) {
            restoreBtnLoading();
            button.prepend(icon)
            if (data.is_worksheet){
                if ("geolocation" in navigator) {
                    navigator.geolocation.getCurrentPosition(
                        (position) => {
                            const lat = position.coords.latitude;
                            const long = position.coords.longitude;
                            const checkin_url = `/team/member/checkin/${data.survey_id}/${data.worksheet_id}/${data.member_id}/${lat}/${long}`;
                            redirect(checkin_url);
                        },
                        (error) => {
                            console.error("Error retrieving location:", error);
                        }
                    );
                }
            }
            else if (data.redirect_url) {
                redirect(data.redirect_url);
            } else {
                window.location.reload();
            }
            // do not resolve if we reload the page
            return new Promise(() => {});
        }
        this.state.error = data.error || false;
        this.state.success = !data.error && {
            message: data.message,
            redirectUrl: data.redirect_url,
            redirectMessage: data.redirect_message,
        };
    }

})
