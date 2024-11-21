# -*- coding: utf-8 -*-
from odoo import fields, models


class ContractLicense(models.Model):
    _name = "electrical.contract.license"
    _description = "Electrical Contract License"

    type = fields.Selection([('nsw', 'NSW Contractor License'),
                             ('act', 'ACT Electrician License'),
                             ('driver_licence', 'Drivers Licence'),
                             ('nsw_white_card', 'NSW General Construction Induction Card (White Card)'),
                             ('ewp', 'EWP Ticket Number (Yellow Card)'),
                             ('wwcc', 'Working With Children Check (WWCC)'),
                             ('whl', 'Working at heights Licence'),
                             ('saa', 'SAA Accreditation Number'),
                             ('pli', 'Public Liability Insurance'),
                             ], required=True)
    number = fields.Char(string="License Number", required=True)
    expiry_date = fields.Date(string="Expire Date", required=True)
    document = fields.Binary(string='Document')
    team_id = fields.Many2one('team.member')
    tag_ids = fields.Many2many('license.tags', string='Endorsements or Conditions', domain="[('type', '=', type)]")
