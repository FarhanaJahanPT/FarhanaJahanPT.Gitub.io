/** @odoo-module **/

import { registry } from "@web/core/registry";
import { standardFieldProps } from "@web/views/fields/standard_field_props";

import { Component, onMounted, useRef } from "@odoo/owl";

class RiskColorWidget extends Component {
    static template = "beyond_worksheet.RiskColorWidget";
    static props = {
        ...standardFieldProps,
    };

    setup() {
        super.setup();
        console.log('aaaaaaaaaaaaaaaaaaaaaaaaaaaa',this)
        console.log('ssssssssssssssssssssssssss',this.props.record.data[this.props.name])
//        this.inputs = [];
//        for (let i = 0; i < 6; i++) {
//            this.inputs.push(useRef(`input_${i}`));
//        }
//
//        /*
//        if the verification code was previously filled in and the user saved the page,
//        pre-fill the input fields with the stored value.
//        */
//        onMounted(async () => {
//            const verificationCode = this.props.record.data.account_peppol_verification_code;
//            for (let i = 0; i < this.inputs.length; i++) {
//                this.inputs[i].el.value = verificationCode[i] || null;
//            }
//        });
    }

    onChange(ev) {
        console.log('awwwwwwwwwwwwwwwwwwwwwwwwwwww',ev)
        console.log('ssssssssssssssssssssssssss',this.props.record.data.risk_level)
        this.props.record.update({[this.props.name]:ev})
//        await this.model.load();
//        this.model.notify();
    }
}

export const riskColorField = {
    component: RiskColorWidget,
    supportedTypes: ["selection"],
};

registry.category("fields").add("risk_color", riskColorField);
