# -*- coding: utf-8 -*-
from odoo import fields, models


class StockLot(models.Model):
    _inherit = "stock.lot"

    image = fields.Image(string='Image', store=True)
    state = fields.Selection([('draft', 'Draft'),('invalid', 'Invalid'),
                              ('verifying', 'Verifying'), ('verified', 'Verified')],
                            string='State', required=True, default='draft', readonly=True)
    type = fields.Selection([('panel', 'Panel'), ('inverter', 'Inverter'),('battery', 'Battery'),
                             ],string='Type')
    verification_time = fields.Datetime(string='Verification Time')
    worksheet_id = fields.Many2one('task.worksheet')
    user_id = fields.Many2one('res.users', string='User')
    member_id = fields.Many2one('team.member', string='Team Member')
    location = fields.Text(string='Location')
    categ_id = fields.Many2one('product.category', related='product_id.categ_id')
    is_checklist = fields.Boolean(string='checklist', default=False)
    latitude = fields.Char(string='Latitude')
    longitude = fields.Char(string='Longitude')

    def write(self, vals):
        res = super(StockLot, self).write(vals)
        if self.worksheet_id and self.type and not self.is_checklist:
            self.env['worksheet.history'].sudo().create({
                'worksheet_id': self.worksheet_id.id,
                'user_id': self.user_id.id if self.user_id else False,
                'member_id': self.member_id.id if self.member_id else False,
                'changes': 'Updated Serial Number',
                'details': '{} Serial Number ({}) has been updated successfully.'.format(self.type,self.name),
            })
            self.is_checklist = True
        for val in vals:
            if self.worksheet_id and self.type and val == 'image':
                self.env['documents.document'].create({
                    'owner_id': self.user_id.id if self.user_id else False,
                    'team_id': self.member_id.id if self.member_id else False,
                    'datas': self.image,
                    'name':"{}({})".format(self.product_id.name, self.name),
                    'location': self.location,
                    'folder_id': self.env.ref('beyond_worksheet.documents_project_folder_Worksheet').id,
                    'res_model': 'task.worksheet',
                    'res_id': self.worksheet_id.id,
                })
        return res
