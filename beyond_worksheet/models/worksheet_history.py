# -*- coding: utf-8 -*-
from odoo import fields, models


class WorksheetHistory(models.Model):
    _name = 'worksheet.history'
    _description = "Worksheet History"

    worksheet_id = fields.Many2one('task.worksheet', string='Worksheet', required=True)
    user_id = fields.Many2one('res.users', string='User')
    member_id = fields.Many2one('team.member', string='Team')
    changes = fields.Char(string='Changes')
    details = fields.Text(string='Details')
