# -*- coding: utf-8 -*-
from odoo import fields, models


class SwmsRiskWork(models.Model):
    _name = "swms.risk.work"
    _description = "SWMS Risk Work"

    name = fields.Char(string='Name', required=True)
    type = fields.Selection([('cranes', 'Cranes'), ('hoists', 'Hoists'),
                             ('scaffolding', 'Scaffolding'), ('dogging_rigging', 'Dogging & Rigging'),
                             ('forklift', 'Forklift')], string='Type')
