# -*- coding: utf-8 -*-
from email.policy import default

from odoo import api, fields, models


class ProjectTask(models.Model):
    _inherit = "project.task"

    panel_lot_ids = fields.One2many('stock.lot','task_id',
                                    string='Panel Serial Number', domain=[('type', '=', 'panel')],  readonly=True)
    inverter_lot_ids = fields.One2many('stock.lot', 'task_id',
                                       string='Inverter Serial Number', domain=[('type', '=', 'inverter')], readonly=True)
    battery_lot_ids = fields.One2many('stock.lot', 'task_id',
                                      string='Battery Serial Number', domain=[('type', '=', 'battery')], readonly=True)
    panel_count = fields.Integer(string='Panel Count', compute='compute_order_count',store=True, default=0)
    inverter_count = fields.Integer(string='Inverter Count', compute='compute_order_count',store=True, default=0)
    battery_count = fields.Integer(string='Battery Count', compute='compute_order_count',store=True, default=0)

    @api.depends('sale_order_id')
    def compute_order_count(self):
        for rec in self:
            order_line = rec.sale_order_id.order_line.filtered(lambda sol: sol.product_id.categ_id.name == 'Inverters' or sol.product_id.categ_id.parent_id.name == 'Inverters')[:1]
            rec.inverter_count = sum(order_line.mapped('product_uom_qty'))
            order_line = rec.sale_order_id.order_line.filtered(lambda sol: sol.product_id.categ_id.name == 'Solar Panels')[:1]
            rec.panel_count = sum(order_line.mapped('product_uom_qty'))
            order_line = rec.sale_order_id.order_line.filtered(lambda sol: sol.product_id.categ_id.name == 'Storage')[:1]
            rec.battery_count = sum(order_line.mapped('product_uom_qty'))

    @api.model
    def get_checklist_values(self, vals):
        data = []
        checklist = []
        if self.browse(vals).x_studio_type_of_service == 'New Installation':
            checklist_ids = self.env['installation.checklist'].search([('task_ids', '=',vals)])
            checklist_item_ids = self.env['installation.checklist.item'].search([('task_id', '=',vals)])
            for checklist_id in checklist_ids:
                data.append([checklist_id.id,checklist_id.name,checklist_id.type])
            for checklist_item_id in checklist_item_ids:
                checklist.append([checklist_item_id.checklist_id.id,checklist_item_id.create_date,checklist_item_id.location,checklist_item_id.text, checklist_item_id.image])
        elif self.browse(vals).x_studio_type_of_service == 'Service':
            checklist_ids = self.env['service.checklist'].search([('task_ids', '=', vals)])
            checklist_item_ids = self.env['service.checklist.item'].search([('task_id', '=', vals)])
            for checklist_id in checklist_ids:
                data.append([checklist_id.id, checklist_id.name, checklist_id.type])
            for checklist_item_id in checklist_item_ids:
                checklist.append([checklist_item_id.service_id.id,
                                  checklist_item_id.create_date,
                                  checklist_item_id.location,
                                  checklist_item_id.text,
                                  checklist_item_id.image])
        return data, checklist
