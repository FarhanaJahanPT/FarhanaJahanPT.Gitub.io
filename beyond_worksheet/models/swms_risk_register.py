# -*- coding: utf-8 -*-
from odoo import fields, models


class SwmsRiskRegister(models.Model):
    _name = "swms.risk.register"
    _description = "SWMS Risk Register"

    installation_question = fields.Text(string='Installation Question', required=True)
    job_activity = fields.Text(string='Job Activity', required=True)
    hazard_associated_risk = fields.Text(string='Hazard and Associated Risks', required=True)
    # risk_level = fields.Char(string='Risk Level')
    risk_level = fields.Selection([('1AM','1A M'),('1BM','1B M'),('1CL','1C L'),('1DL','1D L'),
                                   ('1EL','1E L'),('2AH','2A H'),('2BM','2B M'),('2CM','2C M'),
                                   ('2DL','2D L'),('2EL','2E L'),('3AH','3A H'),('3BH','3B H'),
                                   ('3CH','3C H'),('3DM','3D M'),('3EM','3E M'),('4AVH','4A VH'),
                                   ('4BH','4B H'),('4CH','4C H'),('4DM','4D M'),('4EM','4E M'),
                                   ('5AVH','5A VH'),('5BVH','5B VH'),('5CVH','5C VH'),('5DH','5D H'),
                                   ('5EM','5E M')],string='Risk Level')
    risk_control = fields.Text(string='How will the hazards and the risks be controlled?', required=True)
    residual_risk_level = fields.Char(string='Residual Risk Level')
    risk_group = fields.Char(string='Risk Group')
    category_id = fields.Many2one('product.category', string='Applies To',required=True)
    installer_input = fields.Char(string='Requires Installer Input?')
