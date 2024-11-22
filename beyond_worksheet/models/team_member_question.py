# -*- coding: utf-8 -*-
try:
    import qrcode
except ImportError:
    qrcode = None
try:
    import base64
except ImportError:
    base64 = None
from odoo import models, fields


class TeamMemberQuestion(models.Model):
    _name = 'team.member.question'
    _description = 'Team member Question'

    sequence = fields.Integer(string='Sequence')
    name = fields.Text(string='Question')
    answer = fields.Char(string='Answer')

class SurveyQuestion(models.Model):
    _inherit = 'survey.question'

    # is_from_worksheet = fields.Boolean(related='survey_id.is_from_worksheet', store=True)
    is_from_worksheet_questions = fields.Boolean(default=False)

class SurveySurvey(models.Model):
    _inherit = 'survey.survey'

    team_member_id = fields.Many2one('team.member')
    worksheet_id = fields.Many2one('task.worksheet')
    is_from_worksheet = fields.Boolean(default=False)
