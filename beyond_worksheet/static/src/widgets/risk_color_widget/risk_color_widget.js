/** @odoo-module **/
import { registry } from "@web/core/registry";
import { standardFieldProps } from "@web/views/fields/standard_field_props";
import { Component } from "@odoo/owl";

class RiskColorWidget extends Component {
    static template = "beyond_worksheet.RiskColorWidget";
    static props = {
        ...standardFieldProps,
    };
    setup() {
        super.setup();
    }

    onChange(event) {
        this.props.record.update({[this.props.name]:event.target.value})
    }
}
export const riskColorField = {
    component: RiskColorWidget,
    supportedTypes: ["selection"],
};
registry.category("fields").add("risk_color", riskColorField);
