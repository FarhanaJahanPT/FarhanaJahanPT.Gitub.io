# -*- coding: utf-8 -*-
from odoo import api, fields, models
from odoo.exceptions import ValidationError


class InstallationChecklistItem(models.Model):
    _name = 'installation.checklist.item'
    _description = "Installation Checklist Item"

    image = fields.Image(string='Image', store=True)
    checklist_id = fields.Many2one('installation.checklist', string='Type', required=True)
    user_id = fields.Many2one('res.users', string='User', required=True)
    worksheet_id = fields.Many2one('task.worksheet', required=True, domain=[('x_studio_type_of_service', '=', 'New Installation')])
    location = fields.Char(string='Location', required=True)
    text = fields.Text(string='Text')

    @api.constrains('checklist_id')
    def _check_checklist_id_required(self):
        for record in self:
            if record.checklist_id.type == 'img' and not record.image and record.checklist_id.compulsory == True:
                raise ValidationError("Image fields is required")
            if record.checklist_id.type == 'text' and not record.text and record.checklist_id.compulsory == True:
                raise ValidationError("Text fields is required")

    @api.model_create_multi
    def create(self, vals_list):
        res = super(InstallationChecklistItem, self).create(vals_list)
        self.env['worksheet.history'].create({
            'worksheet_id': res.worksheet_id.id,
            'user_id': res.user_id.id,
            'changes': 'Updated Checklist',
            'details': 'Installation checklist ({}) has been updated successfully.'.format(res.checklist_id.name),
        })
        return res
