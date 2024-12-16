# -*- coding: utf-8 -*-
from odoo import api, fields, models
from odoo.exceptions import ValidationError


class InstallationChecklistItem(models.Model):
    _name = 'installation.checklist.item'
    _description = "Installation Checklist Item"

    image = fields.Image(string='Image', store=True)
    checklist_id = fields.Many2one('installation.checklist', string='Type', required=True)
    user_id = fields.Many2one('res.users', string='User')
    member_id = fields.Many2one('team.member', string='Team Member')
    worksheet_id = fields.Many2one('task.worksheet', required=True, domain=[('x_studio_type_of_service', '=', 'New Installation')])
    location = fields.Char(string='Location', required=True)
    text = fields.Text(string='Text')
    compliant = fields.Boolean(string='Compliant')
    latitude = fields.Char(string='Latitude')
    longitude = fields.Char(string='Longitude')

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
        self.env['worksheet.history'].sudo().create({
            'worksheet_id': res.worksheet_id.id,
            'user_id': res.user_id.id if res.user_id else False,
            'member_id': res.member_id.id if res.member_id else False,
            'changes': 'Updated Checklist',
            'details': 'Installation checklist ({}) has been updated successfully.'.format(res.checklist_id.name),
        })
        if res.checklist_id.type == 'img':
            self.env['documents.document'].create({
                'owner_id': res.user_id.id if res.user_id else False,
                'team_id': res.member_id.id if res.member_id else False,
                'datas': res.image,
                'name': res.checklist_id.name,
                'location': res.location,
                'folder_id': self.env.ref('beyond_worksheet.documents_project_folder_Worksheet').id,
                'res_model': 'task.worksheet',
                'res_id': res.worksheet_id.id,
            })
        return res
