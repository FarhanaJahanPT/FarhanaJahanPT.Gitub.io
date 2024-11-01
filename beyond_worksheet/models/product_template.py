# -*- coding: utf-8 -*-
from odoo import fields, models


class ProductTemplate(models.Model):
    _inherit = "product.template"

    is_testing_required = fields.Boolean(string="Is Testing Required", default=False)
