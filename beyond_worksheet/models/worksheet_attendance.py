# -*- coding: utf-8 -*-
from datetime import datetime, timedelta

from odoo import api, fields, models, _


class WorksheetAttendance(models.Model):
    _name = 'worksheet.attendance'
    _description = "Worksheet Attendance"

    type = fields.Selection([('check_in', 'Check In'),
                             ('check_out', 'Check Out')], string='Type',
                            required=True)
    location = fields.Char(string='Location')
    user_id = fields.Many2one('res.users', string='User', required=True)
    task_id = fields.Many2one('project.task', required=True)
    worksheet_id = fields.Many2one('task.worksheet', string='Worksheet')
    additional_service = fields.Boolean(string='Additional Service')

    def _generate_attendance_invoice_cron(self):
        print('sssssssssssssssssss')
        today = datetime.today()
        monday = today - timedelta(days=today.weekday())
        friday = monday + timedelta(days=4)
        attendance_ids = self.search([('create_date', '>=', monday.date()),('create_date', '<=', friday.date())])
        print(attendance_ids)
        invoice = {
            'move_type': 'in_invoice',
            'partner_id': self.user_id.partner_id.id,
            'invoice_origin': self.worksheet_id.name,
            'invoice_date_due': today.date() + timedelta(days=5),
            # 'invoice_line_ids': [(0, 0, {
            #     'name': "{} to {}".format(self.from_location, self.to_location),
            #     'quantity': 1,
            #     'price_unit': self.amount - self.invoiced_amount,
            #     'price_subtotal': self.amount}
            #                       )]
        }
        print(invoice)
        # invoice = self.env['account.move'].create([{
        #     'move_type': 'in_invoice',
        #     'partner_id': self.user_id.partner_id.id,
        #     'invoice_origin': self.worksheet_id.name,
        #     'invoice_date_due': datetime.today() + 5,
        #     'invoice_line_ids': [(0, 0, {
        #         'name': "{} to {}".format(self.from_location, self.to_location),
        #         'quantity': 1,
        #         'price_unit': self.amount - self.invoiced_amount,
        #         'price_subtotal': self.amount})]}])
