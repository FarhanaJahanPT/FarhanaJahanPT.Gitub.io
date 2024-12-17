# -*- coding: utf-8 -*-
from odoo import api, fields, models
from odoo.exceptions import ValidationError


class ServiceChecklistItem(models.Model):
    _name = 'service.checklist.item'
    _description = "Service Checklist Item"

    image = fields.Image(string='Image', store=True)
    service_id = fields.Many2one('service.checklist', string='Type', required=True)
    user_id = fields.Many2one('res.users', string='User')
    member_id = fields.Many2one('team.member', string='Team Member')
    worksheet_id = fields.Many2one('task.worksheet', required=True, domain=[('x_studio_type_of_service', '=', 'Service')])
    location = fields.Char(string='Location', required=True)
    text = fields.Text(string='Text')
    compliant = fields.Boolean(string='Compliant')
    latitude = fields.Char(string='Latitude')
    longitude = fields.Char(string='Longitude')
    date = fields.Datetime(string='Date', default=fields.Datetime.now)

    @api.constrains('service_id')
    def _check_service_id_required(self):
        for record in self:
            if record.service_id.type == 'img' and not record.image and record.service_id.compulsory == True:
                raise ValidationError("Image fields is required")
            if record.service_id.type == 'text' and not record.text and record.service_id.compulsory == True:
                raise ValidationError("Text fields is required")

    @api.model_create_multi
    def create(self, vals_list):
        res = super(ServiceChecklistItem, self).create(vals_list)
        self.env['worksheet.history'].sudo().create({
            'worksheet_id': res.worksheet_id.id,
            'user_id': res.user_id.id if res.user_id else False,
            'member_id': res.member_id.id if res.member_id else False,
            'changes': 'Updated Checklist',
            'details': 'Service checklist ({}) has been updated successfully.'.format(res.service_id.name),
        })
        if res.service_id.type == 'img':
            self.env['documents.document'].create({
                'owner_id': res.user_id.id if res.user_id else False,
                'team_id': res.member_id.id if res.member_id else False,
                'datas': res.image,
                'name': res.service_id.name,
                'location': res.location,
                'folder_id': self.env.ref('beyond_worksheet.documents_project_folder_Worksheet').id,
                'res_model': 'task.worksheet',
                'res_id': res.worksheet_id.id,
            })
        return res
