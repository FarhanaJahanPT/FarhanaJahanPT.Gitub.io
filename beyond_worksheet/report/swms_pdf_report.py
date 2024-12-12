# -*- coding: utf-8 -*-
from datetime import date
from odoo import api,models


class ReportAccountHashIntegrity(models.AbstractModel):
    _name = 'report.beyond_worksheet.report_swms_worksheet'
    _description = 'Get hash swms worksheet result as PDF.'

    @api.model
    def _get_report_values(self, docids, data=None):
        record_id = self.env['task.worksheet'].browse(docids)
        risk = self.env['swms.risk.work'].search_read( [],['name', 'type'])
        order_line = record_id.sale_id.order_line.product_id.categ_id.mapped('id')
        risk_ids = self.env['swms.risk.register'].search([('category_id', 'in', order_line)])
        data.update({'risk': risk,'risk_ids':risk_ids,
                     'attendance_ids': record_id.worksheet_attendance_ids,
                     'date': date.today()})
        return {
            'doc_ids' : docids,
            'doc_model' : 'task.worksheet',
            'data' : data,
            'docs' : record_id,
        }
