# -*- coding: utf-8 -*-
from odoo import api, fields, models
from odoo.exceptions import ValidationError


class InstallationChecklistItem(models.Model):
    _name = 'installation.checklist.item'
    _description = "Installation Checklist Item"

    image = fields.Image(string='Image', store=True)
    checklist_id = fields.Many2one('installation.checklist', string='Type', required=True)
    user_id = fields.Many2one('res.users', string='User', required=True)
    task_id = fields.Many2one('project.task', required=True)
    location = fields.Char(string='Location', required=True)
    text = fields.Text(string='Text')

    @api.constrains('checklist_id')
    def _check_checklist_id_required(self):
        for record in self:
            if record.checklist_id.type == 'img' and not record.image and record.checklist_id.compulsory == True:
                raise ValidationError("Image fields is required")
            if record.checklist_id.type == 'text' and not record.text and record.checklist_id.compulsory == True:
                raise ValidationError("Text fields is required")
