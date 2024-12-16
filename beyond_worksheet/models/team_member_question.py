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
import werkzeug


class TeamMemberQuestion(models.Model):
    _name = 'team.member.question'
    _description = 'Team member Question'

    sequence = fields.Integer(string='Sequence')
    name = fields.Text(string='Question')
    answer = fields.Char(string='Answer')

class SurveyQuestion(models.Model):
    _inherit = 'survey.question'

    is_from_worksheet_questions = fields.Boolean(default=False)

class SurveySurvey(models.Model):
    _inherit = 'survey.survey'

    team_member_id = fields.Many2one('team.member')
    worksheet_id = fields.Many2one('task.worksheet')
    is_from_worksheet = fields.Boolean(default=False)
    survey_start_url = fields.Char(compute='_compute_survey_start_url')
    signature = fields.Image(
        string="Signature",
        copy=False, attachment=True, max_width=1024, max_height=1024)

    def _compute_survey_start_url(self):
        for invite in self:
            invite.survey_start_url = werkzeug.urls.url_join(invite.get_base_url(),
                                                             invite.get_start_url()) if invite.id else False
