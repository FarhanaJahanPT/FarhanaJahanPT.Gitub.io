# -*- coding: utf-8 -*-
from datetime import datetime
from odoo import fields, models, _


class ResUsers(models.Model):
    _inherit = 'res.users'

    is_internal_user = fields.Boolean(string='Internal User')
    invoice_amount =  fields.Monetary(string='Invoice amount', default=0)
    currency_id = fields.Many2one(comodel_name='res.currency',
                                  string="Company Currency",
                                  related='company_id.currency_id',)

    def write(self, vals):
        res = super(ResUsers,self).write(vals)
        if 'login' in vals:
            self._notify_security_update(
                _("Security Update: Login Changed"),
                _("Your account login has been updated {}".format(datetime.now())),
            )
        if 'password' in vals:
            self._notify_security_update(
                _("Security Update: Password Changed"),
                _("Your account password has been updated {}".format(datetime.now())),
            )
        return res

    def _notify_security_update(self, subject, body):
        model_id = self.env['ir.model'].search([('model', '=', self._name)], limit=1).id
        self.env['worksheet.notification'].sudo().create([{
            'author_id': self.env.user.id,
            'user_id': self.id,
            'model_id': model_id,
            'res_id': self.id,
            'date': datetime.now(),
            'subject': subject,
            'body': body,
        }])
