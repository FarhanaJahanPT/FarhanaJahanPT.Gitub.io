# -*- coding: utf-8 -*-
from odoo import api, fields, models


class InstallationChecklist(models.Model):
    _name = 'installation.checklist'
    _description = "Installation Checklist"

    name = fields.Char(string='Name', required=True)
    task_ids = fields.Many2many('project.task', domain=[('x_studio_type_of_service', '=', 'New Installation')], string='Task')
    type = fields.Selection([('img', 'Image/PDF'), ('text', 'Text')],string='Type', default='img')
    compulsory = fields.Boolean(string='Compulsory', default=False)
    min_qty = fields.Integer(string='Minimum Quantity', default=0)
    is_selfie = fields.Boolean(string="Selfie", default=False)
