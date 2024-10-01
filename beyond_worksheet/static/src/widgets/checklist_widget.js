/** @odoo-module **/
import { registry } from "@web/core/registry";
import { standardWidgetProps } from "@web/views/widgets/standard_widget_props";
import { useService } from "@web/core/utils/hooks";
import { Component, useState, onWillStart } from "@odoo/owl";

class Checklist extends Component {
    static template = "beyond_worksheet.Checklist";
    static props = { ...standardWidgetProps, };
    async setup() {
        this.state = useState({
            data: {},
        });
        this.action = useService("action");
        this.orm = useService("orm");
        onWillStart(async () => {
            var resId = this.props.record.evalContext.id
            const action = await this.orm.call('project.task', 'get_checklist_values', [resId]);
            this.state.data.checklist = action[0]
            this.state.data.checklist_item = action[1]
        });
    }
}
export const checklist = {
    component: Checklist,
};
registry.category("view_widgets").add("checklist_widget", checklist);
