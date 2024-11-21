# -*- coding: utf-8 -*-
from odoo import fields, models


class LicenseTags(models.Model):
    _name = "license.tags"
    _description = "License Tags"

    name = fields.Char(string='Name', required=True)
    type = fields.Selection([('nsw', 'NSW Contractor License'),
                             ('act', 'ACT Electrician License'),
                             ('driver_licence', 'Drivers Licence'),
                             ('nsw_white_card',
                              'NSW General Construction Induction Card (White Card)'),
                             ('ewp', 'EWP Ticket Number (Yellow Card)'),
                             ('wwcc', 'Working With Children Check (WWCC)'),
                             ('whl', 'Working at heights Licence'),
                             ('saa', 'SAA Accreditation Number'),
                             ('pli', 'Public Liability Insurance'),
                             ], required=True)
