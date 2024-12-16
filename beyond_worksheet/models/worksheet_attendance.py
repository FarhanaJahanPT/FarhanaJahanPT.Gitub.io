# -*- coding: utf-8 -*-
from odoo import api, fields, models

def get_google_maps_url(latitude, longitude):
    return "https://maps.google.com?q=%s,%s" % (latitude, longitude)


class WorksheetAttendance(models.Model):
    _name = 'worksheet.attendance'
    _description = "Worksheet Attendance"

    type = fields.Selection([('check_in', 'Check In'),
                             ('check_out', 'Check Out')], string='Type',
                            required=True)
    date = fields.Datetime(string='Date')
    location = fields.Char(string='Location')
    member_id = fields.Many2one('team.member', string='User', required=True)
    task_id = fields.Many2one('project.task', related="worksheet_id.task_id")
    worksheet_id = fields.Many2one('task.worksheet', string='Worksheet', required=True)
    additional_service = fields.Boolean(string='Additional Service')
    in_latitude = fields.Float(string="Latitude", digits=(10, 7), readonly=True)
    in_longitude = fields.Float(string="Longitude", digits=(10, 7), readonly=True)
    survey_id = fields.Many2one('survey.survey')
    user_input_id = fields.Many2one('survey.user_input')
    signature = fields.Image(
        string="Signature",
        copy=False, attachment=True, max_width=1024, max_height=1024)

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

    def action_view_answers(self):
        self.ensure_one()
        return {
            'type': 'ir.actions.act_window',
            'name': 'Responses',
            'view_mode': 'form',
            'res_model': 'survey.user_input',
            'res_id': self.user_input_id.id,
            'target': 'new',
        }

    @api.model
    def auto_create_check_out(self):
        # Get today's date
        today = fields.Date.today()
        # Find members who have checked in but not checked out
        check_ins = self.env['worksheet.attendance'].sudo().search([
            ('type', '=', 'check_in'),
            ('date', '<=', today),  # Check-ins from previous days
        ])
        for check_in in check_ins:
            check_out_exists = self.env['worksheet.attendance'].sudo().search([
                ('type', '=', 'check_out'),
                ('member_id', '=', check_in.member_id.id),
                ('worksheet_id', '=', check_in.worksheet_id.id),
                ('date', '=', check_in.date),
            ])
            if not check_out_exists:
                self.env['worksheet.attendance'].sudo().create({
                    'type': 'check_out',
                    'member_id': check_in.member_id.id,
                    'worksheet_id': check_in.worksheet_id.id,
                    'date': check_in.date,
                })

    @api.model
    def create(self, vals):
        return super(WorksheetAttendance, self.sudo()).create(vals)
