# -*- coding: utf-8 -*-
from odoo import api, fields, models, _

def get_google_maps_url(latitude, longitude):
    return "https://maps.google.com?q=%s,%s" % (latitude, longitude)


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
    in_latitude = fields.Float(string="Latitude", digits=(10, 7), readonly=True)
    in_longitude = fields.Float(string="Longitude", digits=(10, 7), readonly=True)

    @api.model_create_multi
    def create(self, vals_list):
        res = super(WorksheetAttendance, self).create(vals_list)
        self.env['worksheet.history'].sudo().create({
            'worksheet_id': res.worksheet_id.id,
            'user_id': res.create_uid.id,
            'member_id': res.member_id.id if res.member_id else False,
            'changes': 'Attendance',
            'details': 'Check In Site Attendance has been updated successfully.' if res.type == 'check_in' else 'Check Out Site Attendance has been updated successfully.',
        })
        return res

    def action_view_maps(self):
        self.ensure_one()
        return {
            'type': 'ir.actions.act_url',
            'url': get_google_maps_url(self.in_latitude, self.in_longitude),
            'target': 'new'
        }