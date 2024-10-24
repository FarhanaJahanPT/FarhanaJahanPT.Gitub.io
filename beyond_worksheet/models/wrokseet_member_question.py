from odoo import api, fields, models
from odoo.exceptions import ValidationError


class WorksheetMemberQuestion(models.Model):
    _name = 'worksheet.member.question'
    _description = "Worksheet Member Question"

    question_id = fields.Many2one('team.member.question',string='Question')
    answer = fields.Text('Answer')
    worksheet_id = fields.Many2one('task.worksheet',string='Worksheet')
    user_id = fields.Many2one('res.users',string='Member')
    date = fields.Datetime('Date')