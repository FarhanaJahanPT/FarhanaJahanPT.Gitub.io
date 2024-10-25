# -*- coding: utf-8 -*-
from odoo import api, fields, models, _


class WorksheetAttendance(models.Model):
    _name = 'worksheet.attendance'
    _description = "Worksheet Attendance"

    type = fields.Selection([('check_in', 'Check In'),
                             ('check_out', 'Check Out')], string='Type',
                            required=True)
    date = fields.Datetime(string='Date', default=lambda self: fields.Datetime.now(), required=True)
    location = fields.Char(string='Location')
    member_id = fields.Many2one('team.member', string='User', required=True)
    task_id = fields.Many2one('project.task', related="worksheet_id.task_id")
    worksheet_id = fields.Many2one('task.worksheet', string='Worksheet', required=True)
    additional_service = fields.Boolean(string='Additional Service')

    @api.model_create_multi
    def create(self, vals_list):
        res = super(WorksheetAttendance, self).create(vals_list)
        self.env['worksheet.history'].create({
            'worksheet_id': res.worksheet_id.id,
            'user_id': res.user_id.id,
            'changes': 'Attendance',
            'details': 'Check In Site Attendance has been updated successfully.' if res.type == 'check_in' else 'Check Out Site Attendance has been updated successfully.',
        })
        return res
