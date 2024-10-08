# -*- coding: utf-8 -*-
from odoo import api, fields, models


class StockLot(models.Model):
    _inherit = "stock.lot"

    image = fields.Image(string='Image', store=True)
    state = fields.Selection([('draft', 'Draft'),('invalid', 'Invalid'),
                              ('verifying', 'Verifying'), ('verified', 'Verified')],
                            string='State', required=True, default='draft', readonly=True)
    type = fields.Selection([('panel', 'Panel'), ('inverter', 'Inverter'),('battery', 'Battery'),
                             ],string='Type')
    verification_time = fields.Datetime(string='Verification Time')
    task_id = fields.Many2one('project.task')
    worksheet_id = fields.Many2one('task.worksheet')
    user_id = fields.Many2one('res.users', string='User')
    location = fields.Text(string='Location')
