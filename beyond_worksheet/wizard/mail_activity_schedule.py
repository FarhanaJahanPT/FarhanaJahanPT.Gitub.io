# -*- coding: utf-8 -*-
from odoo import models


class MailActivitySchedule(models.TransientModel):
    _inherit = 'mail.activity.schedule'

    def action_schedule_activities(self):
        self.env['worksheet.notification'].sudo().create([{
            'author_id': self.plan_on_demand_user_id.id,
            'user_id': self.activity_user_id.id,
            'model': self.res_model,
            'res_id': self.res_ids,
            'date': self.date_deadline,
            'subject': 'Scheduled Activity',
            'body': '{} activity has been successfully scheduled on {}.'.format(self.activity_type_id.name, self.date_deadline),
        }])
        return super(MailActivitySchedule, self).action_schedule_activities()
