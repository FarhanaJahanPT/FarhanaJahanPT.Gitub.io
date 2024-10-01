# -*- coding: utf-8 -*-
from email.policy import default

from odoo import api, fields, models


class InstallationChecklist(models.Model):
    _name = 'installation.checklist'
    _description = "Installation Checklist"

    name = fields.Char(string='Name', required=True)
    task_ids = fields.Many2many('project.task', string='Task')
    type = fields.Selection([('img', 'Image/PDF'), ('text', 'Text')],string='Type', dfault='img')
    compulsory = fields.Boolean(string='Compulsory', dfault=False)
    min_qty = fields.Integer(string='Minimum Quantity', dfault=0)
