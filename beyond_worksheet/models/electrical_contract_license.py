# -*- coding: utf-8 -*-
from odoo import api, fields, models


class ContractLicense(models.Model):
    _name = "electrical.contract.license"
    _description = "Electrical Contract License"

    type_id = fields.Many2one('license.type', string='Type', required=True)
    number = fields.Char(string="License Number", required=True)
    expiry_date = fields.Date(string="Expire Date", required=True)
    document = fields.Binary(string='Document', required=True)
    team_id = fields.Many2one('team.member', required=True)
    tag_ids = fields.Many2many('license.tags',string='Endorsements or Conditions',)
    tag_ids_domain = fields.Many2many('license.tags',string='Endorsements or Conditions Domain', compute='_compute_tag_ids')

    @api.depends('type_id','tag_ids')
    def _compute_tag_ids(self):
        for record in self:
            if record.tag_ids and record.type_id.multiple_selection == False:
                record.tag_ids_domain = []
            else:
                record.tag_ids_domain = self.env['license.tags'].search([('type_id', '=', record.type_id.id)])
