# -*- coding: utf-8 -*-
from datetime import datetime, timedelta

from odoo import api, fields, models, _


class ProjectTask(models.Model):
    _inherit = "project.task"

    worksheet_id = fields.Many2one('task.worksheet')

    def write(self, vals):
        res = super().write(vals)
        if self.x_studio_confirmed_with_customer and self.x_studio_proposed_team and self.date_deadline and self.planned_date_start and not self.worksheet_id:
            worksheet = self.worksheet_id.create({
                'task_id': self.id,
                'sale_id': self.sale_order_id.id if self.sale_order_id else False
            })
            self.worksheet_id = worksheet.id
        return res

    @api.model
    def get_checklist_values(self, vals):
        data = []
        checklist = []
        order_line = self.browse(vals).sale_order_id.order_line.product_id.categ_id.mapped('id')
        if self.browse(vals).x_studio_type_of_service == 'New Installation':
            checklist_ids = self.env['installation.checklist'].search([('category_ids', 'in', order_line)])
            checklist_item_ids = self.env['installation.checklist.item'].search([('task_id', '=', vals)])
            for checklist_id in checklist_ids:
                data.append([checklist_id.id, checklist_id.name, checklist_id.type])
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
        for user in task_ids.assigned_users:
            email_values = {'email_to': user.partner_id.email,
                            'email_from': user.company_id.email}
            if user.is_internal_user == True:
                mail_template = self.env.ref('beyond_worksheet.worksheet_email_template')
            else:
                mail_template = self.env.ref('beyond_worksheet.external_worksheet_email_template')
            mail_template.send_mail(user.id, email_values=email_values,force_send=True)

    def get_worksheet(self):
        self.ensure_one()
        return {
            'type': 'ir.actions.act_window',
            'name': 'Worksheet',
            'view_mode': 'form',
            'res_model': 'task.worksheet',
            'res_id': self.worksheet_id.id,
            'context': "{'create': False}"
        }