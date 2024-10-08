# -*- coding: utf-8 -*-
from datetime import datetime, timedelta

from odoo import fields, models, _


class ResUsers(models.Model):
    _inherit = 'res.users'

    is_internal_user = fields.Boolean(string='Internal User')

    def get_weekly_work(self,object):
        today = datetime.today()
        next_monday = today + timedelta(days=(7 - today.weekday()) % 7)
        next_friday = next_monday + timedelta(days=4)
        task_ids = self.env['project.task'].search([('planned_date_start', '>=', next_monday.date()),('planned_date_start', '<=', next_friday.date()), ('assigned_users', 'in', object.id)])
        return task_ids