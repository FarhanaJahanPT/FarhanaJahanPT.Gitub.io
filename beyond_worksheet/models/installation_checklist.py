# -*- coding: utf-8 -*-
from email.policy import default

from odoo import api, fields, models


class InstallationChecklist(models.Model):
    _name = 'installation.checklist'
    _description = "Installation Checklist"

    name = fields.Char(string='Name', required=True)
    type = fields.Selection([('img', 'Image/PDF'), ('text', 'Text')], string='Type', default='img')
    compulsory = fields.Boolean(string='Compulsory', default=False)
    min_qty = fields.Integer(string='Minimum Quantity', default=1)
    selfie_type = fields.Selection([('check_in', 'Check In'), ('mid', 'Mid Time'), ('check_out', 'Check Out'), ('null', ' ')],
                                   string='Selfie Type', default='null')
    category_ids = fields.Many2many('product.category', string='Category', required=True)
    is_spv_required = fields.Boolean(string='SPV Required', default=False)

    def get_checklist_count(self):
        worksheet_ids = self.env['task.worksheet'].search([('x_studio_type_of_service','=', 'New Installation')])
        for rec in worksheet_ids:
            rec.checklist_count = 0
            order_line = rec.sale_id.order_line.product_id.categ_id.mapped('id')
            checklist_ids = self.search([('category_ids', 'in', order_line)]).mapped('min_qty')
            rec.checklist_count = sum(checklist_ids)

    def write(self, vals):
        res = super(InstallationChecklist, self).write(vals)
        self.get_checklist_count()
        return res

    @api.model_create_multi
    def create(self, vals_list):
        res = super(InstallationChecklist, self).create(vals_list)
        res.get_checklist_count()
        return res
