# -*- coding: utf-8 -*-
try:
    import qrcode
except ImportError:
    qrcode = None
try:
    import base64
except ImportError:
    base64 = None
from io import BytesIO
from odoo import api, models, fields


class AttendanceQR(models.Model):
    _name = 'attendance.qr'
    _description = 'Attendance QR'

    user_id = fields.Many2one('res.users', string='Team Member', required=True)
    worksheet_id = fields.Many2one('task.worksheet', string='Worksheet')
    qr_code = fields.Binary("QR Code", compute='_compute_qr_code', store=True)

    @api.depends('user_id')
    def _compute_qr_code(self):
        for rec in self:
            if qrcode and base64:
                qr = qrcode.QRCode(
                    version=1,
                    error_correction=qrcode.constants.ERROR_CORRECT_L,
                    box_size=3,
                    border=4,
                )
                qr.add_data(
                    f'http://10.0.0.62:8017/my/worksheet/{self.user_id.id}/{self.worksheet_id.id}')
                # qr.add_data("Invoice No : ")
                # qr.add_data(rec.name)
                # qr.add_data(", Customer : ")
                # qr.add_data(rec.partner_id.name)
                # qr.add_data(", Amount Total : ")
                # qr.add_data(rec.amount_total)
                qr.make(fit=True)
                img = qr.make_image()
                temp = BytesIO()
                img.save(temp, format="PNG")
                qr_image = base64.b64encode(temp.getvalue())
                rec.qr_code = qr_image

    # def action_generate_qr_code(self):
    #     print('>>>>>',self)
    #     if qrcode and base64:
    #         qr = qrcode.QRCode(
    #             version=1,
    #             error_correction=qrcode.constants.ERROR_CORRECT_L,
    #             box_size=3,
    #             border=4,
    #         )
    #         qr.add_data('https://odoo.beyondsolar.com.au/my/orders/20449?access_token=6e2e28e5-061a-44ee-9ad0-b05bd6e8e6a5')
    #         # qr.add_data("Invoice No : ")
    #         # qr.add_data(rec.name)
    #         # qr.add_data(", Customer : ")
    #         # qr.add_data(rec.partner_id.name)
    #         # qr.add_data(", Amount Total : ")
    #         # qr.add_data(rec.amount_total)
    #         qr.make(fit=True)
    #         img = qr.make_image()
    #         temp = BytesIO()
    #         img.save(temp, format="PNG")
    #         qr_image = base64.b64encode(temp.getvalue())
    #         self.qr_code =  qr_image
    #         print('++',self.qr_code)

#  min_qty = fields.Integer(string='Minimum Quantity', default=1)
#  selfie_type = fields.Selection([('check_in', 'Check In'), ('mid', 'Mid Time'), ('check_out', 'Check Out'), ('null', ' ')],
#                                 string='Selfie Type', default='null')
#
