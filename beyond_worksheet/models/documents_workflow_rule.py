# -*- coding: utf-8 -*-

from markupsafe import Markup, escape
from odoo import Command, fields, models, _


class WorkflowActionRuleTask(models.Model):
    _inherit = ['documents.workflow.rule']

    create_model = fields.Selection(selection_add=[('task.worksheet', "Worksheet")])
