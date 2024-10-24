# -*- coding: utf-8 -*-
try:
    import qrcode
except ImportError:
    qrcode = None
try:
    import base64
except ImportError:
    base64 = None
from io import BytesIO
from odoo import api, models, fields


class TeamMemberQuestion(models.Model):
    _name = 'team.member.question'
    _description = 'Team member Question'

    sequence = fields.Integer('Sequence')
    name = fields.Text('Question')
    answer = fields.Char('Answer')
