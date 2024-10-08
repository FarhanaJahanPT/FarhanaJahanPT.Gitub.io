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
        today = datetime.today()
        monday = today - timedelta(days=today.weekday())
        friday = monday + timedelta(days=4)
        attendance_ids = self.search([('create_date', '>=', monday.date()),('create_date', '<=', friday.date()), ('type','!=', 'check_out')])
        print(attendance_ids)
        for attendance in attendance_ids.user_id:
            # print('uesers........................',attendance)
            service = attendance_ids.filtered(lambda w: w.user_id == attendance and w.type == 'check_in' and w.additional_service == False)
            additional = attendance_ids.filtered(lambda w: w.user_id == attendance and w.additional_service == True)
            print('data................',', '.join(service.worksheet_id.mapped('name')))
            vals = []
            if service:
                vals.append((0, 0,
                             {
                                 'name': "Services at {}".format(', '.join(service.worksheet_id.mapped('name'))),
                                 'quantity': len(service),
                                 'price_unit': 1,
                                 # 'price_unit': attendance.user_id.invoice_amount
                             }))
            if additional:
                vals.append((0, 0,
                             {
                                 'name': "Additional service item at {}".format(', '.join(additional.worksheet_id.mapped('name'))),
                                 'quantity': len(additional),
                                 'price_unit': 1,
                                 # 'price_unit': attendance.user_id.invoice_amount
                             }))
            print('vals................',vals)
            # invoice = {
            #     'move_type': 'in_invoice',
            #     'partner_id': attendance.partner_id.id,
            #     'invoice_origin': attendance.worksheet_id.name,
            #     'date': attendance.task_id.planned_date_begin,
            #     'invoice_date_due': today.date() + timedelta(days=5),
            #     'invoice_line_ids': vals
            # }
            # print(invoice)
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
