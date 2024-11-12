# -*- coding: utf-8 -*-
from odoo import models, fields


class WorkType(models.Model):
    _name = 'work.type'
    _description = 'Work Type'

    name = fields.Text(string='Name', help='Work type name')
