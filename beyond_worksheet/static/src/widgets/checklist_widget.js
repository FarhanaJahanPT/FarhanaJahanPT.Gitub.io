/** @odoo-module **/

import { registry } from "@web/core/registry";
import { standardWidgetProps } from "@web/views/widgets/standard_widget_props";
import { useService } from "@web/core/utils/hooks";
import { Component, useState, onMounted } from "@odoo/owl";

class Checklist extends Component {
    static template = "beyond_worksheet.Checklist";
    static props = { ...standardWidgetProps, };

    setup() {
        this.state = useState({
            data: {},
        });
//        this.style = "text-nowrap w-100";
//        if (this.props.record.data.expiring_synchronization_due_day <= 7) {
//            this.style +=
//                this.props.record.data.expiring_synchronization_due_day <= 3
//                    ? " text-danger"
//                    : " text-warning";
//        }
        this.action = useService("action");
        this.orm = useService("orm");
        onMounted(() => {
            this.get_data();
        });
        console.log('this..........................', this)
        console.log('this..........................', this.props.record.data)
        console.log('this..........................', this.props.record.evalContext.id)
        console.log('this..........................', this.props.record._config)
    }
    async get_data(){
    console.log('aaaaaaaaaaaaaaaaaaaaaaaaaa')
    var resId = this.props.record.evalContext.id
    const action = await this.orm.call('project.task', 'get_checklist_values', [resId]);

    }

}

export const checklist_ = {
    component: Checklist,
};

registry.category("view_widgets").add("checklist_widget", checklist_);
