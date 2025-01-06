# -*- coding: utf-8 -*-
from odoo import fields, models


class LicenseTags(models.Model):
    _name = "license.tags"
    _description = "License Tags"

    name = fields.Char(string='Name', required=True)
    type_id = fields.Many2one('license.type', string='Type', required=True)
