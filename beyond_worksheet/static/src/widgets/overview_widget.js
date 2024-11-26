/** @odoo-module **/
import { _t } from "@web/core/l10n/translation";
import { registry } from "@web/core/registry";
import { standardWidgetProps } from "@web/views/widgets/standard_widget_props";
import { useService } from "@web/core/utils/hooks";
import { Component, useState, onWillStart } from "@odoo/owl";
import { ChecklistOverviewPopup } from "../popups/checklist_overview_popups/checklist_overview_popup"

class Overview extends Component {
    static template = "beyond_worksheet.Overview";
    static props = { ...standardWidgetProps, };
    async setup() {
        this.state = useState({
            data: {},
        });
        this.dialogService = useService("dialog");
        this.action = useService("action");
        this.orm = useService("orm");
        onWillStart(async () => {
            console.log('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',this)
            console.log('sssssssssssssssssssssssssssss',this.props)
            var resId = this.props.record.evalContext.id
            const action = await this.orm.call('task.worksheet', 'get_overview_values', [resId]);
            console.log(action,'aaaaaaaaaaaaaaaaaaaaaaaaaaaa')
            this.state.data.overview = action[0]
            this.state.data.serial_count = action[1]
            this.state.data.images_data = action[2]
        });
    }
    checklist(ev){
        console.log('qqqqqqqqqqqqqqqqqqqqqqqqqqqqq',ev)
        const images = this.state.data.images_data.filter((item) => item[0] === ev[0])
        console.log(images,"==========d")
            const props = {
                name:ev[2],
                class:ev[1],
                images:images
            }
            this.dialogService.add(ChecklistOverviewPopup,props);

//        return this.action.doAction({
//            name: _t(ev[2]),
//            res_model: 'installation.checklist.item',
////            domain: [["checklist_id", "=", ev[0]]],
//            type: 'ir.actions.act_window',
//            view_mode: 'kanban',
//            views: [[false, 'kanban']],
//            target: 'new',
//        });
    }
}
export const overview = {
    component: Overview,
};
registry.category("view_widgets").add("overview_widget", overview);
