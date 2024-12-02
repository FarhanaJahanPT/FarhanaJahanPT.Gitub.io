/** @odoo-module **/
import publicWidget from "@web/legacy/js/public/public_widget";
import { jsonrpc } from "@web/core/network/rpc_service";

publicWidget.registry.MemberPortal = publicWidget.Widget.extend({
    selector: '.member_portal',  // Replace with the class/id of the template element
        start: function () {
            this._super.apply(this, arguments);
            $('#submit_button').prop('disabled', true);
        },
        events: {
            'keyup #unique_member_id': '_onChangeMember',
        },
        async _onChangeMember(ev) {
            var result = await jsonrpc('/check/member',  {
                        'member_id' :ev.target.value
                        })
            if(result.exists == false){
                $('#validation_message').text('Invalid Employee ID.');
                $('#member').val(false);
                $('#submit_button').prop('disabled', true);
            }
            else{
                if ("geolocation" in navigator) {
                    navigator.geolocation.getCurrentPosition(
                        (position) => {
                            $('#checkin_form').attr('action', '/my/questions/' + $('#worksheet_id')[0].value+'/'+ result.member_id + '/' + position.coords.latitude + '/'+ position.coords.longitude);
                        },
                        (error) => {
                            console.error("Error retrieving location:", error);
                        }
                    );
                }
                else{
                    $('#checkin_form').attr('action', '/my/questions/' + $('#worksheet_id')[0].value+'/'+ result.member_id + '/' + 0 + '/'+ 0);
                }
                $('#validation_message').text('');
                $('#submit_button').prop('disabled', false);
                $('#member').val(result.member_id);
            }
        }
});

//async _onChangeMember(ev) {
//            var result = await jsonrpc('/check/member',  {
//                        'member_id' :ev.target.value
//                        })
//            if(result.exists == false){
//                $('#validation_message').text('Invalid Employee ID.');
//                $('#member').val(false);
//                $('#submit_button').prop('disabled', true);
//            }
//            else{
//                $('#checkin_form').attr('action', '/my/questions/' + $('#worksheet_id')[0].value+'/'+ result.member_id );
//                $('#validation_message').text('');
//                $('#submit_button').prop('disabled', false);
//                $('#member').val(result.member_id);
//            }
//        }