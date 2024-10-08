# -*- coding: utf-8 -*-
from datetime import datetime, timedelta

from odoo import api, fields, models, _
from odoo.exceptions import ValidationError


class WorksheetAttendance(models.Model):
    _name = 'worksheet.attendance'
    _description = "Worksheet Attendance"

    # installation_image = fields.Image(string='Installation Image', store=True)
    type = fields.Selection([('check_in', 'Check In'),
                             ('check_out', 'Check Out')], string='Type',
                            required=True)
    location = fields.Char(string='Location')
    user_id = fields.Many2one('res.users', string='User', required=True)
    task_id = fields.Many2one('project.task', required=True)

    # @api.model
    # def create(self, vals):
    #     task = self.search([('task_id', '=',vals['task_id']),('user_id', '=', vals['user_id']),('location', 'ilike',vals['location'])])
    #     if task:
    #         for rec in task:
    #             if rec.create_date + timedelta(minutes=60) >= datetime.now():
    #                 raise ValidationError(
    #                     _('Please take selfies with a reasonable time interval of at least 60 mins between each stage.'))
    #     return super(WorksheetAttendance, self).create(vals)