# -*- coding: utf-8 -*-
from odoo import api, fields, models, _


class WorksheetAttendance(models.Model):
    _name = 'worksheet.attendance'
    _description = "Worksheet Attendance"

    type = fields.Selection([('check_in', 'Check In'),
                             ('check_out', 'Check Out')], string='Type',
                            required=True)
    location = fields.Char(string='Location')
    user_id = fields.Many2one('res.users', string='User', required=True)
    task_id = fields.Many2one('project.task', related="worksheet_id.task_id")
    worksheet_id = fields.Many2one('task.worksheet', string='Worksheet', required=True)
    additional_service = fields.Boolean(string='Additional Service')

