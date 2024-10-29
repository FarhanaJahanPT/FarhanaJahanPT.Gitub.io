# -*- coding: utf-8 -*-
from datetime import datetime, timedelta
from odoo import fields, models, _


class ResUsers(models.Model):
    _inherit = 'res.users'

    is_internal_user = fields.Boolean(string='Internal User')
    invoice_amount =  fields.Monetary(string='Invoice amount', default=0)
    currency_id = fields.Many2one(comodel_name='res.currency',
                                  string="Company Currency",
                                  related='company_id.currency_id',)

    def get_weekly_work(self, object):
        today = datetime.today()
        next_monday = today + timedelta(days=(7 - today.weekday()) % 7)
        next_friday = next_monday + timedelta(days=4)
        tasks = self.env['project.task'].search([('planned_date_start', '>=', next_monday.date()),('planned_date_start', '<=', next_friday.date())])
        task_ids = tasks.filtered(lambda w: w.x_studio_proposed_team == object)
        # task_ids += tasks.filtered(lambda w: object in w.assigned_users)
        return task_ids

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
        self.env['worksheet.notification'].sudo().create([{
            'author_id': self.env.user.id,
            'user_id': self.id,
            'model': 'res.users',
            'res_id': self.id,
            'date': datetime.now(),
            'subject': subject,
            'body': body,
        }])
