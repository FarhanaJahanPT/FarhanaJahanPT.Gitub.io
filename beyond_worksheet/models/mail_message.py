# -*- coding: utf-8 -*-
from odoo import fields, models


class MailMessage(models.Model):
    _inherit = 'mail.message'

    is_read = fields.Boolean(string='Read', default=False)
    is_worksheet = fields.Boolean(string='Is Worksheet', default=False)
