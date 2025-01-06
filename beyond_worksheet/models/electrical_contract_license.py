# -*- coding: utf-8 -*-
from odoo import api, fields, models
from odoo.exceptions import ValidationError


class ContractLicense(models.Model):
    _name = "electrical.contract.license"
    _description = "Electrical Contract License"

    @api.model
    def _get_tag_ids_domain(self):
        print('aaaaaaaaaaaaaaaaaaa',self.env.context.get('type_id'))
        print('dddddddddddddddddd')
        for record in self:
            if record.type_id and record.type_id.multiple_selection == False:
                record.tag_ids = record.tag_ids[:1]
            return [('type_id', '=', record.type_id.id)]
        # if self.type_id.multiple_selection == False and self.tag_ids:
        #     return []
        # else:
        # return [('type_id', '=', self.env.context.get('type_id'))]

    type_id = fields.Many2one('license.type', string='Type', required=True)
    number = fields.Char(string="License Number", required=True)
    expiry_date = fields.Date(string="Expire Date", required=True)
    document = fields.Binary(string='Document', required=True)
    team_id = fields.Many2one('team.member', required=True)
    # tag_ids = fields.Many2many('license.tags', string='Endorsements or Conditions',domain=_get_tag_ids_domain, required=True)
    tag_ids = fields.Many2many('license.tags', string='Endorsements or Conditions', domain="[('type_id', '=', type_id)]", limit=1)
