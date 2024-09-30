# -*- coding: utf-8 -*-
from odoo import api, fields, models
from odoo.exceptions import ValidationError


class InstallationChecklist(models.Model):
    _name = 'installation.checklist'
    _description = "Installation Checklist"

    # type = fields.Selection([('before_installation', 'Picture of roof before installation'),
    #                          ('panel_model_label', 'Panel model label'),
    #                          ('switch_board_opened', 'Switch board opened'),
    #                          ('panel_installed', 'Panels installed'),
    #                          ('inverter_installed', 'Inverter installed'),
    #                          ('front_property', 'Front of property'),
    #                          ('inverter_model_label', 'Inverter model Label'),
    #                          ('hd_conduit_support', 'HD conduit & support'),
    #                          ('roof_penetration', 'Roof penetration'),
    #                          ('rancking_system_installed', 'Racking system installed'),
    #                          ('under_array', 'Under array'),
    #                          ('string_voltage', 'String voltage'),
    #                          ], string='Type', required=True)
    image = fields.Image(string='Image', store=True)
    checklist_item_id = fields.Many2one('installation.checklist.item', string='Type')
    user_id = fields.Many2one('res.users', string='User', required=True)
    task_id = fields.Many2one('project.task', required=True)
    location = fields.Char(string='Location')
    text = fields.Text(string='Text')

    @api.constrains('checklist_item_id')
    def _check_checklist_item_id_required(self):
        for record in self:
            if record.checklist_item_id.type == 'img' and not record.image and record.checklist_item_id.compulsory == True:
                raise ValidationError("Image fields is required")
            if record.checklist_item_id.type == 'text' and not record.text and record.checklist_item_id.compulsory == True:
                raise ValidationError("Text fields is required")
