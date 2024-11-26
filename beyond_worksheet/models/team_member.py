# -*- coding: utf-8 -*-
from datetime import datetime, timedelta
from odoo import api, fields, models


class TeamMember(models.Model):
    _name = 'team.member'
    _description = 'Team member'
    _rec_name = 'name'
    _inherit = ['mail.thread', 'mail.activity.mixin']

    employee_id = fields.Many2one('hr.employee', string='Employee')
    member_id = fields.Char("Member ID", required=True, copy=False)
    name = fields.Char('Name', required=True)
    mobile = fields.Char('Mobile')
    country_id = fields.Many2one('res.country', string='Country')
    email = fields.Char(string='Email Address', required=True)
    contract_license_ids = fields.One2many('electrical.contract.license','team_id')
    type = fields.Selection([('tpt', 'Third-Party team'),('tm', 'Team Member'),('tl', 'Team Leader'),], required=True)


    _sql_constraints = [
        ('uniq_member_id', 'UNIQUE(member_id)', 'This Member ID is already Exist'),
    ]

    def get_weekly_work(self, object):
        today = datetime.today()
        next_monday = today + timedelta(days=(7 - today.weekday()) % 7)
        next_friday = next_monday + timedelta(days=4)
        tasks = self.env['project.task'].search(
            [('planned_date_start', '>=', next_monday.date()),
             ('planned_date_start', '<=', next_friday.date())])
        task_ids = tasks.filtered(lambda w: w.team_lead_id == object)
        task_ids += tasks.filtered(lambda w: object in w.worksheet_id.team_member_ids)
        return task_ids


    @api.onchange('employee_id')
    def onchange_employee_id(self):
        if self.employee_id:
            self.name = self.employee_id.name
            self.mobile = self.employee_id.work_phone if self.employee_id.work_phone else self.employee_id.mobile_phone
            self.country_id = self.employee_id.country_id.id
            self.email = self.employee_id.work_email
        else:
            self.name = self.mobile = self.country_id = self.email = None

    def action_create_employee(self):
        employee_id = self.employee_id.create({
            'name': self.name,
            'work_phone': self.mobile,
            'country_id': self.country_id.id,
            'work_email': self.email
        })
        self.employee_id = employee_id.id
