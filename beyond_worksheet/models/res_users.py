# -*- coding: utf-8 -*-
from odoo import fields, models, _


class ResUsers(models.Model):
    _inherit = 'res.users'

    is_internal_user = fields.Boolean(string='Internal User')
