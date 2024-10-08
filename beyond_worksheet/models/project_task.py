# -*- coding: utf-8 -*-
from datetime import datetime, timedelta

from odoo import api, fields, models, _


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
    checklist_item_ids = fields.One2many('installation.checklist.item','task_id', domain=[('checklist_id.selfie_type', '=', 'null')])
    service_item_ids = fields.One2many('service.checklist.item','task_id', domain=[('service_id.selfie_type', '=', 'null')])
    is_checklist = fields.Boolean(string='Checklist', compute='compute_is_checklist', store=True, readonly=True)
    is_individual = fields.Boolean(string='Individual')
    worksheet_sequence = fields.Char(string='Worksheet Reference', readonly=True,default=lambda self: _('New'), copy=False)
    assigned_users = fields.Many2many('res.users', string='Assigned Users')
    witness_signature = fields.Char(string="Witness Signature", copy=False)
    witness_signature_date = fields.Datetime(string="Witness Signature Date", copy=False)


    @api.model
    def create(self, vals_list):
        """Function to create sequence"""
        for vals in vals_list:
            if not vals.get('worksheet_sequence') or vals['worksheet_sequence'] == _('New'):
                vals['worksheet_sequence'] = self.env['ir.sequence'].next_by_code('project.task') or _('New')
        return super().create(vals_list)

    @api.depends('checklist_item_ids', 'service_item_ids', 'is_individual')
    def compute_is_checklist(self):
        for rec in self:
            rec.is_checklist = False
            order_line = rec.sale_order_id.order_line.product_id.categ_id.mapped('id')
            if rec.x_studio_type_of_service == 'New Installation':
                checklist_ids = self.env['installation.checklist'].search([('category_ids', 'in', order_line), ('selfie_type', '=', 'null')]).mapped('min_qty')
                if sum(checklist_ids) == len(rec.checklist_item_ids):
                    rec.is_checklist = True
            if rec.x_studio_type_of_service == 'Service':
                checklist_ids = self.env['service.checklist'].search([('category_ids', 'in', order_line), ('selfie_type', '=', 'null')]).mapped('min_qty')
                if sum(checklist_ids) == len(rec.service_item_ids):
                    rec.is_checklist = True

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
        order_line = self.browse(vals).sale_order_id.order_line.product_id.categ_id.mapped('id')
        if self.browse(vals).x_studio_type_of_service == 'New Installation':
            checklist_ids = self.env['installation.checklist'].search([('category_ids', 'in', order_line)])
            checklist_item_ids = self.env['installation.checklist.item'].search([('task_id', '=',vals)])
            for checklist_id in checklist_ids:
                data.append([checklist_id.id,checklist_id.name,checklist_id.type])
            for checklist_item_id in checklist_item_ids:
                checklist.append([checklist_item_id.checklist_id.id,
                                  checklist_item_id.create_date,
                                  checklist_item_id.location,
                                  checklist_item_id.text,
                                  checklist_item_id.image])
        elif self.browse(vals).x_studio_type_of_service == 'Service':
            checklist_ids = self.env['service.checklist'].search([('category_ids', 'in', order_line)])
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

    def _send_team_notifications_cron(self):
        today = datetime.today()
        next_monday = today + timedelta(days=(7 - today.weekday()) % 7)
        next_friday = next_monday + timedelta(days=4)
        task_ids = self.search([('planned_date_start', '>=', next_monday.date()),('planned_date_start', '<=', next_friday.date())])
        for user in task_ids.x_studio_proposed_team:
            task_id = task_ids.filtered(lambda e: e.x_studio_proposed_team == user)
            if user.partner_id.email and user.is_internal_user == True:
                email_values = {'email_to': user.partner_id.email,
                                'email_from': user.company_id.email}
                mail_template = self.env.ref('beyond_worksheet.worksheet_email_template')
                mail_template.send_mail(task_id[:1].id, email_values=email_values,force_send=True)
            elif user.partner_id.email:
                email_values = {'email_to': user.partner_id.email,'email_from': user.company_id.email}
                mail_template = self.env.ref('beyond_worksheet.external_worksheet_email_template')
                mail_template.send_mail(task_id[:1].id,email_values=email_values,force_send=True)

    def get_weekly_work(self,object):
        today = datetime.today()
        next_monday = today + timedelta(days=(7 - today.weekday()) % 7)
        next_friday = next_monday + timedelta(days=4)
        task_ids = self.search([('planned_date_start', '>=', next_monday.date()),('planned_date_start', '<=', next_friday.date()), ('x_studio_proposed_team', '=', object.x_studio_proposed_team.id)])
        return task_ids
