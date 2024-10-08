# -*- coding: utf-8 -*-
from odoo import api, fields, models,_


class WorkSheet(models.Model):
    _name = 'task.worksheet'
    _description = "Worksheet"


    name = fields.Char("Name",default=lambda self: _('New'))

    @api.model_create_multi
    def create(self, vals_list):
        """Function to create sequence"""
        for vals in vals_list:
            if not vals.get('name') or vals['name'] == _('New'):
                vals['name'] = self.env['ir.sequence'].next_by_code('task.worksheet') or _('New')
        return super().create(vals_list)

    # name = fields.Char(string='Name', required=True)
    # # task_ids = fields.Many2many('project.task', domain=[('x_studio_type_of_service', '=', 'New Installation')],
    # #                             string='Task')
    # type = fields.Selection([('img', 'Image/PDF'), ('text', 'Text')], string='Type', default='img')
    # compulsory = fields.Boolean(string='Compulsory', default=False)
    # min_qty = fields.Integer(string='Minimum Quantity', default=1)
    # selfie_type = fields.Selection([('check_in', 'Check In'), ('mid', 'Mid Time'), ('check_out', 'Check Out'), ('null', ' ')],
    #                                string='Selfie Type', default='null')
    # category_ids = fields.Many2many('product.category', string='Category', required=True)
