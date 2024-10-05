# -*- coding: utf-8 -*-
from odoo import api, fields, models


class ServiceChecklist(models.Model):
    _name = 'service.checklist'
    _description = "Service Checklist"

    name = fields.Char(string='Name', required=True)
    # task_ids = fields.Many2many('project.task', domain=[('x_studio_type_of_service', '=', 'Service')], string='Task')
    type = fields.Selection([('img', 'Image/PDF'), ('text', 'Text')], string='Type', dfault='img')
    compulsory = fields.Boolean(string='Compulsory', dfault=False)
    min_qty = fields.Integer(string='Minimum Quantity', dfault=1)
    selfie_type = fields.Selection([('check_in', 'Check In'), ('mid', 'Mid Time'), ('check_out', 'Check Out')],
                                   string='Selfie Type')
    category_ids = fields.Many2many('product.category', string='Category',
                                    required=True)