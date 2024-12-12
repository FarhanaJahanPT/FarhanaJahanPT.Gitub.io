/** @odoo-module **/

import publicWidget from "@web/legacy/js/public/public_widget";
import { jsonrpc } from "@web/core/network/rpc_service";
console.log("jsssssssssssssssssson")
publicWidget.registry.MemberPortalSignature = publicWidget.Widget.extend({
    selector: '.member_signature',  // Replace with the class/id of the template element
        events: {
            'click #member_check_in': '_CheckIn',
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