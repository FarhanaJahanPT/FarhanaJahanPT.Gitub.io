# -*- coding: utf-8 -*-
from datetime import datetime, timedelta
from odoo import fields, models, _


class ResUsers(models.Model):
    _inherit = 'res.users'

    is_internal_user = fields.Boolean(string='Internal User')
    invoice_amount =  fields.Monetary(string='Invoice amount', default=0)
    currency_id = fields.Many2one(comodel_name='res.currency',
                                  string="Company Currency",
                                  related='company_id.currency_id',)

    def get_weekly_work(self,object):
        today = datetime.today()
        next_monday = today + timedelta(days=(7 - today.weekday()) % 7)
        next_friday = next_monday + timedelta(days=4)
        task_ids = self.env['project.task'].search([('planned_date_start', '>=', next_monday.date()),('planned_date_start', '<=', next_friday.date()), ('assigned_users', 'in', object.id)])
        return task_ids
