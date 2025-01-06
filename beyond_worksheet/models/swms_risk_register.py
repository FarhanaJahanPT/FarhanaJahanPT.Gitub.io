# -*- coding: utf-8 -*-
from odoo import fields, models


class SwmsRiskRegister(models.Model):
    _name = "swms.risk.register"
    _description = "SWMS Risk Register"
    _rec_name = "installation_question"

    installation_question = fields.Text(string='Installation Question', required=True)
    job_activity = fields.Text(string='Job Activity', required=True)
    hazard_associated_risk = fields.Text(string='Hazard and Associated Risks', required=True)
    risk_level = fields.Selection([('vh','Very High'),('h','High'),('m','Moderate'),('l','Low')],string='Risk Level')
    risk_control = fields.Text(string='How will the hazards and the risks be controlled?', required=True)
    residual_risk_level = fields.Selection([('vh','Very High'),('h','High'),('m','Moderate'),('l','Low')], string='Residual Risk Level')
    risk_group = fields.Char(string='Risk Group')
    category_id = fields.Many2one('product.category', string='Applies To',required=True)
    installer_input = fields.Boolean(string='Requires Installer Input?')
