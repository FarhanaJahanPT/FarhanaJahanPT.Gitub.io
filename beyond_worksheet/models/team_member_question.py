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
