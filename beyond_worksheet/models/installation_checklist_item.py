# -*- coding: utf-8 -*-
from odoo import api, fields, models


class InstallationChecklistItem(models.Model):
    _name = 'installation.checklist.item'
    _description = "Installation Checklist Item"

    name = fields.Char(string='Name')
    task_ids = fields.Many2many('project.task', string='Task')
    # task_ids = fields.Many2many('project.task', relation="task_dependencies_rel", column1="depends_on_id",
    #                                  column2="task_id", string="Task",)
    type = fields.Selection([('img', 'Image/PDF'), ('text', 'Text')],string='Type')
    compulsory = fields.Boolean(string='Compulsory', defualt=False)
    min_qty = fields.Integer(string='Minimum Quantity')
