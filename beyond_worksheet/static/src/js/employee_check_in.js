/** @odoo-module **/
import publicWidget from "@web/legacy/js/public/public_widget";
import { jsonrpc } from "@web/core/network/rpc_service";

publicWidget.registry.MemberPortal = publicWidget.Widget.extend({
    selector: '.member_portal',
        start: function () {
            this._super.apply(this, arguments);
            $('#submit_button').prop('disabled', true);
        },
        events: {
            'keyup #unique_member_id': '_onChangeMember',
        },
        async _onChangeMember(ev) {
            var worksheet_id = $('#worksheet_id')[0].value
            var result = await jsonrpc('/check/member',  {
                        'member_id' :ev.target.value,
                        'worksheet_id':worksheet_id
                        })
            if(result.exists == false){
                $('#validation_message').text('Invalid Employee ID.');
                $('#member').val(false);
                $('#submit_button').prop('disabled', true);
            }
            else{
                $('#start_form').attr('action', '/my/swms/report/' + worksheet_id +'/'+ result.member_id );
                $('#validation_message').text('');
                $('#submit_button').prop('disabled', false);
                $('#member').val(result.member_id);
            }
        }
});
