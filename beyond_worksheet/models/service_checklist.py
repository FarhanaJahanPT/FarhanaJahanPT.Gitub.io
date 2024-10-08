# -*- coding: utf-8 -*-
from odoo import api, fields, models


class ServiceChecklist(models.Model):
    _name = 'service.checklist'
    _description = "Service Checklist"

    name = fields.Char(string='Name', required=True)
    type = fields.Selection([('img', 'Image/PDF'), ('text', 'Text')], string='Type', default='img')
    compulsory = fields.Boolean(string='Compulsory', default=False)
    min_qty = fields.Integer(string='Minimum Quantity', default=1)
    selfie_type = fields.Selection(
        [('check_in', 'Check In'), ('mid', 'Mid Time'),
         ('check_out', 'Check Out'), ('null', ' ')],
        string='Selfie Type', default='null')
    category_ids = fields.Many2many('product.category', string='Category',
                                    required=True)
