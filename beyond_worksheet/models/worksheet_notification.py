# -*- coding: utf-8 -*-
from odoo import fields, models


class WorksheetNotification(models.Model):
    _name = 'worksheet.notification'
    _description = "Worksheet Notification"

    date = fields.Date(string='date', default=lambda self: fields.Date.today())
    author_id = fields.Many2one('res.users', string='Auther')
    user_id = fields.Many2one('res.users', string='User')
    subject = fields.Char(string='subject')
    body = fields.Text(string='Description')
    model = fields.Char(string='Related Model')
    res_id = fields.Char(string='Related ID')
    is_read = fields.Boolean(string='Read', default=False)
