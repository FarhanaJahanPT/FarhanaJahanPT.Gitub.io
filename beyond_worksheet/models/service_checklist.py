# -*- coding: utf-8 -*-
from odoo import api, fields, models


class ServiceChecklist(models.Model):
    _name = 'service.checklist'
    _description = "Service Checklist"

    name = fields.Char(string='Name', required=True)
    type = fields.Selection([('img', 'Image/PDF'), ('text', 'Text')], string='Type', default='img')
    compulsory = fields.Boolean(string='Compulsory', default=False)
    min_qty = fields.Integer(string='Minimum Quantity', default=1)
    selfie_type = fields.Selection([('check_in', 'Check In'), ('mid', 'Mid Time'),
                                    ('check_out', 'Check Out'), ('null', ' ')],
                                   string='Selfie Type', default='null')
    category_ids = fields.Many2many('product.category', string='Category',
                                    required=True)

    def get_checklist_count(self):
        worksheet_ids = self.env['task.worksheet'].search([('x_studio_type_of_service', '=', 'Service')])
        for rec in worksheet_ids:
            rec.checklist_count = 0
            order_line = rec.sale_id.order_line.product_id.categ_id.mapped('id')
            checklist_ids = self.search([('category_ids', 'in', order_line)]).mapped('min_qty')
            rec.checklist_count = sum(checklist_ids)

    def write(self, vals):
        res = super(ServiceChecklist, self).write(vals)
        self.get_checklist_count()
        return res

    @api.model_create_multi
    def create(self, vals_list):
        res = super(ServiceChecklist, self).create(vals_list)
        res.get_checklist_count()
        return res
