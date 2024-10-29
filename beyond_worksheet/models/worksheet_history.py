# -*- coding: utf-8 -*-
from odoo import api, fields, models


class WorksheetHistory(models.Model):
    _name = 'worksheet.history'
    _description = "Worksheet History"

    worksheet_id = fields.Many2one('task.worksheet', string='Worksheet', required=True)
    user_id = fields.Many2one('res.users', string='User', default=lambda self: self.env.user)
    member_id = fields.Many2one('team.member', string='User')
    changes = fields.Char(string='Changes')
    details = fields.Text(string='Details')
