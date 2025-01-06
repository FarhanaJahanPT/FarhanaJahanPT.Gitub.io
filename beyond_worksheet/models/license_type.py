# -*- coding: utf-8 -*-
from odoo import fields, models


class LicenseType(models.Model):
    _name = "license.type"
    _description = "License Type"

    name = fields.Char(string='Name', required=True)
    multiple_selection = fields.Boolean(string='Multiple Selection')
