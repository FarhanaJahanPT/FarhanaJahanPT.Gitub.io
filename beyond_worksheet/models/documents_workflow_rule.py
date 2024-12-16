# -*- coding: utf-8 -*-
from odoo import fields, models


class WorkflowActionRuleTask(models.Model):
    _inherit = ['documents.workflow.rule']

    create_model = fields.Selection(selection_add=[('task.worksheet', "Worksheet")])
