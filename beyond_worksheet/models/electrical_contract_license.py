# -*- coding: utf-8 -*-
from odoo import fields, models


class ContractLicense(models.Model):
    _name = "electrical.contract.license"
    _description = "Electrical Contract License"

    type = fields.Selection([('nsw', 'NSW License'), ('act', 'ACT License')], required=True)
    number = fields.Char(string="License Number", required=True)
    expiry_date = fields.Date(string="Expire Date", required=True)
    user_id = fields.Many2one('res.users')
