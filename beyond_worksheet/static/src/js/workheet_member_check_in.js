/** @odoo-module **/

import publicWidget from "@web/legacy/js/public/public_widget";
import { jsonrpc } from "@web/core/network/rpc_service";
console.log("jsssssssssssssssssson")
publicWidget.registry.MemberPortalSignature = publicWidget.Widget.extend({
    selector: '.member_signature',  // Replace with the class/id of the template element
        events: {
            'click #member_check_in': '_CheckIn',
            'click .upload_member_btn_signature': '_CheckSignature',
        },
//         start: function () {
//        this._super.apply(this, arguments);
////        this._setupSignatureWatcher();
//    },

    _CheckSignature: function () {
        const self = this;
        const worksheetId = $('#worksheet_id').val();
        const surveyId = $('#survey_worksheet').val();
        console.log("inside signatureeeeeeeeeeee")
        // Check signature completion status
        jsonrpc('/my/worksheet/' + worksheetId + '/' + surveyId + '/signature/status', {})
            .then(function (result) {
                if (result.signature_completed) {
                    $('.member_btn_check_in').removeClass('d-none'); // Show success message
                    $('.success_msg_text').removeClass('d-none'); // Enable Check-In button
                    $('.upload_member_btn_signature').addClass('d-none'); // Enable Check-In button
                }
            })
            .catch(function (error) {
                console.error('Error checking signature status:', error);
            });
    },
    async _CheckIn(ev) {
        const worksheetId = $('#worksheet_id').val();
        const surveyId = $('#survey_worksheet').val();
        const memberId = $('#member').val();
        console.log(worksheetId,surveyId,memberId)
        const fallbackUrl = `/team/member/checkin/${surveyId}/${worksheetId}/${memberId}/0/0`;
          if ("geolocation" in navigator) {
                navigator.geolocation.getCurrentPosition(
                    (position) => {
                        const lat = position.coords.latitude;
                        const long = position.coords.longitude;
                        console.log("hhhhhhhhhhhhhh iiiiiiiiiii")
                        window.location.href = `/team/member/checkin/${surveyId}/${worksheetId}/${memberId}/${lat}/${long}`;
//                            $('#checkin_form').attr('action', '/my/questions/' + $('#worksheet_id')[0].value+'/'+ result.member_id + '/' + position.coords.latitude + '/'+ position.coords.longitude);
                    },
                    (error) => {
                        console.error("Error retrieving location:", error);
                    }
                );
            }
            else{
             window.location.href = fallbackUrl;                }
    }
});