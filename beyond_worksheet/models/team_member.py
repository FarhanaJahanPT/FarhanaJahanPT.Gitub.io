# -*- coding: utf-8 -*-
from datetime import datetime, timedelta

from odoo import fields, models


class TeamMember(models.Model):
    _name = 'team.member'
    _description = 'Team member'

    member_id = fields.Char("Member ID", required=True, copy=False)
    name = fields.Char('Name', required=True)
    mobile = fields.Char('Mobile')
    country_id = fields.Many2one('res.country', string='Country')
    email = fields.Char(string='Email Address', required=True)

    _sql_constraints = [
        ('uniq_member_id', 'UNIQUE(member_id)', 'This Member ID is already Exist'),
    ]

    def get_weekly_work(self, object):
        today = datetime.today()
        next_monday = today + timedelta(days=(7 - today.weekday()) % 7)
        next_friday = next_monday + timedelta(days=4)
        tasks = self.env['project.task'].search([('planned_date_start', '>=', next_monday.date()),('planned_date_start', '<=', next_friday.date())])
        task_ids = tasks.filtered(lambda w: object in w.worksheet_id.team_member_ids)
        return task_ids
