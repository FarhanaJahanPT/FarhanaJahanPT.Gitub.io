# -*- coding: utf-8 -*-
from odoo import api, fields, models


class Document(models.Model):
    _inherit = 'documents.document'

    worksheet_id = fields.Many2one('task.worksheet', compute='_compute_worksheet_id')
    team_id = fields.Many2one('team.member', string='Teams')
    location = fields.Char(string='Location')


    @api.depends('res_id', 'res_model')
    def _compute_worksheet_id(self):
        for record in self:
            record.worksheet_id = record.res_model == 'task.worksheet' and self.env[
                'task.worksheet'].browse(record.res_id)
