# -*- coding: utf-8 -*-
from odoo import fields, models


class WorksheetMemberQuestion(models.Model):
    _name = 'worksheet.member.question'
    _description = "Worksheet Member Question"

    question_id = fields.Many2one('team.member.question',string='Question')
    answer = fields.Text(string='Answer')
    worksheet_id = fields.Many2one('task.worksheet',string='Worksheet')
    member_id = fields.Many2one('team.member',string='Member')
    date = fields.Datetime(string='Date')
