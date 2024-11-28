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
            this.state.data.resId = this.props.record.evalContext.id
            const action = await this.orm.call('task.worksheet', 'get_overview_values', [this.state.data.resId]);
            console.log('aaaaaaaaaaaaaaaaaaaaaaaa',action)
            this.state.data.overview = action[0]
            this.state.data.serial_count = action[1]
            this.state.data.images_data = action[2]
        });
    }
    checklist(ev){
        const images = this.state.data.images_data.filter((item) => item[0] === ev[0])
            const props = {
                id:ev[0],
                name:ev[2],
                class:ev[1],
                type:ev[9],
                worksheet_id:this.state.data.resId,
                images:images
            }
            this.dialogService.add(ChecklistOverviewPopup,props);
    }
    async SerialNumberView(ev) {
        try {
            // Extract record ID
            var id = this.props.record.evalContext.id;
            if (typeof id === "object" && id !== null) {
                id = id.id || id[0]; // Adjust if id is an object or array
            }
            // Fetch tree view ID
            const treeViews = await this.orm.call(
                'ir.ui.view',
                'search_read',
                [[['name', '=', 'stock.production.lot.view.tree']], ['id'], 0, 1]
            );
            const treeViewId = treeViews.length > 0 ? treeViews[0].id : false;

            if (!treeViewId) {
                console.error("Tree view not found");
                return;
            }
            return this.action.doAction({
                name: _t(ev[2] + " Serial Number View"),
                res_model: 'stock.lot',
                domain: [["type", "=", ev[2]], ["worksheet_id", "=", id]],
                type: 'ir.actions.act_window',
                view_mode: 'tree',
                views: [[treeViewId, 'tree']],
                target: 'new',
            });
        } catch (error) {
            console.error("Error in SerialNumberView:", error);
        }
    }
    async onChange(ev){
        const result = await this.orm.call('task.worksheet', 'get_checklist_compliant', [this.state.data.resId, ev]);
    }
}
export const overview = {
    component: Overview,
};
registry.category("view_widgets").add("overview_widget", overview);
