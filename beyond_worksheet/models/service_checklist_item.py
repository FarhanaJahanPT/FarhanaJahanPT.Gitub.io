# -*- coding: utf-8 -*-
from odoo import api, fields, models
from odoo.exceptions import ValidationError


class ServiceChecklistItem(models.Model):
    _name = 'service.checklist.item'
    _description = "Service Checklist Item"

    image = fields.Image(string='Image', store=True)
    service_id = fields.Many2one('service.checklist', string='Type', required=True)
    user_id = fields.Many2one('res.users', string='User', required=True)
    task_id = fields.Many2one('project.task', required=True)
    location = fields.Char(string='Location', required=True)
    text = fields.Text(string='Text')

    @api.constrains('service_id')
    def _check_service_id_required(self):
        for record in self:
            if record.service_id.type == 'img' and not record.image and record.service_id.compulsory == True:
                raise ValidationError("Image fields is required")
            if record.service_id.type == 'text' and not record.text and record.service_id.compulsory == True:
                raise ValidationError("Text fields is required")
