# -*- coding: utf-8 -*-
from datetime import datetime, timedelta
from odoo import api, fields, models


class ProjectTask(models.Model):
    _inherit = "project.task"

    worksheet_id = fields.Many2one('task.worksheet')
    witness_signature = fields.Char(string="Witness Signature", copy=False)
    witness_signature_date = fields.Datetime(string="Witness Signature Date", copy=False)
    witness_name = fields.Char(string="Witness Name", copy=False)
    team_lead_id = fields.Many2one('team.member', string='Assigned Installer')

    def write(self, vals):
        res = super().write(vals)
        if self.x_studio_confirmed_with_customer and self.team_lead_id and self.date_deadline and self.planned_date_start and not self.worksheet_id:
            worksheet = self.worksheet_id.create({
                'task_id': self.id,
                'sale_id': self.sale_order_id.id if self.sale_order_id else False
            })
            self.worksheet_id = worksheet.id
        return res

    @api.constrains('team_lead_id')
    def check_team_lead_id(self):
        if self.worksheet_id:
            self.env['worksheet.history'].sudo().create({
                'worksheet_id': self.worksheet_id.id,
                'user_id': self.env.user.id,
                'changes': 'Assigned Team Leader',
                'details': 'Worksheet assigned to ({}) has been successfully updated.'.format(self.team_lead_id.name),
            })
            model_id = self.env['ir.model'].search([('model', '=', 'task.worksheet')], limit=1).id
            self.env['worksheet.notification'].sudo().create([{
                'author_id': self.env.user.id,
                'team_id': self.team_lead_id.id,
                'model_id': model_id,
                'res_id': self.worksheet_id.id,
                'date': datetime.now(),
                'subject': 'Worksheet Assigned',
                'body': '{} has been assigned to you for installation on {}'.format(self.name, self.planned_date_start),
            }])

    def _send_team_notifications_cron(self):
        today = datetime.today()
        next_monday = today + timedelta(days=(7 - today.weekday()) % 7)
        next_friday = next_monday + timedelta(days=4)
        task_ids = self.search(
            [('planned_date_start', '>=', next_monday.date()),
             ('planned_date_start', '<=', next_friday.date())])
        if task_ids.worksheet_id:
            member_ids = task_ids.worksheet_id.team_lead_id
            member_ids += task_ids.worksheet_id.team_member_ids
            for member_id in member_ids:
                email_values = {'email_to': member_id.email,
                                'email_from': self.env.company.email}
                if member_id.employee_id:
                    mail_template = self.env.ref(
                        'beyond_worksheet.worksheet_email_template')
                else:
                    mail_template = self.env.ref(
                        'beyond_worksheet.external_worksheet_email_template')
                mail_template.send_mail(member_id.id, email_values=email_values,
                                        force_send=True)

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
