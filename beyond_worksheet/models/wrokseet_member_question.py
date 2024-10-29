from odoo import api, fields, models


class WorksheetMemberQuestion(models.Model):
    _name = 'worksheet.member.question'
    _description = "Worksheet Member Question"

    question_id = fields.Many2one('team.member.question',string='Question')
    answer = fields.Text('Answer')
    worksheet_id = fields.Many2one('task.worksheet',string='Worksheet')
    member_id = fields.Many2one('team.member',string='Member')
    date = fields.Datetime('Date')