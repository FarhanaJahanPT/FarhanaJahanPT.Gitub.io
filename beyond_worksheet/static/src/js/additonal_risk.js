/** @odoo-module **/

import publicWidget from "@web/legacy/js/public/public_widget";
import { jsonrpc } from "@web/core/network/rpc_service";

publicWidget.registry.AdditionalRisk = publicWidget.Widget.extend({
    selector: '.swms_report',  // Replace with the class/id of the template element
        events: {
            'click #addRiskBtn': '_addRiskBtn',
        },
    init() {
       this.rpc = this.bindService("rpc");
    },
    async _addRiskBtn(ev) {
        const worksheetId = $('#worksheet_id').val();
        const risk = $('#additionalRiskValue').val();
        if (risk){
            await jsonrpc('/worksheet/additional/risk/',  {
                        'risk' :risk,
                        'worksheet_id':worksheetId
                        })
            $('#riskModalClose').click()
            $('#additionalRiskValue').val('');
        }
        else{
            $('#validation_message_risk').text('Please Enter the risk.');
        }
    }
});