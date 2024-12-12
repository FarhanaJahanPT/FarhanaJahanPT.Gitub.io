# -*- coding: utf-8 -*-
from odoo import fields, models


class SwmsTeamMemberInput(models.Model):
    _name = "swms.team.member.input"
    _description = "SWMS Team Member Input"

    installation_question_id = fields.Many2one("swms.risk.register",string="Questions")
    team_member_input = fields.Selection([('yes','Yes'),('no','No')],string="Answer")
    member_id = fields.Many2one("team.member",string="Team Member")
    worksheet_id = fields.Many2one("task.worksheet",string="Worksheet")
    date = fields.Date()

