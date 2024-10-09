# -*- coding: utf-8 -*-
from datetime import datetime, timedelta

from odoo import api, fields, models,_


class WorkSheet(models.Model):
    _name = 'task.worksheet'
    _description = "Worksheet"
    _inherit = 'mail.thread'



    name = fields.Char("Name", default=lambda self: _('New'))
    task_id = fields.Many2one('project.task', string='Task')
    sale_id = fields.Many2one('sale.order', string='Sale Order')

    panel_lot_ids = fields.One2many('stock.lot', 'worksheet_id',
                                    string='Panel Serial Number', domain=[('type', '=', 'panel')], readonly=True)

    inverter_lot_ids = fields.One2many('stock.lot', 'worksheet_id',
                                       string='Inverter Serial Number', domain=[('type', '=', 'inverter')],
                                       readonly=True)
    battery_lot_ids = fields.One2many('stock.lot', 'worksheet_id',
                                      string='Battery Serial Number', domain=[('type', '=', 'battery')], readonly=True)

    panel_count = fields.Integer(string='Panel Count', compute='_compute_order_count', store=True, default=0)
    inverter_count = fields.Integer(string='Inverter Count', compute='_compute_order_count', store=True, default=0)
    battery_count = fields.Integer(string='Battery Count', compute='_compute_order_count', store=True, default=0)

    checklist_item_ids = fields.One2many('installation.checklist.item', 'task_id',
                                         domain=[('checklist_id.selfie_type', '=', 'null')])
    service_item_ids = fields.One2many('service.checklist.item', 'task_id',
                                       domain=[('service_id.selfie_type', '=', 'null')])
    is_checklist = fields.Boolean(string='Checklist', compute='_compute_is_checklist', store=True, readonly=True)
    is_individual = fields.Boolean(string='Individual')
    worksheet_sequence = fields.Char(string='Worksheet Reference', readonly=True, default=lambda self: _('New'),
                                     copy=False)
    assigned_users = fields.Many2many('res.users', string='Assigned Users')
    witness_signature = fields.Char(string="Witness Signature", copy=False)
    witness_signature_date = fields.Datetime(string="Witness Signature Date", copy=False)
    x_studio_type_of_service = fields.Selection(string='Type of Service',
                                                related='sale_id.x_studio_type_of_service', readonly=True)
    worksheet_attendance_ids = fields.One2many('worksheet.attendance', 'worksheet_id', string='Worksheet Attendance')
    @api.model_create_multi
    def create(self, vals_list):
        """Function to create sequence"""
        for vals in vals_list:
            if not vals.get('name') or vals['name'] == _('New'):
                vals['name'] = self.env['ir.sequence'].next_by_code('task.worksheet') or _('New')
        return super().create(vals_list)

    @api.depends('sale_id')
    def _compute_order_count(self):
        for rec in self:
            order_line = rec.sale_id.order_line.filtered(
                lambda sol: sol.product_id.categ_id.name == 'Inverters' or sol.product_id.categ_id.parent_id.name == 'Inverters')[:1]
            rec.inverter_count = sum(order_line.mapped('product_uom_qty'))
            order_line = rec.sale_id.order_line.filtered(
                lambda sol: sol.product_id.categ_id.name == 'Solar Panels')[:1]
            rec.panel_count = sum(order_line.mapped('product_uom_qty'))
            order_line = rec.sale_id.order_line.filtered(lambda sol: sol.product_id.categ_id.name == 'Storage')[:1]
            rec.battery_count = sum(order_line.mapped('product_uom_qty'))


    @api.depends('checklist_item_ids', 'service_item_ids')
    def _compute_is_checklist(self):
        for rec in self:
            rec.is_checklist = False
            order_line = rec.sale_id.order_line.product_id.categ_id.mapped('id')
            if rec.task_id.x_studio_type_of_service == 'New Installation':
                checklist_ids = self.env['installation.checklist'].search(
                    [('category_ids', 'in', order_line), ('selfie_type', '=', 'null')]).mapped('min_qty')
                if sum(checklist_ids) == len(rec.checklist_item_ids):
                    rec.is_checklist = True
            if rec.task_id.x_studio_type_of_service == 'Service':
                checklist_ids = self.env['service.checklist'].search(
                    [('category_ids', 'in', order_line), ('selfie_type', '=', 'null')]).mapped('min_qty')
                if sum(checklist_ids) == len(rec.service_item_ids):
                    rec.is_checklist = True

    def get_sale_order(self):
        self.ensure_one()
        return {
            'type': 'ir.actions.act_window',
            'name': 'Sale Order',
            'view_mode': 'form',
            'res_model': 'sale.order',
            'res_id': self.sale_id.id,
            'context': "{'create': False}"
        }

    def get_task(self):
        self.ensure_one()
        return {
            'type': 'ir.actions.act_window',
            'name': 'Task',
            'view_mode': 'form',
            'res_model': 'project.task',
            'res_id': self.task_id.id,
            'context': "{'create': False}"
        }

    def _generate_attendance_invoice_cron(self):
        today = datetime.today()
        monday = today - timedelta(days=today.weekday())
        friday = monday + timedelta(days=4)
        attendance_ids = self.env['worksheet.attendance'].search([('create_date', '>=', monday.date()),('create_date', '<=', friday.date())])
        for worksheet_id in attendance_ids.worksheet_id:
            if worksheet_id.is_individual:
                service = worksheet_id.worksheet_attendance_ids.filtered(lambda w: w.type == 'check_in')
                additional = worksheet_id.worksheet_attendance_ids.filtered(lambda w: w.additional_service == True)
                vals = []
                if service:
                    vals.append((0, 0,{'name': "Services at {}".format(worksheet_id.name),
                                     'quantity': 1,
                                     'price_unit': service[:1].user_id.invoice_amount}))
                if additional:
                    vals.append((0, 0,{'name': "Additional service item at {}".format(worksheet_id.name),
                                     'quantity': 1,
                                     'price_unit': additional[:1].user_id.invoice_amount}))
                invoice = self.env['account.move'].create([{
                    'name': self.env['ir.sequence'].next_by_code('rcti.invoice'),
                    'move_type': 'in_invoice',
                    'partner_id': worksheet_id.worksheet_attendance_ids[:1].user_id.partner_id.id,
                    'invoice_origin': worksheet_id.name,
                    'date': worksheet_id.task_id.planned_date_begin,
                    'invoice_date_due': today.date() + timedelta(days=5),
                    'invoice_line_ids': vals
                }])
                print(invoice)
