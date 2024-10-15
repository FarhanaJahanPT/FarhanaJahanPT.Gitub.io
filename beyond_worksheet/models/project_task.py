# -*- coding: utf-8 -*-
from datetime import datetime, timedelta

from odoo import api, fields, models, _


class ProjectTask(models.Model):
    _inherit = "project.task"

    worksheet_id = fields.Many2one('task.worksheet')
    assigned_users = fields.Many2many('res.users', string='Assigned Users')
    witness_signature = fields.Char(string="Witness Signature", copy=False)


    def write(self, vals):
        res = super().write(vals)
        if self.x_studio_confirmed_with_customer and self.x_studio_proposed_team and self.date_deadline and self.planned_date_start and not self.worksheet_id:
            worksheet = self.worksheet_id.create({
                'task_id': self.id,
                'sale_id': self.sale_order_id.id if self.sale_order_id else False
            })
            self.worksheet_id = worksheet.id
        return res

    def _send_team_notifications_cron(self):
        today = datetime.today()
        next_monday = today + timedelta(days=(7 - today.weekday()) % 7)
        next_friday = next_monday + timedelta(days=4)
        task_ids = self.search([('planned_date_start', '>=', next_monday.date()),('planned_date_start', '<=', next_friday.date())])
        user_ids = task_ids.assigned_users
        user_ids += task_ids.x_studio_proposed_team
        for user in user_ids:
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
