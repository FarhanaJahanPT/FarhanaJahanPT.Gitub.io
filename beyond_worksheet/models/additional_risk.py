# -*- coding: utf-8 -*-
from odoo import models,fields


class AdditionalRisk(models.Model):
    _name = "additional.risk"
    _description = "Additional Risk"
    _rec_name = 'name'

    name = fields.Char("Name")
    worksheet_id = fields.Many2one("task.worksheet")
